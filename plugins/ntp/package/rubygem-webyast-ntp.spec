#
# spec file for package rubygem-webyast-ntp
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


Name:           rubygem-webyast-ntp
Version:        0.3.7
Release:        0
%define mod_name webyast-ntp
%define mod_full_name %{mod_name}-%{version}
#
#
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  rubygems_with_buildroot_patch
%rubygems_requires
BuildRequires:  rubygem-restility
BuildRequires:  webyast-base >= 0.3.31
BuildRequires:  webyast-base-testsuite
BuildRequires:  rubygem-webyast-rake-tasks >= 0.3.5
PreReq:         webyast-base >= 0.3.31
PreReq:         rubygem-webyast-rake-tasks >= 0.3.5

Obsoletes:	webyast-ntp-ws < %{version}
Provides:	webyast-ntp-ws = %{version}

#for YaPI needs ntp
Requires:       ntp
#for YaPI hwclock
Requires:       util-linux

Url:            http://en.opensuse.org/Portal:WebYaST
Summary:        WebYaST - NTP 
License:        GPL-2.0
Group:          Productivity/Networking/Web/Utilities
Source:         %{mod_full_name}.gem
Source1:        NTP.pm
Source2:        org.opensuse.yast.modules.yapi.ntp.policy
Source3:        50-default-webyast-ntp.rules

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
WebYaST - Plugin providing REST based interface to basic ntp time synchronization

Authors:
--------
    Josef Reidinger <jreidinger@novell.com>

%description testsuite
This package contains complete testsuite for webyast-ntp package.
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

#YaPI module
mkdir -p $RPM_BUILD_ROOT/usr/share/YaST2/modules/YaPI/
cp %{SOURCE1} $RPM_BUILD_ROOT/usr/share/YaST2/modules/YaPI/
#policies
mkdir -p $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}
cp %{SOURCE2} $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}
%if %suse_version >= 1230
mkdir -p $RPM_BUILD_ROOT/etc/polkit-1/rules.d/
install -m 0644 %SOURCE3 $RPM_BUILD_ROOT/etc/polkit-1/rules.d/
%endif

%webyast_build_restdoc

#just a dummy locale cause not translation are available
mkdir -p $RPM_BUILD_ROOT/%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/locale

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%post
%if %suse_version < 1230
# granting all permissions for the webservice user and root
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant > /dev/null
%endif

%restart_webyast

%files 
%defattr(-,root,root,-)
%{_libdir}/ruby/gems/%{rb_ver}/cache/%{mod_full_name}.gem
%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/
%exclude %{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/test
%{_libdir}/ruby/gems/%{rb_ver}/specifications/%{mod_full_name}.gemspec

# ntp require only yast2-dbus server, so it must ensure that directory exist
%dir /usr/share/YaST2/
%dir /usr/share/YaST2/modules/
%dir /usr/share/YaST2/modules/YaPI/
%attr(644,root,root) /usr/share/YaST2/modules/YaPI/NTP.pm
%attr(644,root,root) /usr/share/%{webyast_polkit_dir}/org.opensuse.yast.modules.yapi.ntp.policy
%if %suse_version >= 1230
/etc/polkit-1/rules.d/50-default-webyast-ntp.rules
%endif

%restart_script_name

%files doc
%defattr(-,root,root,-)
%doc %{_libdir}/ruby/gems/%{rb_ver}/doc/%{mod_full_name}/

%files testsuite
%defattr(-,root,root,-)
%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/test

%changelog
