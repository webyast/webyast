#
# spec file for package webyast-terminal (Version 0.1)
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


# norootforbuild
Name:           rubygem-webyast-terminal
Version:        0.3.2
Release:        0
%define mod_name webyast-terminal
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
Requires:       shellinabox

URL:            http://en.opensuse.org/Portal:WebYaST
Summary:        WebYaST - terminal plugin
Source:         %{mod_full_name}.gem
Source1:        org.opensuse.yast.system.terminal.policy

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
WebYaST integration of shellinabox (web based AJAX terminal plugin)

Authors:
Vladislav Lewin <vlewin@suse.de>

%description testsuite
This package contains complete testsuite for webyast-terminal package.
It's only needed for verifying the functionality of the module and it's not
needed at runtime.

%prep

%build

%check
%webyast_run_plugin_tests

%install
%gem_install %{S:0}

mkdir -p $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}
cp %{SOURCE1} $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}

# remove empty public
rm -rf $RPM_BUILD_ROOT/%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/public

%webyast_build_plugin_assets

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%post
# granting all permissions for root
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null

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
%attr(644,root,root) /usr/share/%{webyast_polkit_dir}/org.opensuse.yast.modules.yapi.terminal.policy

%files doc
%defattr(-,root,root,-)
%doc %{_libdir}/ruby/gems/%{rb_ver}/doc/%{mod_full_name}/

%files testsuite
%defattr(-,root,root,-)
%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/test

%changelog

