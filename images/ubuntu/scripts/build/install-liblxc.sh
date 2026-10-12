#!/bin/bash
################################################################################
##  File:  install-liblxc.sh
##  Desc:  Build and install liblxc from source with seccomp enabled
##  Note:  Sourced by install-incus.sh. Ubuntu's liblxc1 may be built without
##         seccomp; liblxc without seccomp rejects lxc.seccomp.profile and
##         every incusd container launch fails.
##         Building into /usr/local/lib puts it ahead of /usr/lib in the
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

    apt-get install -y libseccomp-dev libselinux1-dev meson ninja-build

    cd /tmp || exit 1

    if [ ! -d lxc ]; then
        git clone --branch "${LXC_VERSION}" https://github.com/lxc/lxc.git
    fi

    cd lxc || exit 1
    rm -rf builddir

    # Library only: the lxc-* tools and init scripts stay with the distro
    # package. apparmor is not used on all Ubuntu runners, keep it disabled
    # here so the build doesn't require apparmor headers.
    meson setup builddir \
        --prefix=/usr/local --libdir=/usr/local/lib \
        -Dseccomp=true -Dselinux=true -Dapparmor=false \
        -Dman=false -Dexamples=false -Dtests=false \
        -Dtools=false -Dcommands=false

    meson compile -C builddir
    meson install -C builddir
    ldconfig

    ldd /usr/local/lib/liblxc.so.1 | grep -q libseccomp || {
        echo "[ERROR] liblxc just built still has no seccomp support" >&2
        exit 1
    }

    echo "[INFO] liblxc ${LXC_VERSION} with seccomp installed successfully"
fi
