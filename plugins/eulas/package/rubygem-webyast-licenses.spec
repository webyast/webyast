#
# spec file for package yast2-webservice-eula (Version 0.0.1)
#
# Copyright (c) 2008-09 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild
Name:           rubygem-webyast-eulas
Version:        0.1
Release:        0
%define mod_name webyast-eulas
%define mod_full_name %{mod_name}-%{version}

#
Group:          Productivity/Networking/Web/Utilities
License:        GPL-2.0	
#
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  rubygems_with_buildroot_patch
%rubygems_requires
BuildRequires:	webyast-base >= 0.3
BuildRequires:	webyast-base-testsuite
BuildRequires:	rubygem-restility
PreReq:	        webyast-base >= 0.3

Summary:        WebYaST - license management service
Source:         %{mod_full_name}.gem
Source1:        eulas-sles11.yml
Source2:        org.opensuse.yast.modules.yapi.license.policy
Source3:        eulas-opensuse11_1.yml

#
%define plugin_name eulas
#

%package doc
Summary:        RDoc documentation for %{mod_name}
Group:          Productivity/Networking/Web/Utilities
Requires:       %{name} = %{version}
%description doc
Documentation generated at gem installation time.
Usually in RDoc and RI formats.

%package testsuite
Group:    Productivity/Networking/Web/Utilities
Requires: %{name} = %{version}
Requires: webyast-base-testsuite
Summary:  Testsuite for webyast-licenses package

%description
WebYaST - Plugin providing REST based interface to handle user acceptation of EULAs.

Authors:
--------
    Martin Kudlvasr <mkudlvasr@suse.cz>
    Josef Reidinger <jreidinger@suse.cz>

%description testsuite
This package contains complete testsuite for webyast-licenses package.
It's only needed for verifying the functionality of the module and it's not
needed at runtime.

%prep

%build

%check
# run the testsuite
%webyast_run_plugin_tests

%post
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant > /dev/null

%webyast_update_assets

%postun
%webyast_update_assets

%install

#
# Install all web and frontend parts.
#
%gem_install %{S:0}
mkdir -p $RPM_BUILD_ROOT/usr/share/%{webyast_user}/%{plugin_name}

#sles_version does not exist any more (bnc#689901)
#to use openSUSE license, the OBS project must be named accordingly
case "%{_project}" in 
 *openSUSE:*)
  # use an openSUSE license by default
  SOURCE_CONFIG=%SOURCE3
  rm -r $RPM_BUILD_ROOT/%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/config/resources/licenses/SLES-11
  ;;
 *)
  # use a sles11 license by default
  SOURCE_CONFIG=%SOURCE1
  rm -r $RPM_BUILD_ROOT/%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/config/resources/licenses/openSUSE-11.1
  ;;
esac
mv $RPM_BUILD_ROOT/%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/config/resources/licenses $RPM_BUILD_ROOT/usr/share/%{webyast_user}/%{plugin_name}/
mkdir -p $RPM_BUILD_ROOT%{webyast_vardir}/%{plugin_name}/accepted-licenses

mkdir -p $RPM_BUILD_ROOT/etc/webyast/
cp $SOURCE_CONFIG $RPM_BUILD_ROOT/etc/webyast/eulas.yml

# Policies
mkdir -p $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}
cp %{SOURCE2} $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}

# remove empty public
rm -rf $RPM_BUILD_ROOT/%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/public

%webyast_build_plugin_assets

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%files 
%defattr(-,root,root)
%{_libdir}/ruby/gems/%{rb_ver}/cache/%{mod_full_name}.gem
%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/
%exclude %{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/test
%{_libdir}/ruby/gems/%{rb_ver}/specifications/%{mod_full_name}.gemspec
# precompiled assets
%dir %{webyast_dir}/public/assets
%{webyast_dir}/public/assets/*
%dir /usr/share/%{webyast_user}
%dir /usr/share/%{webyast_user}/%{plugin_name}
%dir %{webyast_vardir}
%dir %{webyast_vardir}/%{plugin_name}
/usr/share/%{webyast_user}/%{plugin_name}/licenses
%dir /etc/webyast/
%config /etc/webyast/eulas.yml
%attr(-,%{webyast_user},%{webyast_user}) %dir %{webyast_vardir}/%{plugin_name}/accepted-licenses
%dir /usr/share/%{webyast_polkit_dir}
%attr(644,root,root) %config /usr/share/%{webyast_polkit_dir}/org.opensuse.yast.modules.yapi.license.policy

%files doc
%defattr(-,root,root,-)
%doc %{_libdir}/ruby/gems/%{rb_ver}/doc/%{mod_full_name}/

%files testsuite
%defattr(-,root,root,-)
%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/test

%changelog
