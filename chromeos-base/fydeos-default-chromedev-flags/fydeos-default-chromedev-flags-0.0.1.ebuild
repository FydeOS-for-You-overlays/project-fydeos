# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI="4"
inherit chrome-dev-flag 
DESCRIPTION="empty project"
HOMEPAGE="http://fydeos.com"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE="arc"

S=${WORKDIR}

CHROME_DEV_FLAGS="--fydeos-account-enabled"

if use arc ; then
  CHROME_DEV_FLAGS="${CHROME_DEV_FLAGS} --arc-start-mode=always-start-with-no-play-store"
fi
