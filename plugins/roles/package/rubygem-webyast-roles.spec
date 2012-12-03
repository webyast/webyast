#
# spec file for package rubygem-webyast-roles
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


Name:           rubygem-webyast-roles
Version:        0.3.7
Release:        0
%define mod_name webyast-roles
%define mod_full_name %{mod_name}-%{version}
#
#
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  rubygems_with_buildroot_patch
%rubygems_requires
BuildRequires:  webyast-base >= 0.3.31
BuildRequires:  webyast-base-testsuite
PreReq:         webyast-base >= 0.3.31

Obsoletes:      webyast-roles-ui < %{version}
Obsoletes:      webyast-roles-ws < %{version}
Provides:       webyast-roles-ui = %{version}
Provides:       webyast-roles-ws = %{version}

Url:            http://en.opensuse.org/Portal:WebYaST
Summary:        WebYaST - role management
License:        GPL-2.0
Group:          Productivity/Networking/Web/Utilities
Source:         %{mod_full_name}.gem
Source1:        roles.yml
Source2:        roles_assign.yml
Source3:        org.opensuse.yast.modules.yapi.roles.policy

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
WebYaST - Plugin providing REST based interface for roles management.

Authors:
--------
    Josef Reidinger <jreidinger@suse.cz>

%description testsuite
This package contains complete testsuite for webyast-roles package.
It's only needed for verifying the functionality of the module and it's not
needed at runtime.

%prep

%build
%create_restart_script

%check
# run the testsuite
%webyast_run_plugin_tests

%install
%gem_install %{S:0}

mkdir -p $RPM_BUILD_ROOT%{webyast_vardir}/roles
cp %{SOURCE1} %{SOURCE2} $RPM_BUILD_ROOT%{webyast_vardir}/roles

# Policies
mkdir -p $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}
install -m 0644 %SOURCE3 $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}

%webyast_build_plugin_assets

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%post
#
# granting all permissions for root 
#
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null
# XXX not nice to get webyast all permissions, but now not better solution
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant > /dev/null

%webyast_update_assets

%restart_webyast

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

%attr(0700,%{webyast_user},%{webyast_user}) %dir %{webyast_vardir}/roles
%attr(0600,%{webyast_user},%{webyast_user}) %config %{webyast_vardir}/roles/*
%attr(644,root,root) %config /usr/share/%{webyast_polkit_dir}/org.opensuse.yast.modules.yapi.roles.policy

%restart_script_name

%files doc
%defattr(-,root,root,-)
%doc %{_libdir}/ruby/gems/%{rb_ver}/doc/%{mod_full_name}/

%files testsuite
%defattr(-,root,root,-)
%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/test



%changelog
