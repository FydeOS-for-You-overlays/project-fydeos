# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI="6"


EGIT_REPO_URI="git@gitlab.fydeos.xyz:cockpit/fydeos-shell-daemon-go.git"
EGIT_BRANCH="master"

inherit git-r3
DESCRIPTION="fydeos shell daemon in golang, the replacement of python version"
HOMEPAGE="http://fydeos.com"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND="
  !chromeos-base/fydeos-shell-daemon
  "

DEPEND="${RDEPEND}
  dev-lang/go
"

src_compile() {
  go build 
}

src_install() {
  insinto /usr/share/fydeos_shell
  insinto /etc/init
  doins init/fydeos-shell-daemon.conf
  insinto /etc/dbus-1/system.d
  doins dbus/io.fydeos.ShellDaemon.conf
  exeinto /usr/share/fydeos_shell
  doexe script/*
  doexe shell_daemon
}
