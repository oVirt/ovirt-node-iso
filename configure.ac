AC_INIT([ovirt-node], [3.6], [node-devel@ovirt.org])
AM_INIT_AUTOMAKE([-Wall -Werror foreign -Wno-portability tar-pax])

AC_SUBST([FEDORA],[[`rpm --eval '%{fedora}'|sed 's/[^0-9]//g'`]])
AC_SUBST([RHEL], [[`rpm --eval '%{rhel}'|sed 's/[^0-9]//g'`]])
AC_SUBST([CENTOS], [[`rpm --eval '%{centos}'|sed 's/[^0-9]//g'`]])
AC_SUBST([DISTRO])
AC_SUBST([DISTRO_SHORT])
AC_SUBST([PACKAGE_NAME])
AC_SUBST([PRODUCT_NAME])
AC_SUBST([REPO_SUFFIX])
REPO_SUFFIX="master-snapshot"


if test "$FEDORA"; then
    DISTRO=ovirt$FEDORA
    DISTRO_SHORT=fc$FEDORA
fi
if test "$RHEL"; then
    DISTRO=rhevh$RHEL
    DISTRO_SHORT=el$RHEL
fi
if test "$CENTOS"; then
    DISTRO=centos$CENTOS
    DISTRO_SHORT=el$CENTOS
fi



AC_ARG_WITH([recipe], [AC_HELP_STRING([--with-recipe],
            [Specify a recipe directory.  Defaults to /usr/share/ovirt-node-recipe])],
            [RECIPES="$withval"],
            [RECIPES=/usr/share/ovirt-node-recipe])
AC_SUBST([RECIPES])


AC_ARG_WITH([kickstart], [AC_HELP_STRING([--with-kickstart],
            [Specify a kickstart file to use.  Defaults to vdsm-plugin-iso.ks])],
            [MAIN_KS="$withval"],
            [MAIN_KS=vdsm-plugin-iso.ks])
AC_SUBST([MAIN_KS])

AC_ARG_WITH([build_number], [AC_HELP_STRING([--with-build-number],
            [Specify a build number.])],
            [BUILD_NUMBER="$withval"],
            [BUILD_NUMBER=$(date +%Y%m%d%H%M)])
AC_SUBST([BUILD_NUMBER])

AC_ARG_WITH([extra_recipe], [AC_HELP_STRING([--with-extra-recipe],
            [Specify extra recipe to be used .  Defaults to none])],
            [EXTRA_RECIPE="$withval"
            use_extra_recipe=true],
            [EXTRA_RECIPE="false"])
AC_SUBST([EXTRA_RECIPE])
AM_CONDITIONAL([USE_EXTRA_RECIPE],[test x$use_extra_recipe = xtrue])


PACKAGE_NAME=ovirt-node-iso
PRODUCT_NAME=oVirt\ Node\ Hypervisor

AC_CONFIG_FILES([Makefile
                ovirt-node-iso.spec
                recepie-downloader.sh])
AC_OUTPUT
