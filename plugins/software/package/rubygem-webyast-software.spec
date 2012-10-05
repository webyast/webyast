#
# spec file for package rubygem-webyast-software
#
# Copyright (c) 2012 SUSE LINUX Products GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           rubygem-webyast-software
Version:        0.3.28
Release:        0
%define mod_name webyast-software
%define mod_full_name %{mod_name}-%{version}
#
#
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  rubygems_with_buildroot_patch
%rubygems_requires
BuildRequires:  webyast-base >= 0.3
BuildRequires:  webyast-base-testsuite
PreReq:         webyast-base >= 0.3

Obsoletes:      webyast-software-ui < %{version}
Obsoletes:      webyast-software-ws < %{version}
Provides:       webyast-software-ui = %{version}
Provides:       webyast-software-ws = %{version}

Requires:       rubygem-ruby-dbus
BuildRequires:  rubygem-ruby-dbus

%if 0%{?suse_version} == 0 || %{?suse_version} > 1120
# openSUSE-11.3 or newer
Requires:       PackageKit >= 0.5.1-6
%else
# openSUSE-11.1 or SLES11
Requires:       PackageKit >= 0.3.14
%endif

Url:            http://en.opensuse.org/Portal:WebYaST
Summary:        WebYaST - software management 
License:        GPL-2.0
Group:          Productivity/Networking/Web/Utilities
Source:         %{mod_full_name}.gem
Source1:        org.opensuse.yast.modules.yapi.patches.policy
Source2:        org.opensuse.yast.modules.yapi.packages.policy
Source3:        org.opensuse.yast.modules.yapi.repositories.policy

%package doc
Summary:        RDoc documentation for %{mod_name}
Group:          Development/Languages/Ruby
Requires:       %{name} = %{version}

%description doc
Documentation generated at gem installation time.
Usually in RDoc and RI formats.

%package testsuite
Summary:        Test suite for %{mod_name}
Group:          Development/Languages/Ruby
Requires:       %{name} = %{version}

%description
WebYaST - Plugin providing REST based interface to handle repositories, patches and packages.

Authors:
--------
    Stefan Schubert <schubi@opensuse.org>

%description testsuite
This package contains complete testsuite for webyast-software package.
It's only needed for verifying the functionality of the module and it's not
needed at runtime.

%prep

%build

%check
# run the testsuite
#
# Disabled for now.
# PackageKit/DBus need /proc and thus don't run in build environment.
# But both are required for testing :-/
# reference: bnc#597868
# -percent-webyast_check

%install
%gem_install %{S:0}

# Policies
mkdir -p $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}
install -m 0644 %SOURCE1 $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}
install -m 0644 %SOURCE2 $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}
install -m 0644 %SOURCE3 $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}

mkdir -p $RPM_BUILD_ROOT/var/lib/webyast/software/licenses/accepted

%webyast_build_plugin_assets

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%post
#
# granting all permissions for root
#
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null ||:
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant > /dev/null ||:

# grant the permission for the webyast user
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant --policy org.freedesktop.packagekit.system-sources-configure >& /dev/null || true
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant --policy org.freedesktop.packagekit.system-update >& /dev/null || true
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant --policy org.freedesktop.packagekit.package-eula-accept >& /dev/null || true

%webyast_update_assets

%postun
%webyast_remove_assets

%files 

%defattr(-,root,root,-)
%{_libdir}/ruby/gems/%{rb_ver}/cache/%{mod_full_name}.gem
%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/
%exclude %{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/test
%{_libdir}/ruby/gems/%{rb_ver}/specifications/%{mod_full_name}.gemspec

# precompiled assets
%dir %{webyast_dir}/public/assets
%{webyast_dir}/public/assets/*

%dir /usr/share/%{webyast_polkit_dir}
%attr(644,root,root) %config /usr/share/%{webyast_polkit_dir}/org.opensuse.yast.modules.yapi.patches.policy
%attr(644,root,root) %config /usr/share/%{webyast_polkit_dir}/org.opensuse.yast.modules.yapi.packages.policy
%attr(644,root,root) %config /usr/share/%{webyast_polkit_dir}/org.opensuse.yast.modules.yapi.repositories.policy
%attr(775,%{webyast_user},root) /var/lib/webyast/software

%files doc
%defattr(-,root,root,-)
%doc %{_libdir}/ruby/gems/%{rb_ver}/doc/%{mod_full_name}/

%files testsuite
%defattr(-,root,root,-)
%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/test

%changelog
