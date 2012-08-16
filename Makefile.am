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
NAME0			  = ovirt-node-image
RECIPE            = $(PACKAGE).ks
PRODUCT           = @PRODUCT_NAME@
PRODUCT_SHORT     ?= $(PRODUCT)
PKG_FMT           = iso
FEDORA            = @FEDORA@
RHEL              = @RHEL@
DISTRO            = @DISTRO@
BUILD_TYPE        ?= STABLE
CENTOS            = @CENTOS@
ARCH              = $(shell rpm --eval '%{_arch}')
RELEASE 		  := $(shell rpm -q --qf "%{RELEASE}\n" --define "BUILD_NUMBER $(BUILD_NUMBER)" --specfile ./ovirt-node-iso.spec | head -n1)
RECIPE_DIR 		  = @RECIPES@
OVIRT_CACHE_DIR	?= $(HOME)/ovirt-cache

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
OVIRT_URL	      = http://ovirt.org/releases/stable/rpm/Fedora
OVIRT_NIGHTLY_URL = http://ovirt.org/releases/nightly/rpm/Fedora
OVIRT_BETA_URL    = http://ovirt.org/releases/beta/rpm/Fedora
CUR_RAWHIDE       = 19
CUR_DEVEL         = 18

CENTOS_MIRROR     = http://mirrorlist.centos.org/
CENTOS_RELEASE    = 6

# For Release: 0..., set _ovirt_dev=1 so that we get extra_release.GIT-
# annotated rpm version strings.
_ovirt_dev = \
 $(shell grep -q '^[[:space:]]*Release:[[:space:]]*0' \
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

repos.ks: kickstarts
	( \
      if [ -n "$(CENTOS)" ]; then \
        CENTOS_REPO_LINE="repo --name=centos --mirrorlist=$(CENTOS_MIRROR)?release=$(CENTOS_RELEASE)&arch=${ARCH}&repo=os" ;\
        UPDATES_REPO_LINE="repo --name=centos-updates --mirrorlist=$(CENTOS_MIRROR)?release=$(CENTOS_RELEASE)&arch=${ARCH}&repo=updates" ;\
        EPEL_REPO_LINE="repo --name=epel --baseurl=http://dl.fedoraproject.org/pub/epel/$(CENTOS_RELEASE)/${ARCH}/" ;\
        echo "$${CENTOS_REPO_LINE}" > repos.ks ;\
        echo "$${UPDATES_REPO_LINE}" >> repos.ks ;\
        echo "$${EPEL_REPO_LINE}" >> repos.ks ;\
      elif [ -n "$(FEDORA)" ]; then \
            OVIRT_STABLE_REPO_LINE="repo --name=ovirt-stable-repo --baseurl=$(OVIRT_URL)/$(FEDORA)\n" ;\
            OVIRT_NIGHTLY_REPO_LINE="repo --name=ovirt-nightly-repo --baseurl=$(OVIRT_NIGHTLY_URL)/$(FEDORA)\n" ;\
            OVIRT_BETA_REPO_LINE="repo --name=ovirt-beta-repo --baseurl=$(OVIRT_BETA_URL)/$(FEDORA)\n" ;\
            if [ 0$(FEDORA) == 0$(CUR_RAWHIDE) ]; then \
                FEDORA_REPO=rawhide ;\
                FEDORA_REPO_LOC="$(if $(FEDORA_URL),--baseurl=$(FEDORA_URL)/development/rawhide/$(ARCH)/os,--mirrorlist=$(FEDORA_MIRROR)?repo=rawhide&arch=$(ARCH))" ;\
            elif [ 0$(FEDORA) == 0$(CUR_DEVEL) ]; then \
                FEDORA_REPO=f$(FEDORA) ;\
                FEDORA_REPO_LOC="$(if $(FEDORA_URL),--baseurl=$(FEDORA_URL)/development/$(FEDORA)/$(ARCH)/os,--mirrorlist=$(FEDORA_MIRROR)?repo=fedora-$(FEDORA)&arch=$(ARCH))" ;\
                UPDATE_REPO_LINE="repo --name=$${FEDORA_REPO}-updates-testing $(if $(FEDORA_URL),--baseurl=$(FEDORA_URL)/updates/testing/$(FEDORA)/${ARCH},--mirrorlist=$(FEDORA_MIRROR)?repo=updates-testing-f$(FEDORA)&arch=$(ARCH))\n" ;\
            else \
                FEDORA_REPO=f$(FEDORA) ;\
                FEDORA_REPO_LOC="$(if $(FEDORA_URL),--baseurl=$(FEDORA_URL)/releases/$(FEDORA)/Everything/${ARCH}/os,--mirrorlist=$(FEDORA_MIRROR)?repo=fedora-$(FEDORA)&arch=$(ARCH))" ;\
                UPDATE_REPO_LINE="repo --name=$${FEDORA_REPO}-updates $(if $(FEDORA_URL),--baseurl=$(FEDORA_URL)/updates/$(FEDORA)/${ARCH},--mirrorlist=$(FEDORA_MIRROR)?repo=updates-released-f$(FEDORA)&arch=$(ARCH))\n" ;\
            fi ;\
            echo "repo --name=$${FEDORA_REPO} $${FEDORA_REPO_LOC}" > repos.ks ;\
            printf "$${UPDATE_REPO_LINE}" >> repos.ks ;\
            printf "$${OVIRT_STABLE_REPO_LINE}" >> repos.ks ;\
            if [ "$${BUILD_TYPE}" == "NIGHTLY" ]; then \
              printf "$${OVIRT_NIGHTLY_REPO_LINE}" >> repos.ks ;\
              printf "$${OVIRT_BETA_REPO_LINE}" >> repos.ks ;\
            elif [ "$${BUILD_TYPE}" == "BETA" ]; then \
              printf "$${OVIRT_BETA_REPO_LINE}" >> repos.ks ;\
            fi ;\
      else \
            echo "# OVIRT_REPO_URL=$(OVIRT_REPO_URL)" > $@ ;\
            for repo in $(OVIRT_REPO_URL); do \
               echo "repo --name=repo$${i} --baseurl=$${repo}" >> $@ ;\
               i=$${i}_ ;\
            done ;\
      fi ;\
	)

version.ks: repos.ks
	( \
	    echo "PRODUCT='"$(PRODUCT)"'" ;\
	    echo "PRODUCT_SHORT='"$(PRODUCT_SHORT)"'" ;\
	    echo "PACKAGE=$(PACKAGE)" ;\
	    echo "VERSION=$(VERSION)" ;\
	    echo "RELEASE=$(RELEASE)" ;\
	) > $@
	ksflatten -c $(NAME0).ks -o $(PACKAGE).ks

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

.PHONY: $(PACKAGE).ks
