# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI="5"

DESCRIPTION="empty project"
HOMEPAGE="http://fydeos.com"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND="dev-lang/python-exec"

DEPEND="${RDEPEND}"

S=$WORKDIR

src_install() {
  exeinto /usr/local/lib/python-exec
  doexe ${ROOT}usr/lib/python-exec/python-exec2*
}
