#
# spec file for package rubygem-webyast-firewall
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


Name:           rubygem-webyast-firewall
Version:        0.3.9
Release:        0
%define mod_name webyast-firewall
%define mod_full_name %{mod_name}-%{version}
#
#
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  rubygems_with_buildroot_patch
%rubygems_requires
BuildRequires:  rubygem-restility
BuildRequires:  rubygem-webyast-rake-tasks >= 0.3.5
BuildRequires:  webyast-base
BuildRequires:  webyast-base-testsuite
PreReq:         webyast-base
PreReq:         rubygem-webyast-rake-tasks >= 0.3.5
%if 0%{?suse_version} == 0 || %suse_version > 1110
Requires:       yast2-core >= 2.18.10
%else
Requires:       yast2-core >= 2.17.30.1
%endif
Requires:	yast2
Requires:       SuSEfirewall2

Obsoletes:	webyast-firewall-ws < %{version}
Obsoletes:	webyast-firewall-ui < %{version}
Provides:	webyast-firewall-ws = %{version}
Provides:	webyast-firewall-ui = %{version}

Summary:        WebYaST - Firewall management service
License:        GPL-2.0
Group:          Productivity/Networking/Web/Utilities
Source:         %{mod_full_name}.gem
Source1:        org.opensuse.yast.modules.yapi.firewall.policy
Source2:        FIREWALL.pm

%package doc
Summary:        RDoc documentation for %{mod_name}
Group:          Development/Languages/Ruby
Requires:       %{name} = %{version}

%package testsuite
Summary:        Test suite for %{mod_name}
Group:          Development/Languages/Ruby
Requires:       %{name} = %{version}

%description
WebYaST - Plugin provides REST based interface to handle firewall settings.
Authors:
--------
    Martin Kudlvasr<mkudlvasr@novell.com>

%description testsuite
This package contains complete testsuite for webyast-firewall package.
It's only needed for verifying the functionality of the module and it's not
needed at runtime.

%description doc
Documentation generated at gem installation time.
Usually in RDoc and RI formats.

%prep

%build
%create_restart_script

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
cp %{SOURCE2} $RPM_BUILD_ROOT/usr/share/YaST2/modules/YaPI/

%webyast_build_restdoc

%webyast_build_plugin_assets

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%post
#
# granting all permissions for root
#
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null ||:
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant > /dev/null ||:

%restart_webyast

%postun
%webyast_remove_assets

%files 
%defattr(-,root,root)
%{_libdir}/ruby/gems/%{rb_ver}/cache/%{mod_full_name}.gem
%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/
%exclude %{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/test
%{_libdir}/ruby/gems/%{rb_ver}/specifications/%{mod_full_name}.gemspec

# precompiled assets
%dir %{webyast_dir}/public/assets
%{webyast_dir}/public/assets/*

%dir /usr/share/%{webyast_polkit_dir}
%attr(644,root,root) %config /usr/share/%{webyast_polkit_dir}/org.opensuse.yast.modules.yapi.firewall.policy

# YaPI dir
%dir /usr/share/YaST2/
%dir /usr/share/YaST2/modules/
%dir /usr/share/YaST2/modules/YaPI/
/usr/share/YaST2/modules/YaPI/FIREWALL.pm

%restart_script_name

%files doc
%defattr(-,root,root,-)
%doc %{_libdir}/ruby/gems/%{rb_ver}/doc/%{mod_full_name}/

%files testsuite
%defattr(-,root,root,-)
%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/test

%changelog
