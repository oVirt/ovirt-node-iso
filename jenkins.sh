#!/bin/bash
# oVirt node iso jenkins build script
#
# Copyright (C) 2008 Red Hat, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.

set -e
set -v

#Cleanup
test -f Makefile && make -k distclean
rm -rf ${WORKSPACE}/ovirt-node-tools

OVIRT_CACHE_DIR=${WORKSPACE}/ovirt-cache
OVIRT_LOCAL_REPO=file://${OVIRT_CACHE_DIR}/ovirt
export OVIRT_CACHE_DIR OVIRT_LOCAL_REPO
OVIRT_NODE_TOOLS_RPM=$(ls -t ${OVIRT_CACHE_DIR}/ovirt/noarch/ovirt-node-tools* | head -n1)

# ovirt-node-tools rpm should be copied to $OVIRT_CACHE_DIR/ovirt/noarch
mkdir ${WORKSPACE}/ovirt-node-tools
cd ${WORKSPACE}/ovirt-node-tools
rpm2cpio $OVIRT_NODE_TOOlS_RPM | pax -r
cd ${WORKSPACE}

RECIPE_DIR=${WORKSPACE}/ovirt-node-tools/usr/share/ovirt-node-tools
cp ${WORKSPACE}/ovirt-node-tools/usr/sbin/node-creator ${WORKSPACE}

./autogen.sh --with-recipe=${RECIPE_DIR} --with-build-number=${BUILD_NUMBER}

make iso
make publish
