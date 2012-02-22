#
# spec file for package rubygem-webyast-activedirectory
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

# norootforbuild
Name:           rubygem-webyast-activedirectory
Version:        0.1
Release:        0
%define mod_name webyast-activedirectory
%define mod_full_name %{mod_name}-%{version}
#
Group:          Development/Languages/Ruby
License:        GPL-2.0	
#
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  rubygems_with_buildroot_patch
%rubygems_requires
BuildRequires:	webyast-base, rubygem-sqlite3-ruby
BuildRequires:	rubygem-webyast-rake-tasks >= 0.2
BuildRequires:	webyast-base-testsuite
BuildRequires:	rubygem-restility
PreReq:	        webyast-base
PreReq:         rubygem-webyast-rake-tasks >= 0.2
Requires:       yast2-dbus-server

%if 0%{?suse_version} == 0 || %suse_version > 1110
Requires:       yast2-core >= 2.18.10
%else
Requires:       yast2-core >= 2.17.30.1
%endif

Source:         %{mod_full_name}.gem
Source1:        org.opensuse.yast.modules.yapi.activedirectory.policy
Source2:        ActiveDirectory.pm
#
Summary:        Webyast module for configuring activedirectory settings
%description
Webyast module for configuring activedirectory settings


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
%description testsuite
Test::Unit or RSpec files, useful for developers.

%prep
%build

%post
# granting all permissions for the web user
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant > /dev/null

%webyast_update_assets

%postun
%webyast_update_assets

%check

# run the testsuite
%webyast_run_plugin_tests

%install
%gem_install %{S:0}

# Policies
mkdir -p $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}
install -m 0644 %SOURCE1 $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}

#YaPI
mkdir -p $RPM_BUILD_ROOT/usr/share/YaST2/modules/YaPI/
install -m 0644 %{SOURCE2} $RPM_BUILD_ROOT/usr/share/YaST2/modules/YaPI/

%webyast_build_restdoc public/activedirectory/restdoc

# remove empty public
rm -rf $RPM_BUILD_ROOT/%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/public

%webyast_build_plugin_assets


%clean
%{__rm} -rf %{buildroot}

%files
%defattr(-,root,root,-)
%{_libdir}/ruby/gems/%{rb_ver}/cache/%{mod_full_name}.gem
%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/
%exclude %{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/test
%{_libdir}/ruby/gems/%{rb_ver}/specifications/%{mod_full_name}.gemspec

# precompiled assets
%dir %{webyast_dir}/public/assets
%{webyast_dir}/public/assets/*

# restdoc documentation
%dir %{webyast_dir}/public/activedirectory
%{webyast_dir}/public/activedirectory/restdoc

%dir /usr/share/%{webyast_polkit_dir}
%attr(644,root,root) %config /usr/share/%{webyast_polkit_dir}/org.opensuse.yast.modules.yapi.activedirectory.policy

# YaPI dir
%dir /usr/share/YaST2/
%dir /usr/share/YaST2/modules/
%dir /usr/share/YaST2/modules/YaPI/
/usr/share/YaST2/modules/YaPI/ActiveDirectory.pm

%files doc
%defattr(-,root,root,-)
%doc %{_libdir}/ruby/gems/%{rb_ver}/doc/%{mod_full_name}/

%files testsuite
%defattr(-,root,root,-)
%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/test

%changelog
