dnl
dnl Licensed to the Apache Software Foundation (ASF) under one or more
dnl contributor license agreements.  See the NOTICE file distributed with
dnl this work for additional information regarding copyright ownership.
dnl The ASF licenses this file to You under the Apache License, Version 2.0
dnl (the "License"); you may not use this file except in compliance with
dnl the License.  You may obtain a copy of the License at
dnl
dnl     http://www.apache.org/licenses/LICENSE-2.0
dnl
dnl Unless required by applicable law or agreed to in writing, software
dnl distributed under the License is distributed on an "AS IS" BASIS,
dnl WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
dnl See the License for the specific language governing permissions and
dnl limitations under the License.
dnl

AC_PREREQ(2.60)

define([VERSION_MAJOR], [3])
define([VERSION_MINOR], [1])
define([VERSION_FIX], [0])
define([VERSION_NUMBER], VERSION_MAJOR[.]VERSION_MINOR[.]VERSION_FIX)
define([VERSION_SUFFIX], [_master])

AC_INIT([ovirt-node-iso], VERSION_NUMBER[]VERSION_SUFFIX, [devel@ovirt.org])
PACKAGE_RPM_VERSION="VERSION_NUMBER"
PACKAGE_RPM_RELEASE="0.0.$(echo VERSION_SUFFIX | sed 's/^_//')"
AC_SUBST([PACKAGE_RPM_VERSION])
AC_SUBST([PACKAGE_RPM_RELEASE])



AM_INIT_AUTOMAKE([-Wall -Werror foreign -Wno-portability tar-pax])

AC_SUBST([FEDORA],[[`rpm --eval '%{fedora}'|sed 's/[^0-9]//g'`]])
AC_SUBST([RHEL], [[`rpm --eval '%{rhel}'|sed 's/[^0-9]//g'`]])
AC_SUBST([CENTOS], [[`rpm --eval '%{centos}'|sed 's/[^0-9]//g'`]])
AC_SUBST([DISTRO])
AC_SUBST([PACKAGE_NAME])
AC_SUBST([PRODUCT_NAME])


if test "$FEDORA"; then
    DISTRO=ovirt$FEDORA
fi
if test "$RHEL"; then
    DISTRO=rhevh$RHEL
fi
if test "$CENTOS"; then
    DISTRO=centos$CENTOS
fi

AC_ARG_WITH([recipe], [AC_HELP_STRING([--with-recipe],
            [Specify a recipe directory.  Defaults to /usr/share/ovirt-node-recipe])],
            [RECIPES="$withval"],
            [RECIPES=/usr/share/ovirt-node-recipe])
AC_SUBST([RECIPES])

AC_ARG_WITH([build_number], [AC_HELP_STRING([--with-build-number],
            [Specify a build number.])],
            [BUILD_NUMBER="$withval"],
            [BUILD_NUMBER=$(date +%Y%m%d%H%M)])
AC_SUBST([BUILD_NUMBER])

PACKAGE_NAME=ovirt-node-base-iso
PRODUCT_NAME=oVirt\ Node\ Hypervisor
MAIN_KS=ovirt-node-base-image.ks


AC_CONFIG_FILES([Makefile])
AC_OUTPUT
