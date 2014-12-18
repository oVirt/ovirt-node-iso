AC_INIT([ovirt-node], [3.5], [node-devel@ovirt.org])
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

AC_ARG_WITH([extra_recipe], [AC_HELP_STRING([--with-extra-recipe],
            [Specify extra recipe to be used .  Defaults to none])],
            [EXTRA_RECIPE="$withval"
            use_extra_recipe=true],
            [EXTRA_RECIPE="false"])
AC_SUBST([EXTRA_RECIPE])
AM_CONDITIONAL([USE_EXTRA_RECIPE],[test x$use_extra_recipe = xtrue])


PACKAGE_NAME=ovirt-node-iso
PRODUCT_NAME=oVirt\ Node\ Hypervisor
MAIN_KS=ovirt-node-image.ks


AC_CONFIG_FILES([Makefile
                ovirt-node-iso.spec])
AC_OUTPUT
