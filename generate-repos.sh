#!/usr/bin/bash

OVERSION=$1
DIST=$2

#
# URLs to release files containing the repositories to use
#
OVIRT_RELEASE_FILE_URL=http://resources.ovirt.org/pub/yum-repo/ovirt-release$OVERSION.rpm
FEDORA_RELEASE_FILE_URL=http://download.fedoraproject.org/fedora/linux/releases/20/Fedora/x86_64/os/Packages/f/fedora-release-20-1.noarch.rpm
CENTOS_RELEASE_FILE_URL=http://mirror.centos.org/centos/6/os/x86_64/Packages/centos-release-6-5.el6.centos.11.1.x86_64.rpm


#
# Helper functions
#
usage() {
echo -e "$0 OVIRT_VER DIST\nPrints the repos needed to add VDSM to a oVirt Node Base Image"
echo -e " OVIRT_VER  Two digits MAJORMINOR, i.e.: 34 or 35"
echo -e " DIST       Dist tag, i.e. el6 or fc19 ('rpm -E %dist' can help)"
}
cpiocat() { cpio --quiet --to-stdout -i $@ ; }
rpmcat() { RPM=$1 ; shift 1 ; rpm2cpio $RPM | cpiocat $@ ; }
assert_url_exists() { curl -v -s $1 2>&1 | grep -q "HTTP/1.1 200" || die "URL does not exist: $1" ; }
die() { echo $@ >&2 ; exit 42 ; }

[[ -z $OVERSION ]] && die "Missing ovirt version (i.e 34)"
[[ -z $DIST ]] && die "Missing dist (ie el6)"

#
# Repo dumpers
#

#
# oVirt
#
ovirt_repo() {
local DEPS=el
[[ $DIST == "fc19" ]] && DEPS=f19

# The mirrorlist links don't work with epel
hack_epel() { sed "/mirrorlist.*epel/ s/^/#/ ; /baseurl.*fedora.*epel/ s/^#//" ; }

assert_url_exists $OVIRT_RELEASE_FILE_URL
rpmcat $OVIRT_RELEASE_FILE_URL \
	./usr/share/ovirt-release$OVERSION/ovirt.repo \
	./usr/share/ovirt-release$OVERSION/ovirt-$DEPS-deps.repo \
	| sed "s/@DIST@/$DIST/" | hack_epel

}


#
# Platform
#
platform_repos() {
# if fedora …
local is_centos=false
local is_fedora=false

if   [[ $DIST =~ ^el ]] ; then is_centos=true ;
elif [[ $DIST =~ ^f ]]  ; then is_fedora=true ;
else die "Could not detect platform: $DIST"   ;
fi

if $is_centos ; then
  _centos_repo
elif $is_fedora ; then
  _fedora_repo
else
  die "Unknown platform: $DIST"
fi
}

_centos_repo() {
assert_url_exists $CENTOS_RELEASE_FILE_URL
rpmcat \
    $CENTOS_RELEASE_FILE_URL \
    ./etc/yum.repos.d/CentOS-Base.repo
}

_fedora_repo() {
assert_url_exists $FEDORA_RELEASE_FILE_URL
rpmcat \
    $FEDORA_RELEASE_FILE_URL \
    ./etc/yum.repos.d/fedora.repo \
    ./etc/yum.repos.d/fedora-updates.repo
}

# Output all repos:
{
#
# This repofiles was created automatically on $(date)
# $0 $@
#

# oVirt
ovirt_repo

# Platform
platform_repos
}

