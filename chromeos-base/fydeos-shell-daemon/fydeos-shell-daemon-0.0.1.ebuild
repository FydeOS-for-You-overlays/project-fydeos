# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI="5"

inherit git-2

EGIT_REPO_URI="git@gitlab.fydeos.xyz:cockpit/fydeos-shell-daemon.git"
EGIT_BRANCH="master"

DESCRIPTION="fydeos shell daemon"
HOMEPAGE="http://fydeos.com"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE="dev"

RDEPEND="
  dev-lang/python
  dev-libs/dbus-glib
  dev-python/dbus-python
  "

DEPEND="${RDEPEND}"

src_compile() {
  python -m compileall ./src
}

src_install() {
  insinto /usr/share/fydeos_shell
  doins src/*.pyc
  if use dev; then
    doins src/*.py
    doins -r src/client-test
  fi
  insinto /etc/init
  doins init/fydeos-shell-daemon.conf
  insinto /etc/dbus-1/system.d
  doins dbus/io.fydeos.ShellDaemon.conf
}
