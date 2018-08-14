# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI="4"
inherit chrome-dev-flag 
DESCRIPTION="append chrome command line flags"
HOMEPAGE="http://fydeos.com"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE="force-chinese"

S=${WORKDIR}

CHROME_DEV_FLAGS="--fydeos-account-enabled"

if use force-chinese ; then
  CHROME_DEV_FLAGS="${CHROME_DEV_FLAGS} --lang=zh-CN LANGUAGE=zh-CN"
fi
