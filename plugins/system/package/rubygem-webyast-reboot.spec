#
# spec file for package webyast-reboot
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


# norootforbuild
Name:           rubygem-webyast-system
Version:        0.1
Release:        0
%define mod_name webyast-system
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


Summary:        WebYaST - reboot/shutdown
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
polkit-auth --user %{webyast_ws_user} --grant org.freedesktop.consolekit.system.stop >& /dev/null || true
polkit-auth --user %{webyast_ws_user} --grant org.freedesktop.consolekit.system.stop-multiple-users >& /dev/null || true
polkit-auth --user %{webyast_ws_user} --grant org.freedesktop.consolekit.system.restart >& /dev/null || true
polkit-auth --user %{webyast_ws_user} --grant org.freedesktop.consolekit.system.restart-multiple-users >& /dev/null || true

## granting all permissions for root
polkit-auth --user root --grant org.freedesktop.consolekit.system.stop >& /dev/null || true
polkit-auth --user root --grant org.freedesktop.consolekit.system.stop-multiple-users >& /dev/null || true
polkit-auth --user root --grant org.freedesktop.consolekit.system.restart >& /dev/null || true
polkit-auth --user root --grant org.freedesktop.consolekit.system.restart-multiple-users >& /dev/null || true

%webyast_update_assets

%postun
# don't remove the rights during package update ($1 > 0)
# see https://fedoraproject.org/wiki/Packaging/ScriptletSnippets#Syntax for details
if [ $1 -eq 0 ] ; then
  polkit-auth --user %{webyast_ws_user} --revoke org.freedesktop.consolekit.system.stop >& /dev/null || true
  polkit-auth --user %{webyast_ws_user} --revoke org.freedesktop.consolekit.system.stop-multiple-users >& /dev/null || true
  polkit-auth --user %{webyast_ws_user} --revoke org.freedesktop.consolekit.system.restart >& /dev/null || true
  polkit-auth --user %{webyast_ws_user} --revoke org.freedesktop.consolekit.system.restart-multiple-users >& /dev/null || true
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

