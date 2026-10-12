#!/bin/bash
################################################################################
##  File:  install-liblxc.sh
##  Desc:  Build and install liblxc from source with seccomp enabled
##  Note:  Sourced by install-incus.sh. EPEL's lxc-libs for EL10 is built
##         with -Dseccomp=false; liblxc without seccomp rejects
##         lxc.seccomp.profile and every incusd container launch fails.
##         Building into /usr/local/lib puts it ahead of /usr/lib64 in the
##         loader cache (via /etc/ld.so.conf.d/incus.conf written by
##         install-cowsql.sh) so incusd picks it up automatically.
##
##  Expects: LXC_VERSION (default v6.0.6)
################################################################################

LXC_VERSION="${LXC_VERSION:-v6.0.6}"

if ldd /usr/local/lib/liblxc.so.1 2>/dev/null | grep -q libseccomp; then
    echo "[INFO] liblxc with seccomp already installed at /usr/local/lib, skipping."
else
    echo "[INFO] Building liblxc ${LXC_VERSION} with seccomp..."

    dnf install -y libseccomp-devel libselinux-devel

    # meson and ninja-build are not in every host's repo set (some PowerVS
    # images carry no CRB), so fall back to pip if the packages are absent.
    dnf install -y meson ninja-build || true
    if ! command -v meson >/dev/null 2>&1; then
        echo "[INFO] meson not packaged here, installing via pip3..."
        dnf install -y python3-pip
        pip3 install --quiet meson ninja
    fi

    cd /tmp || exit 1

    if [ ! -d lxc ]; then
        git clone --branch "${LXC_VERSION}" https://github.com/lxc/lxc.git
    fi

    cd lxc || exit 1
    rm -rf builddir

    # Library only: the lxc-* tools and init scripts stay with the distro
    # package. apparmor is not present on RHEL so its headers are absent.
    meson setup builddir \
        --prefix=/usr/local --libdir=/usr/local/lib \
        -Dseccomp=true -Dselinux=true -Dapparmor=false \
        -Dman=false -Dexamples=false -Dtests=false \
        -Dtools=false -Dcommands=false -Dspecfile=false

    meson compile -C builddir

    # sudo resets PATH to secure_path which excludes /usr/local/bin (where pip
    # installs meson/ninja); pass the current PATH explicitly so ninja is found.
    env PATH="$PATH" meson install -C builddir
    ldconfig

    ldd /usr/local/lib/liblxc.so.1 | grep -q libseccomp || {
        echo "[ERROR] liblxc just built still has no seccomp support" >&2
        exit 1
    }

    echo "[INFO] liblxc ${LXC_VERSION} with seccomp installed successfully"
fi
