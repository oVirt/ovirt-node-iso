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
rm -rf ${WORKSPACE}/ovirt-node-tools ${WORKSPACE}/*iso ${WORKSPACE}/rpmbuild ${WORKSPACE}/manifest* ${WORKSPACE}/old_artifacts

OVIRT_CACHE_DIR=${WORKSPACE}/ovirt-cache
OVIRT_LOCAL_REPO=file://${OVIRT_CACHE_DIR}/ovirt
export OVIRT_CACHE_DIR OVIRT_LOCAL_REPO
OVIRT_NODE_TOOLS_RPM=$(ls -t ${OVIRT_CACHE_DIR}/ovirt/noarch/ovirt-node-tools* | head -n1)
export HOME=${WORKSPACE}

createrepo ${OVIRT_CACHE_DIR}/ovirt

# ovirt-node-tools rpm should be copied to ${OVIRT_CACHE_DIR}/ovirt/noarch
mkdir ${WORKSPACE}/ovirt-node-tools
cd ${WORKSPACE}/ovirt-node-tools
rpm2cpio ${OVIRT_NODE_TOOLS_RPM} | pax -r
OVIRT_NODE_TOOLS_RPM=$(basename ${OVIRT_NODE_TOOLS_RPM})
ONT_NAME=$(echo $OVIRT_NODE_TOOLS_RPM | sed -r 's/^([a-zA-Z0-9\-]+)-([a-zA-Z0-9\.]+)-([a-zA-Z0-9\.]+).noarch.rpm$/\1/')
ONT_VERSION=$(echo $OVIRT_NODE_TOOLS_RPM | sed -r 's/^([a-zA-Z0-9\-]+)-([a-zA-Z0-9\.]+)-([a-zA-Z0-9\.]+).noarch.rpm$/\2/')
ONT_RELEASE=$(echo $OVIRT_NODE_TOOLS_RPM | sed -r 's/^([a-zA-Z0-9\-]+)-([a-zA-Z0-9\.]+)-([a-zA-Z0-9\.]+).noarch.rpm$/\3/')
ONT_BUILD_NUMBER=$(echo $ONT_RELEASE | sed -r 's/^[0-9]+\.(.*)\.fc[0-9]+$/\1./')
if [ "$ONT_BUILD_NUMBER" = "$ONT_RELEASE" ]; then
    ONT_BUILD_NUMBER=""
fi
cd ${WORKSPACE}

RECIPE_DIR=${WORKSPACE}/ovirt-node-tools/usr/share/ovirt-node-tools
cp ${WORKSPACE}/ovirt-node-tools/usr/sbin/node-creator ${WORKSPACE}

./autogen.sh --with-recipe=${RECIPE_DIR} --with-build-number=${ONT_BUILD_NUMBER}${BUILD_NUMBER}

make iso
make publish

ISO_NAME=$(make verrel).iso
# Get iso details
ISO_DIR=$(mktemp -d)
sudo mount -o loop ${ISO_NAME} $ISO_DIR
cp $ISO_DIR/isolinux/manifest-srpm.txt ${WORKSPACE}
cp $ISO_DIR/isolinux/manifest-rpm.txt ${WORKSPACE}
cp $ISO_DIR/isolinux/manifest-file.txt.bz2 ${WORKSPACE}
chmod 666 ${WORKSPACE}/manifest-*txt*
sudo umount ${ISO_DIR}
rmdir ${ISO_DIR}
egrep '^kernel|kvm|libvirt|^vdsm|^ovirt-node|^fence-agents' manifest-srpm.txt | sed 's/\.src\.rpm//' > ovirt-node-iso.mini-manifest.txt

# Add additional information to mini-manifest.txt
echo "======================================================" >> ovirt-node-iso.mini-manifest.txt
echo "ovirt-node-tools used:  $(basename ${OVIRT_NODE_TOOLS_RPM}) " >> ovirt-node-iso.mini-manifest.txt


# Check size of iso and report in mini-manifest.txt
echo "======================================================" >> ovirt-node-iso.mini-manifest.txt
size=$(ls -l ${ISO_NAME} | awk '{print $5}')
human_size=$(ls -lh ${ISO_NAME} | awk '{print $5}')
echo "    Iso Size:  $size  ($human_size)" >> ovirt-node-iso.mini-manifest.txt

old_size=""
old_human_size=""
mkdir -p old_artifacts
cd old_artifacts
if wget ${JOB_URL}/lastSuccessfulBuild/artifact/*zip*/archive.zip; then
    unzip archive.zip
    cd $WORKSPACE
    if [ -e ${WORKSPACE}/old_artifacts/archive/ovirt-node-iso*iso ]; then
        old_size=$(ls -l ${WORKSPACE}/old_artifacts/archive/ovirt-node-iso*iso | awk '{print $5}')
        old_human_size=$(ls -lh ${WORKSPACE}/old_artifacts/archive/ovirt-node-iso*iso | awk '{print $5}')
        echo "Old Iso Size:  $old_size  ($old_human_size)" >> ovirt-node-iso.mini-manifest.txt
    else
        echo "No old iso found for compairson">> ovirt-node-iso.mini-manifest.txt
    fi
else
    cd $WORKSPACE
    echo "No previous build archive found for old iso compairson">> ovirt-node-iso.mini-manifest.txt
fi
rm -rf old_artifacts
# md5 and sha256sums
echo "MD5SUM:  $(md5sum ${ISO_NAME} |awk '{print $1}')" >> ovirt-node-iso.mini-manifest.txt
echo "SHA256SUM:  $(sha256sum ${ISO_NAME} |awk '{print $1}')" >> ovirt-node-iso.mini-manifest.txt

echo "======================================================" >> ovirt-node-iso.mini-manifest.txt
echo "livecd-tools version:  $(rpm -qa livecd-tools)" >> ovirt-node-iso.mini-manifest.txt

