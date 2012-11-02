#
# spec file for package webyast-registration
#
# Copyright (c) 2009 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


# norootforbuild
Name:           rubygem-webyast-registration
Version:        0.3.11
Release:        0
%define mod_name webyast-registration
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
PreReq:	        webyast-base >= 0.3
Recommends:     openssl-certs

Obsoletes:	webyast-registration-ws < %{version}
Obsoletes:	webyast-registration-ui < %{version}
Provides:	webyast-registration-ws = %{version}
Provides:	webyast-registration-ui = %{version}

URL:            http://en.opensuse.org/Portal:WebYaST
Summary:        WebYaST - Registration
Source:         %{mod_full_name}.gem
Source1:        org.opensuse.yast.modules.yapi.register.policy

# YaST2/modules/YSR.pm  
%if 0%{?suse_version} == 0 || 0%{?suse_version} > 1120
# non-suse, factory, and YaST:HEAD
Requires:       yast2-registration >= 2.19.7
%else
%if 0%{?suse_version} == 1120
Requires:       yast2-registration >= 2.18.5
%endif
%if 0%{?suse_version} <= 1110
# SLE11 and 11.1
Requires:       yast2-registration >= 2.17.35
%endif
%endif

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
WebYaST - Plugin providing REST based interface for the system registration at NCC, SMT or SLMS

Authors:
--------
    J. Daniel Schmidt <jdsn@novell.com>
    Stefan Schubert <schubi@novell.com>

%description testsuite
This package contains complete testsuite for webyast-registration package.
It's only needed for verifying the functionality of the module and it's not
needed at runtime.

%prep

%build

%check
# run the testsuite
%webyast_run_plugin_tests

%install
%gem_install %{S:0}

# Policies
mkdir -p $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}
install -m 0644 %SOURCE1 $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}

%webyast_build_plugin_assets

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%post
#
# granting all permissions for root and webyast
#
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant > /dev/null
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
%attr(644,root,root) %config /usr/share/%{webyast_polkit_dir}/org.opensuse.yast.modules.yapi.register.policy

%files doc
%defattr(-,root,root,-)
%doc %{_libdir}/ruby/gems/%{rb_ver}/doc/%{mod_full_name}/

%files testsuite
%defattr(-,root,root,-)
%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/test

%changelog
