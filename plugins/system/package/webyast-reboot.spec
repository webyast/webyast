#
# spec file for package webyast-reboot
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           webyast-reboot
Provides:       WebYaST(org.opensuse.yast.system.system)
Provides:       yast2-webservice-system = %{version}
Obsoletes:      yast2-webservice-system < %{version}
PreReq:         yast2-webservice
License:        GPL-2.0
Group:          Productivity/Networking/Web/Utilities
URL:            http://en.opensuse.org/Portal:WebYaST
Autoreqprov:    on
Version:        0.2.4
Release:        0
Summary:        WebYaST - reboot/shutdown
Source:         www.tar.bz2
Source1:        org.opensuse.yast.system.power-management.policy
Source2:        01-org.opensuse.yast.system.power-management.pkla

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
BuildRequires:  rubygem-webyast-rake-tasks >= 0.1.3
BuildRequires:  rubygem-restility
BuildRequires:  webyast-base-testsuite
# the testsuite is run during build
BuildRequires:  rubygem-test-unit rubygem-mocha

%define plugin_name system
%define plugin_dir %{webyast_dir}/vendor/plugins/%{plugin_name}

%package testsuite
Group:    Productivity/Networking/Web/Utilities
Requires: %{name} = %{version}
Requires: webyast-base-testsuite
Summary:  Testsuite for webyast-reboot package

%description
WebYaST - Plugin providing REST based interface for system reboot/shutdown.

Authors:
--------
Ladislav Slezak <lslezak@novell.com>

%description testsuite
Testsuite for webyast-reboot package.

%prep
%setup -q -n www

%build
# build restdoc documentation
mkdir -p public/%{plugin_name}/restdoc
%webyast_restdoc

export RAILS_PARENT=%{webyast_dir}
env LANG=en rake makemo

# do not package restdoc sources
rm -rf restdoc
#do not package generated doc
rm -rf doc

%check
%webyast_check

%install
#
# Install all web and frontend parts.
#
mkdir -p $RPM_BUILD_ROOT%{plugin_dir}
cp -a * $RPM_BUILD_ROOT%{plugin_dir}/
rm -f $RPM_BUILD_ROOT%{plugin_dir}/COPYING

# Policies
mkdir -p $RPM_BUILD_ROOT/usr/share/polkit-1/actions
install -m 0644 %SOURCE1 $RPM_BUILD_ROOT/usr/share/polkit-1/actions

%if 0%{?suse_version} == 0 || 0%{?suse_version} > 1130
# openSUSE-11.4 has policykit-1 which uses .pkla files
mkdir -p $RPM_BUILD_ROOT/var/lib/polkit-1/localauthority/10-vendor.d
install -m 0644 %SOURCE2 $RPM_BUILD_ROOT/var/lib/polkit-1/localauthority/10-vendor.d/
%if 0%{?suse_version} == 1130
# openSUSE-11.3+ has policykit-1 which uses .pkla files
mkdir -p $RPM_BUILD_ROOT/etc/polkit-1/localauthority/10-vendor.d
install -m 0644 %SOURCE2 $RPM_BUILD_ROOT/etc/polkit-1/localauthority/10-vendor.d/
%endif
%endif

# remove .po files (no longer needed)
rm -rf $RPM_BUILD_ROOT/%{plugin_dir}/po

# search locale files
%find_lang webyast-reboot


%clean
rm -rf $RPM_BUILD_ROOT


%post
# granting all permissions for root
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null ||:
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant > /dev/null ||:

# grant the permission for the webyast user
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant --policy org.freedesktop.consolekit.system.stop >& /dev/null || true
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant --policy org.freedesktop.consolekit.system.stop-multiple-users >& /dev/null || true
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant --policy org.freedesktop.consolekit.system.restart >& /dev/null || true
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant --policy org.freedesktop.consolekit.system.restart-multiple-users >& /dev/null || true

%files -f webyast-reboot.lang

%defattr(-,root,root)
%dir %{webyast_dir}
%dir %{webyast_dir}/vendor
%dir %{webyast_dir}/vendor/plugins
%dir %{plugin_dir}
%dir /usr/share/polkit-1
%dir /usr/share/polkit-1/actions
%{plugin_dir}/README
%{plugin_dir}/Rakefile
%{plugin_dir}/init.rb
%{plugin_dir}/install.rb
%{plugin_dir}/uninstall.rb
%{plugin_dir}/app
%{plugin_dir}/config
%{plugin_dir}/public
%{plugin_dir}/locale

%attr(644,root,root) %config /usr/share/polkit-1/actions/org.opensuse.yast.system.power-management.policy
%doc COPYING
%if 0%{?suse_version} == 0 || 0%{?suse_version} > 1130
%dir /var/lib/polkit-1/localauthority
%dir /var/lib/polkit-1/localauthority/10-vendor.d
%config /var/lib/polkit-1/localauthority/10-vendor.d/*
%if 0%{?suse_version} == 1130
%config /etc/polkit-1/localauthority/10-vendor.d/*
%endif
%endif

%files testsuite
%defattr(-,root,root)
%{plugin_dir}/test

%changelog

