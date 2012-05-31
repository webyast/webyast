#
# spec file for package rubygem-webyast-system
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


Name:           rubygem-webyast-system
Version:        0.3.2
Release:        0
%define mod_name webyast-system
%define mod_full_name %{mod_name}-%{version}
#
#
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  rubygems_with_buildroot_patch
%rubygems_requires
BuildRequires:  rubygem-restility
BuildRequires:  webyast-base >= 0.3
BuildRequires:  webyast-base-testsuite
PreReq:         webyast-base >= 0.3

Obsoletes:	webyast-reboot-ws
Obsoletes:	webyast-reboot-ui
Provides:	webyast-reboot-ws
Provides:	webyast-reboot-ui

Summary:        WebYaST - reboot/shutdown
License:        GPL-2.0
Group:          Productivity/Networking/Web/Utilities
Source:         %{mod_full_name}.gem
Source1:        org.opensuse.yast.modules.yapi.system.policy

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
WebYaST - Plugin providing REST based interface for system reboot/shutdown.

Authors:
--------
Ladislav Slezak <lslezak@novell.com>

%description testsuite
Testsuite for webyast-reboot package.

%prep

%build

%check
%webyast_run_plugin_tests

%install
%gem_install %{S:0}

# Policies
mkdir -p $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}
install -m 0644 %SOURCE1 $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}

%webyast_build_restdoc public/system/restdoc

# remove empty public
rm -rf $RPM_BUILD_ROOT/%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/public

%webyast_build_plugin_assets

%clean
%{__rm} -rf $RPM_BUILD_ROOT

# posttrans is used instead of post so it ensures the rights are
# granted even after upgrading from old package (before renaming) (bnc#645310)
# (see https://fedoraproject.org/wiki/Packaging/ScriptletSnippets#Syntax )
%posttrans
# granting all permissions for the web user
#FIXME don't silently fail
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant --policy org.freedesktop.consolekit.system.stop >& /dev/null || true
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant --policy org.freedesktop.consolekit.system.stop-multiple-users >& /dev/null || true
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant --policy org.freedesktop.consolekit.system.restart >& /dev/null || true
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant --policy org.freedesktop.consolekit.system.restart-multiple-users >& /dev/null || true

## granting all permissions for root
/usr/sbin/grantwebyastrights --user root --action grant --policy org.freedesktop.consolekit.system.stop >& /dev/null || true
/usr/sbin/grantwebyastrights --user root --action grant --policy org.freedesktop.consolekit.system.stop-multiple-users >& /dev/null || true
/usr/sbin/grantwebyastrights --user root --action grant --policy org.freedesktop.consolekit.system.restart >& /dev/null || true
/usr/sbin/grantwebyastrights --user root --action grant --policy org.freedesktop.consolekit.system.restart-multiple-users >& /dev/null || true

%webyast_update_assets

%postun
# don't remove the rights during package update ($1 > 0)
# see https://fedoraproject.org/wiki/Packaging/ScriptletSnippets#Syntax for details
if [ $1 -eq 0 ] ; then
  /usr/sbin/grantwebyastrights --user %{webyast_user} --action revoke --policy org.freedesktop.consolekit.system.stop >& /dev/null || true
  /usr/sbin/grantwebyastrights --user %{webyast_user} --action revoke --policy org.freedesktop.consolekit.system.stop-multiple-users >& /dev/null || true
  /usr/sbin/grantwebyastrights --user %{webyast_user} --action revoke --policy org.freedesktop.consolekit.system.restart >& /dev/null || true
  /usr/sbin/grantwebyastrights --user %{webyast_user} --action revoke --policy org.freedesktop.consolekit.system.restart-multiple-users >& /dev/null || true
fi

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

# restdoc documentation
%dir %{webyast_dir}/public/system
%{webyast_dir}/public/system/restdoc

%dir /usr/share/%{webyast_polkit_dir}
%attr(644,root,root) %config /usr/share/%{webyast_polkit_dir}/org.opensuse.yast.modules.yapi.system.policy

%files doc
%defattr(-,root,root,-)
%doc %{_libdir}/ruby/gems/%{rb_ver}/doc/%{mod_full_name}/

%files testsuite
%defattr(-,root,root,-)
%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/test

%changelog
