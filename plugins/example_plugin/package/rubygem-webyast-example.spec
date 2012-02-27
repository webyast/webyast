#
# example spec file for package webyast-example-ws
#
# Copyright (c) 2010 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


# norootforbuild
Name:           rubygem-webyast-example
Version:        0.1
Release:        0
%define mod_name webyast-example
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

Summary:        WebYaST - example plugin

#
Url:            http://rubygems.org/gems/webyast-example
Source:         %{mod_full_name}.gem
Source1:        example.service.conf
Source2:        exampleService.rb
Source3:        example.service.service
Source4:        org.opensuse.yast.modules.yapi.example.policy
Source5:        wicd-rpmlintrc

%package doc
Summary:        RDoc documentation for %{mod_name}
Group:          Development/Languages/Ruby
Requires:       %{name} = %{version}
%description doc
Documentation generated at gem installation time.
Usually in RDoc and RI formats.

%package testsuite
Group:          Development/Languages/Ruby
Requires:       %{name} = %{version}
Requires:       webyast-base-testsuite
Summary:        Testsuite for webyast-example package

%description
WebYaST - Plugin providing EXAMPLE REST based interface

Authors:
--------
    Josef Reidinger <jreidinger@novell.com>

%description testsuite
This package contains complete testsuite for webyast-example package.
It's only needed for verifying the functionality of the module and it's not
needed at runtime.

%prep

%build

%check
# run the testsuite
%webyast_run_plugin_tests

%install

#
# Install all web and frontend parts.
#
%gem_install %{S:0}

#Dbus service permissions configuration
mkdir -p $RPM_BUILD_ROOT/etc/dbus-1/system.d/
cp %{SOURCE1} $RPM_BUILD_ROOT/etc/dbus-1/system.d/
# binary providing DBus service - place is specified in service config
mkdir -p $RPM_BUILD_ROOT/usr/local/sbin/
cp %{SOURCE2} $RPM_BUILD_ROOT/usr/local/sbin
#Dbus service describotion
mkdir -p $RPM_BUILD_ROOT/usr/share/dbus-1/system-services/
cp %{SOURCE3} $RPM_BUILD_ROOT/usr/share/dbus-1/system-services/
#policies
mkdir -p $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}
cp %{SOURCE4} $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}

# remove empty public
rm -rf $RPM_BUILD_ROOT/%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/public

%webyast_build_plugin_assets

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%post
# granting all permissions for the webyast user and root
/usr/sbin/grantwebyastrights --user root --action grant --policy org.opensuse.yast.system.example.read > /dev/null || :
/usr/sbin/grantwebyastrights --user root --action grant --policy org.opensuse.yast.system.example.write > /dev/null || :
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant --policy org.opensuse.yast.system.example.read > /dev/null || :
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant --policy org.opensuse.yast.system.example.write > /dev/null || :

%webyast_update_assets

%postun
%webyast_update_assets

%files 
%defattr(-,root,root)
%{_libdir}/ruby/gems/%{rb_ver}/cache/%{mod_full_name}.gem
%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/
%exclude %{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/test
%{_libdir}/ruby/gems/%{rb_ver}/specifications/%{mod_full_name}.gemspec

# precompiled assets
%dir %{webyast_dir}/public/assets
%{webyast_dir}/public/assets/*

%attr(744,root,root) /usr/local/sbin/exampleService.rb
%attr(644,root,root) /usr/share/%{webyast_polkit_dir}/org.opensuse.yast.modules.yapi.example.policy
%attr(644,root,root) /etc/dbus-1/system.d/example.service.conf
%attr(644,root,root) /usr/share/dbus-1/system-services/example.service.service

%files doc
%defattr(-,root,root,-)
%doc %{_libdir}/ruby/gems/%{rb_ver}/doc/%{mod_full_name}/

%files testsuite
%defattr(-,root,root,-)
%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/test

%changelog
