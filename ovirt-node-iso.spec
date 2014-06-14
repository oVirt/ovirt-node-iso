%global product oVirt Node ISO
%global product_short oVirt Node ISO

%global vdsm_compat 3.5,3.4,3.3,3.2,3.1

%define base_iso http://plain.resources.ovirt.org/pub/ovirt-node-base-3.0/iso/el6/ovirt-node-base-iso-3.0.5-20140522.0.el6.iso
%define build_release 20140610.0

Name:           ovirt-node-iso
URL:            http://www.ovirt.org/Node
Version:        3.5.0
Release:        %{?build_release}%{?dist}
Summary:        %{product} ISO Image
BuildArch:      noarch
Source1:        %{?base_iso}
Source2:        generate-repos.sh
Source3:        verify-meta-file.sh

Group:        Applications/System
License:      License: AFL and BSD and (BSD or GPLv2+) and BSD with advertising and Boost and GFDL and GPL and GPL+ and (GPL+ or Artistic) and GPLv1+ and GPLv2 and (GPLv2 or BSD) and (GPLv2 or GPLv3) and GPLv2 with exceptions and GPLv2+ and (GPLv2+ or AFL) and GPLv2+ with exceptions and GPLv3 and GPLv3+ and GPLv3+ with exceptions and IJG and ISC and LGPLv2 and LGPLv2+ and (LGPLv2+ or BSD) and (LGPLv2+ or MIT) and LGPLv2+ with exceptions and LGPLv2/GPLv2 and LGPLv3 and LGPLv3+ and MIT and (MIT or LGPLv2+ or BSD) and (MPLv1.1 or GPLv2+ or LGPLv2+) and Open Publication and OpenLDAP and OpenSSL and Public Domain and Python and (Python or ZPLv2.0) and Rdisc and Redistributable, no modification permitted and SISSL and Vim and zlib

BuildRequires:  ovirt-node-tools
BuildRequires:  libguestfs-tools
Requires:       rpmdevtools

%define _isoname %name-%version-%{?build_release}
%define app_root %{_datadir}/%{name}


%description
The iso boot image for %{product}.
This rpm contains only the iso image.


%prep
export OVER=$(echo %{version} | egrep -o ".{3}" | tr -d .)
export DIST=$(echo %{dist} | egrep -o "[fe].*")
bash %SOURCE2 $OVER $DIST > repos-for-edit-node-iso.repo


%build
#
# Build the Node for Engine ISO by leveraging edit-node
#
export INSTALL=ovirt-node-plugin-vdsm,gettext,pm-utils,make
export UPDATE=glusterfs-libs,glusterfs-api,openssl

edit-node -d -v \
    --repo repos-for-edit-node-iso.repo \
    --install $INSTALL,$UPDATE %{source1} \
    --name %{_isoname}.iso \
    --output %{buildroot}


%install
%{__install} -d -m0755 %{buildroot}%{app_root}
%{__install} -p -m0644 %{SOURCE1} %{buildroot}%{app_root}/%{name}-%{version}-%{release}.iso
echo %{version},%{release} > %{buildroot}%{app_root}/version-%{version}-%{release}.txt
echo %{vdsm_compat} > %{buildroot}%{app_root}/vdsm-compatibility-%{version}-%{release}.txt


%post
nvr=0
for ver in %{app_root}/version-*txt; do
    ver=$(basename $(echo $ver |  sed 's/\.txt//'))
    if [ "$nvr" = "0" ]; then
        nvr=$ver
    else
        rpmdev-vercmp $nvr $ver >/dev/null 2>&1
        rc=$?
        if [ $rc = 12 ]; then
            nvr=$ver
        fi
    fi
done
ln -snf %{app_root}/${nvr}.txt  %{app_root}/version.txt
ln -snf %{app_root}/ovirt-node-iso-${nvr#*-}.iso %{app_root}/%{name}.iso
if [ -f %{app_root}/vdsm-compatibility-${nvr#*-}.txt ]; then
    ln -snf %{app_root}/vdsm-compatibility-${nvr#*-}.txt %{app_root}/vdsm-compatibility.txt
fi

# Extract the metadata file
virt-cat --add %{_isoname}.iso \
    /isolinux/version > %{buildroot}/%{app_root}/%{_isoname}.iso.meta


%preun
#first remove all symlinks
rm %{app_root}/version.txt
rm %{app_root}/%{name}.iso
rm -f %{app_root}/vdsm-compatibility.txt

nvr=0
for ver in %{app_root}/version-*txt; do
    ver=$(basename $(echo $ver |  sed 's/\.txt//'))
    if [ "$ver" = "version-%{version}-%{release}" ]; then
        continue
    fi
    if [ "$nvr" = "0" ]; then
        nvr=$ver
    else
        rpmdev-vercmp $nvr $ver >/dev/null 2>&1
        rc=$?
        if [ $rc = 12 ]; then
            nvr=$ver
        fi
    fi
done
if [ ! "$nvr" = "0" ]; then
    ln -snf %{app_root}/${nvr}.txt  %{app_root}/version.txt
    ln -snf %{app_root}/rhevh-${nvr#*-}.iso %{app_root}/%{name}.iso
    if [ -f %{app_root}/vdsm-compatibility-${nvr#*-}.txt ]; then
        ln -snf %{app_root}/vdsm-compatibility-${nvr#*-}.txt %{app_root}/vdsm-compatibility.txt
    fi
fi


%files
%defattr(0644,root,root,0755)
%{app_root}
%{app_root}/%{_isoname}.iso
%{app_root}/%{_isoname}.iso.meta
%{app_root}/version-%{version}-%{release}.txt
%{app_root}/vdsm-compatibility-%{version}-%{release}.txt



%changelog
* Mon May 12 2014 Fabian Deutsch <fabiand@redhat.com> - 3.4.1-1.0
- Major upgrade
- Use edit-node and base images

* Mon Oct 15 2012 Mike Burns <mburns@redhat.com> 2.5.999
- add vdsm-compatibility version text file to rpm.

* Wed Feb 08 2012 Mike Burns <mburns@redhat.com> 2.2.2-2.2
- Initial version
