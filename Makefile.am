# Copyright (C) 2010, Red Hat, Inc.
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

PACKAGE           = @PACKAGE_NAME@
NAME0             = @MAIN_KS@
RECIPE            = $(PACKAGE).ks
PRODUCT           = @PRODUCT_NAME@
EXTRA_RECIPE      = @EXTRA_RECIPE@
PRODUCT_SHORT     ?= $(PRODUCT)
PKG_FMT           = iso
FEDORA            = @FEDORA@
RHEL              = @RHEL@
DISTRO            = @DISTRO@
BUILD_TYPE        ?= STABLE
CENTOS            = @CENTOS@
ARCH              = $(shell rpm --eval '%{_arch}')
RELEASE           := $(shell rpm -q --qf "%{RELEASE}\n" --define "BUILD_NUMBER $(BUILD_NUMBER)" --specfile ./ovirt-node-iso.spec | head -n1)
RECIPE_DIR        = @RECIPES@
OVIRT_VERSION     = @PACKAGE_VERSION@
REPO_SUFFIX       = @REPO_SUFFIX@

OVIRT_CACHE_DIR ?= $(HOME)/ovirt-caches

EXTRA_DIST = \
    ovirt-node-iso.spec.in       \
    ovirt-node-iso.spec          \
    $(PACKAGE)-$(VERSION)-$(RELEASE).iso

DISTCLEANFILES = $(PACKAGE)-$(VERSION).tar.gz \
                 repos.ks \
                 Makefile.in \
                 aclocal.m4 \
                 autom4te.cache \
                 configure \
                 install-sh \
                 missing \
                 *.ks

# Need to find node-creator script
# Default to RECIPE_DIR/node-creator
# then check local dir
# then check PATH
NODE_CREATOR      = $(shell ( test -e $(RECIPE_DIR)/node-creator && echo "$(RECIPE_DIR)/node-creator" ) || ( test -e node-creator && echo "./node-creator" ) || which node-creator 2>/dev/null)
FEDORA_MIRROR     = http://mirrors.fedoraproject.org/mirrorlist
OVIRT_BASE_URL    = http://resources.ovirt.org/pub/ovirt-$(REPO_SUFFIX)/rpm
CENTOS_MIRROR     = http://mirrorlist.centos.org/

# For Release: 0..., set _ovirt_dev=1 so that we get extra_release.GIT-
# annotated rpm version strings.
_ovirt_dev = \
 $(shell grep -q '^[[:space:]]*Release:[[:space:]]*[0-9\.]*999' \
 $(top_srcdir)/*.spec && echo 1 || :)

rpms: dist
	rpmbuild --define "BUILD_NUMBER $(BUILD_NUMBER)" $(RPM_FLAGS) -ta $(distdir).tar.gz

srpms: dist
	rpmbuild --define "BUILD_NUMBER $(BUILD_NUMBER)" $(RPM_FLAGS) -ts $(distdir).tar.gz

publish: rpms
	mkdir -p $(OVIRT_CACHE_DIR)
	rsync -aq $(shell rpm --eval '%{_rpmdir}')/ $(OVIRT_CACHE_DIR)/ovirt/
	rsync -aq $(shell rpm --eval '%{_srcrpmdir}')/ $(OVIRT_CACHE_DIR)/ovirt/src
	rsync -aq $(PACKAGE_NAME)-$(VERSION)-$(RELEASE).iso $(OVIRT_CACHE_DIR)/ovirt/binary/
	createrepo $(OVIRT_CACHE_DIR)/ovirt


$(PACKAGE).ks: version.ks

clean_ks:
	rm -f *.ks

kickstarts: clean_ks node-creator
	cp $(RECIPE_DIR)/*.ks .
	rm -f version.ks
	@test -e "${NAME0}" || ( echo "Error main kickstart file missing - ${NAME0}" && exit 1 )

repos.ks: kickstarts
	( \
      if [ -n "$(CENTOS)" ]; then \
        CENTOS_REPO_LINE="repo --name=centos --mirrorlist=$(CENTOS_MIRROR)?release=$(CENTOS)&arch=${ARCH}&repo=os \n" ;\
        UPDATES_REPO_LINE="repo --name=centos-updates --mirrorlist=$(CENTOS_MIRROR)?release=$(CENTOS)&arch=${ARCH}&repo=updates \n" ;\
        EPEL_REPO_LINE="repo --name=epel --baseurl=http://dl.fedoraproject.org/pub/epel/$(CENTOS)/${ARCH} \n" ;\
        OVIRT_REPO_LINE="repo --name=ovirt-repo --baseurl=$(OVIRT_BASE_URL)/el$(CENTOS)\n" ;\
        GLUSTER_REPO_LINE="repo --name=ovirt-$(OVIRT_VERSION)-glusterfs-${ARCH}-epel --baseurl=http://download.gluster.org/pub/gluster/glusterfs/3.6/LATEST/EPEL.repo/epel-$(CENTOS)/${ARCH}\n" ;\
        printf "$${CENTOS_REPO_LINE}" > repos.ks ;\
        printf "$${UPDATES_REPO_LINE}" >> repos.ks ;\
        printf "$${EPEL_REPO_LINE}" >> repos.ks ;\
        printf "$${OVIRT_REPO_LINE}" >> repos.ks ;\
        printf "$${GLUSTER_REPO_LINE}" >> repos.ks ;\
      elif [ -n "$(FEDORA)" ]; then \
        OVIRT_REPO_LINE="repo --name=ovirt-stable-repo --baseurl=$(OVIRT_BASE_URL)/fc$(FEDORA)\n" ;\
        FEDORA_REPO_LOC="repo --name=$${FEDORA_REPO} --mirrorlist=$(FEDORA_MIRROR)?repo=fedora-$(FEDORA)&arch=$(ARCH)\n" ;\
        UPDATE_REPO_LINE="repo --name=$${FEDORA_REPO}-updates --mirrorlist=$(FEDORA_MIRROR)?repo=updates-released-f$(FEDORA)&arch=$(ARCH)\n" ;\
        printf "$${OVIRT_REPO_LINE}" > repos.ks ;\
        printf "$${FEDORA_REPO_LOC}" >> repos.ks ;\
        printf "$${UPDATE_REPO_LINE}" >> repos.ks ;\
        fi ;\
        echo "# OVIRT_REPO_URL=$(OVIRT_REPO_URL)" >> $@ ;\
        for repo in $(OVIRT_REPO_URL); do \
          echo "repo --name=repo$${i} --baseurl=$${repo}" >> $@ ;\
          i=$${i}_ ;\
        done ;\
    )

version.ks: repos.ks $(EXTRA_RECEPIE)
	( \
        echo "PRODUCT='"$(PRODUCT)"'" ;\
        echo "PRODUCT_SHORT='"$(PRODUCT_SHORT)"'" ;\
        echo "PACKAGE=$(PACKAGE)" ;\
        echo "VERSION=$(VERSION)" ;\
        echo "RELEASE=$(RELEASE)" ;\
    ) > $@
	cat $(NAME0) > tmp-recepie.ks
if USE_EXTRA_RECIPE
	echo -e "\n%include $(EXTRA_RECIPE)" >> tmp-recepie.ks
endif
	ksflatten -c tmp-recepie.ks -o $(PACKAGE).ks
	rm -rf tmp-recepie.ks

$(PACKAGE).$(PKG_FMT) iso: kickstarts version.ks repos.ks
	@test ! -e "$(PACKAGE_NAME)-$(VERSION)-$(RELEASE).iso" || ( echo "ERROR: $(PACKAGE_NAME)-$(VERSION)-$(RELEASE).iso already exists." && exit 1 )
	$(NODE_CREATOR) $(RECIPE)
	@test -e "$(PACKAGE_NAME).iso" || ( echo "ERROR: ISO build failed." && exit 1 )
	mv $(PACKAGE_NAME).iso $(PACKAGE_NAME)-$(VERSION)-$(RELEASE).iso

verrel:
	@echo ${PACKAGE_NAME}-${VERSION}-${RELEASE}

node-creator:
	@test -n "${NODE_CREATOR}" || ( echo "No node-creator script found" && exit 1 )
	@echo "Node Creator script is:  ${NODE_CREATOR}"

all: $(PACKAGE).ks

.PHONY: $(PACKAGE).ks kickstarts
