%define product oVirt Node
%define product_short oVirt Node
%define product_code ovirt-node

Name:		ovirt-node-iso
Version:	2.2.2
Release:	2.2%{?dist}
Summary:	%{product} ISO Image
BuildArch:  noarch
Source1:    %{product_code}-image-%{version}-%{release}.iso
Group:		Applications/System
License:	License: AFL and BSD and (BSD or GPLv2+) and BSD with advertising and Boost and GFDL and GPL and GPL+ and (GPL+ or Artistic) and GPLv1+ and GPLv2 and (GPLv2 or BSD) and (GPLv2 or GPLv3) and GPLv2 with exceptions and GPLv2+ and (GPLv2+ or AFL) and GPLv2+ with exceptions and GPLv3 and GPLv3+ and GPLv3+ with exceptions and IJG and ISC and LGPLv2 and LGPLv2+ and (LGPLv2+ or BSD) and (LGPLv2+ or MIT) and LGPLv2+ with exceptions and LGPLv2/GPLv2 and LGPLv3 and LGPLv3+ and MIT and (MIT or LGPLv2+ or BSD) and (MPLv1.1 or GPLv2+ or LGPLv2+) and Open Publication and OpenLDAP and OpenSSL and Public Domain and Python and (Python or ZPLv2.0) and Rdisc and Redistributable, no modification permitted and SISSL and Vim and zlib
URL:		http://ovirt.org/
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

Requires:	rpmdevtools
%define app_root %{_datadir}/%{name}

%description
The iso boot image for %{product}.
This rpm contains only the iso image.

%prep

%build

%install
%{__rm} -rf %{buildroot}
mkdir %{buildroot}

%{__install} -d -m0755 %{buildroot}%{app_root}
%{__install} -p -m0644 %{SOURCE1} %{buildroot}%{app_root}/%{product_code}-%{version}-%{release}.iso
echo %{version},%{release} > %{buildroot}%{app_root}/version-%{version}-%{release}.txt

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
ln -snf %{app_root}/rhevh-${nvr#*-}.iso %{app_root}/%{name}.iso

%preun
#first remove all symlinks
rm %{app_root}/version.txt
rm %{app_root}/%{name}.iso

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
fi

%clean
%{__rm} -rf %{buildroot}


%files
%defattr(0644,root,root,0755)
%{app_root}
%{app_root}/%{product_code}-%{version}-%{release}.iso
%{app_root}/version-%{version}-%{release}.txt



%changelog
* Wed Feb 08 2012 Mike Burns <mburns@redhat.com> 2.2.2-2.2
- Initial version
