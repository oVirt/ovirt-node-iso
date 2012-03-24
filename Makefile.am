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

DISTCLEANFILES = $(PACKAGE)-$(VERSION).tar.gz

# Need to find node-creator script
# Default to RECIPE_DIR/node-creator
# then check local dir
# then check PATH
NODE_CREATOR      = $(shell ( test -e $(RECIPE_DIR)/node-creator && echo "$(RECIPE_DIR)/node-creator" ) || ( test -e node-creator && echo "./node-creator" ) || which node-creator 2>/dev/null)

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
	createrepo $(OVIRT_CACHE_DIR)/ovirt


$(PACKAGE).ks: repos.ks

clean_ks:
	rm -f *.ks

kickstarts: clean_ks version.ks node-creator
	cp $(RECIPE_DIR)/*.ks .
	ksflatten -c $(NAME0).ks -o $(PACKAGE).ks

repos.ks: kickstarts

version.ks:
	( \
	    echo "PRODUCT='"$(PRODUCT)"'" ;\
	    echo "PRODUCT_SHORT='"$(PRODUCT_SHORT)"'" ;\
	    echo "PACKAGE=$(PACKAGE)" ;\
	    echo "VERSION=$(VERSION)" ;\
	    echo "RELEASE=$(RELEASE)" ;\
	) > $@

$(PACKAGE).$(PKG_FMT) iso: kickstarts version.ks repos.ks
	@test ! -e "$(PACKAGE_NAME)-$(VERSION)-$(RELEASE).iso" || ( @echo "ERROR: $(PACKAGE_NAME)-$(VERSION)-$(RELEASE).iso already exists." && exit 1 )
	$(NODE_CREATOR) $(RECIPE)
	@test -e "$(PACKAGE_NAME).iso" || ( @echo "ERROR: ISO build failed." && exit 1 )
	mv $(PACKAGE_NAME).iso $(PACKAGE_NAME)-$(VERSION)-$(RELEASE).iso

verrel:
	@echo ${PACKAGE_NAME}-${VERSION}-${RELEASE}

node-creator:
	@test -n "${NODE_CREATOR}" || ( @echo "No node-creator script found" && exit 1 )
	@echo "Node Creator script is:  ${NODE_CREATOR}"

all: $(PACKAGE).ks

.PHONY: $(PACKAGE).ks
