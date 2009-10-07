#
# spec file for package yast2-webservice-system
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-webservice-system
PreReq:         yast2-webservice
# requires HAL for reboot/shutdown actions
Requires:	hal
Provides:       yast2-webservice:/srv/www/yastws/app/controllers/system_controller.rb
License:        MIT
Group:          Productivity/Networking/Web/Utilities
Autoreqprov:    on
Version:        0.0.4
Release:        0
Summary:        YaST2 - Webservice - System
Source:         www.tar.bz2
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch

#
%define pkg_user yastws
%define plugin_name system
#


%description
YaST2 - Webservice - REST based interface for basic system access

Authors:
--------
    Ladislav Slezak <lslezak@novell.com>

%prep
%setup -q -n www

%build

%install

#
# Install all web and frontend parts.
#
mkdir -p $RPM_BUILD_ROOT/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
cp -a * $RPM_BUILD_ROOT/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}

# do not package restdoc sources
rm -rf $RPM_BUILD_ROOT/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/restdoc


%clean
rm -rf $RPM_BUILD_ROOT

%post
# granting all permissions for the web user
polkit-auth --user %{pkg_user} --grant org.freedesktop.hal.power-management.shutdown >& /dev/null || true
polkit-auth --user %{pkg_user} --grant org.freedesktop.hal.power-management.shutdown-multiple-sessions >& /dev/null || true
polkit-auth --user %{pkg_user} --grant org.freedesktop.hal.power-management.reboot >& /dev/null || true
polkit-auth --user %{pkg_user} --grant org.freedesktop.hal.power-management.reboot-multiple-sessions >& /dev/null || true

# granting all permissions for root
polkit-auth --user root --grant org.freedesktop.hal.power-management.shutdown >& /dev/null || true
polkit-auth --user root --grant org.freedesktop.hal.power-management.shutdown-multiple-sessions >& /dev/null || true
polkit-auth --user root --grant org.freedesktop.hal.power-management.reboot >& /dev/null || true
polkit-auth --user root --grant org.freedesktop.hal.power-management.reboot-multiple-sessions >& /dev/null || true

%postun
# don't remove the rights during package update ($1 > 0)
# see https://fedoraproject.org/wiki/Packaging/ScriptletSnippets#Syntax for details
if [ $1 -eq 0 ] ; then
  # discard all configured permissions for the web user
  polkit-auth --user %{pkg_user} --revoke org.freedesktop.hal.power-management.shutdown >& /dev/null || :
  polkit-auth --user %{pkg_user} --revoke org.freedesktop.hal.power-management.shutdown-multiple-sessions >& /dev/null || :
  polkit-auth --user %{pkg_user} --revoke org.freedesktop.hal.power-management.reboot >& /dev/null || :
  polkit-auth --user %{pkg_user} --revoke org.freedesktop.hal.power-management.reboot-multiple-sessions >& /dev/null || :
fi

%files 
%defattr(-,root,root)
%dir /srv/www/%{pkg_user}
%dir /srv/www/%{pkg_user}/vendor
%dir /srv/www/%{pkg_user}/vendor/plugins
%dir /srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/MIT-LICENSE
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/README
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/Rakefile
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/init.rb
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/install.rb
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/uninstall.rb
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/app
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/config
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/public

%changelog
