#
# spec file for package webyast-reboot-ws
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           webyast-reboot-ws
Provides:       WebYaST(org.opensuse.yast.system.system)
Provides:       yast2-webservice-system = %{version}
Obsoletes:      yast2-webservice-system < %{version}
PreReq:         yast2-webservice
# requires HAL for reboot/shutdown actions
Requires:	hal
License:	GPL v2 only
Group:          Productivity/Networking/Web/Utilities
Autoreqprov:    on
Version:        0.1.2
Release:        0
Summary:        WebYaST - reboot/shutdown service
Source:         www.tar.bz2
Url:            http://en.opensuse.org/YaST/Web
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
BuildRequires:  rubygem-webyast-rake-tasks >= 0.1.3
BuildRequires:	rubygem-restility
BuildRequires:  webyast-base-ws-testsuite
# the testsuite is run during build
BuildRequires:	rubygem-test-unit rubygem-mocha

#
%define pkg_user yastws
%define plugin_name system
#

%package testsuite
Group:    Productivity/Networking/Web/Utilities
Requires: %{name} = %{version}
Requires: webyast-base-ws-testsuite
Summary:  Testsuite for webyast-reboot-ws package

%description
WebYaST - Plugin providing REST based interface for system reboot/shutdown.

Authors:
--------
    Ladislav Slezak <lslezak@novell.com>

%description testsuite
Testsuite for webyast-reboot-ws webservice package.

%prep
%setup -q -n www

%build
# build restdoc documentation
mkdir -p public/system/restdoc
%webyast_ws_restdoc

# do not package restdoc sources
rm -rf restdoc
#do not package generated doc
rm -rf doc

%check
%webyast_ws_check

%install
#
# Install all web and frontend parts.
#
mkdir -p $RPM_BUILD_ROOT/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
cp -a * $RPM_BUILD_ROOT/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
rm -f $RPM_BUILD_ROOT/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/COPYING

%clean
rm -rf $RPM_BUILD_ROOT

%post
# granting all permissions for the web user
#FIXME don't silently fail
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
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/README
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/Rakefile
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/init.rb
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/install.rb
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/uninstall.rb
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/app
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/config
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/public
%doc COPYING

%files testsuite
%defattr(-,root,root)
%{webyast_ws_dir}/vendor/plugins/%{plugin_name}/test

%changelog
