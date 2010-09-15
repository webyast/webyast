#
# spec file for package webyast-base-ws (Version 0.1.19)
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           webyast-base-ws
Provides:       yast2-webservice = %{version}
Obsoletes:      yast2-webservice < %{version}

%if 0%{?suse_version} == 0 || %suse_version > 1110
# 11.2 or newer

%if 0%{?suse_version} > 1120
# since 11.3, they are in a separate subpackage
Requires:       sysvinit-tools
%else
# Require startproc respecting -p, bnc#559534#c44
Requires:       sysvinit > 2.86-215.2
%endif
Requires:       yast2-core >= 2.18.10
# Require lighttpd whose postun does not mass kill, bnc#559534#c19
# (Updating it later does not work because postun uses the old version.)
PreReq:         lighttpd > 1.4.20-3.6
%else
# 11.1 or SLES11
Requires:       yast2-core >= 2.17.30.1
Requires:       sysvinit > 2.86-195.3.1
PreReq:         lighttpd > 1.4.20-2.29.1
%endif

Requires:	lighttpd-mod_magnet, ruby-fcgi, ruby-dbus, sqlite, syslog-ng
Requires:       rubygem-webyast-rake-tasks, rubygem-http_accept_language
Requires:	yast2-dbus-server
# 634404
Recommends:     logrotate
# gamin gives problems with lighttpd, so better conflict with it for now
Conflicts:      gamin
PreReq:         PolicyKit, PackageKit, rubygem-rake, rubygem-sqlite3
PreReq:         rubygem-rails-2_3 >= 2.3.4
PreReq:         rubygem-rpam, rubygem-polkit, rubygem-gettext_rails
License:	LGPL v2.1 only
Group:          Productivity/Networking/Web/Utilities
URL:            http://en.opensuse.org/Portal:WebYaST
Autoreqprov:    on
Version:        0.2.5
Release:        0
Summary:        WebYaST - base components for rest service
Source:         www.tar.bz2
Source1:        webyastPermissionsService.rb
Source2:        webyast.permissions.conf
Source3:        webyast.permissions.service.service
Source4:        org.opensuse.yast.permissions.policy
Source5:        grantwebyastrights
Source6:        yast_user_roles
Source7:        lighttpd.conf
Source8:        modules.conf
Source9:        yastws
Source10:       webyast
Source11:	webyast-ws.lr.conf
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  ruby, pkg-config, rubygem-mocha
# if we run the tests during build, we need most of Requires here too,
# except for deployment specific stuff
BuildRequires:  rubygem-webyast-rake-tasks, rubygem-restility
BuildRequires:  yast2-core, yast2-dbus-server, ruby-dbus, sqlite, dbus-1
BuildRequires:  PolicyKit, PackageKit, rubygem-sqlite3
BuildRequires:  rubygem-rails-2_3 >= 2.3.4
BuildRequires:  rubygem-rpam, rubygem-polkit
# the testsuite is run during build
BuildRequires:	rubygem-test-unit rubygem-mocha

# This is for Hudson (build service) to setup the build env correctly
%if 0
BuildRequires:  rubygem-test-unit
BuildRequires:  rubygem-rcov >= 0.9.3.2
%endif

# we do not necessarily need any UI in case of WebYaST
Provides:       yast2_ui
Provides:       yast2_ui_pkg

# rpmlint warns about file duplicates, this should take care but
# doesn't build (?!)
#%if 0%{?suse_version} > 1020
#BuildRequires:  fdupes
#%endif

BuildArch:      noarch

%package testsuite
Group:    Productivity/Networking/Web/Utilities
Requires: webyast-base-ws = %{version}
Summary:  Testsuite for webyast-base-ws package

#
%define pkg_home /var/lib/%{webyast_ws_user}
#


%description
WebYaST - Core components for REST based interface to system manipulation.
Authors:
--------
    Duncan Mac-Vicar Prett <dmacvicar@suse.de>
    Klaus Kaempf <kkaempf@suse.de>
    Bjoern Geuken <bgeuken@suse.de>
    Stefan Schubert <schubi@suse.de>

%description testsuite
Testsuite for core WebYaST webservice package.

%prep
%setup -q -n www

%build

%check
# run the testsuite
RAILS_ENV=test rake db:migrate
RAILS_ENV=test $RPM_BUILD_ROOT%{webyast_ws_dir}/test/dbus-launch-simple rake test

#---------------------------------------------------------------
%install

#
# Install all web and frontend parts.
#
mkdir -p $RPM_BUILD_ROOT%{webyast_ws_dir}/log/
cp -a * $RPM_BUILD_ROOT%{webyast_ws_dir}/
rm -f $RPM_BUILD_ROOT%{webyast_ws_dir}/log/*
rm -f $RPM_BUILD_ROOT%{webyast_ws_dir}/COPYING
touch $RPM_BUILD_ROOT%{webyast_ws_dir}/db/schema.rb

%{__install} -d -m 0755                            \
    %{buildroot}%{pkg_home}/sockets/               \
    %{buildroot}%{pkg_home}/cache/                 \
    %{buildroot}%{_sbindir}                        \
    %{buildroot}%{_var}/log/%{webyast_ws_user}
#
# init script
#
%{__install} -D -m 0755 %SOURCE9 \
    %{buildroot}%{_sysconfdir}/init.d/%{webyast_ws_service}
%{__ln_s} -f %{_sysconfdir}/init.d/%{webyast_ws_service} %{buildroot}%{_sbindir}/rc%{webyast_ws_service}
#

# configure lighttpd web service
mkdir -p $RPM_BUILD_ROOT/etc/yastws/
install -m 0644 %SOURCE7 $RPM_BUILD_ROOT/etc/yastws/
install -m 0644 %SOURCE8 $RPM_BUILD_ROOT/etc/yastws/

# Policies
mkdir -p $RPM_BUILD_ROOT/usr/share/PolicyKit/policy
install -m 0644 %SOURCE4 $RPM_BUILD_ROOT/usr/share/PolicyKit/policy/
install -m 0644 %SOURCE6 $RPM_BUILD_ROOT/etc/
install -m 0555 %SOURCE5 $RPM_BUILD_ROOT/usr/sbin/

# firewall service definition, bnc#545627
mkdir -p $RPM_BUILD_ROOT/etc/sysconfig/SuSEfirewall2.d/services
install -m 0644 %SOURCE10 $RPM_BUILD_ROOT/etc/sysconfig/SuSEfirewall2.d/services

# logrotate configuration bnc#634404
mkdir $RPM_BUILD_ROOT/etc/logrotate.d
install -m 0644 %SOURCE11 $RPM_BUILD_ROOT/etc/logrotate.d

#  create yastwsdirs (config, var and data)
mkdir -p $RPM_BUILD_ROOT/etc/webyast
mkdir -p $RPM_BUILD_ROOT/var/lib/yastws
mkdir -p $RPM_BUILD_ROOT/usr/share/yastws

#  create empty tmp directory
mkdir -p $RPM_BUILD_ROOT%{webyast_ws_dir}/tmp
mkdir -p $RPM_BUILD_ROOT%{webyast_ws_dir}/tmp/cache
mkdir -p $RPM_BUILD_ROOT%{webyast_ws_dir}/tmp/pids
mkdir -p $RPM_BUILD_ROOT%{webyast_ws_dir}/tmp/sessions
mkdir -p $RPM_BUILD_ROOT%{webyast_ws_dir}/tmp/sockets

# install permissions service
mkdir -p $RPM_BUILD_ROOT/usr/sbin/
install -m 0500 %SOURCE1 $RPM_BUILD_ROOT/usr/sbin/
mkdir -p $RPM_BUILD_ROOT/etc/dbus-1/system.d/
install -m 0644 %SOURCE2 $RPM_BUILD_ROOT/etc/dbus-1/system.d/
mkdir -p $RPM_BUILD_ROOT/usr/share/dbus-1/system-services/
install -m 0444 %SOURCE3 $RPM_BUILD_ROOT/usr/share/dbus-1/system-services/

#---------------------------------------------------------------
%clean
rm -rf $RPM_BUILD_ROOT

#---------------------------------------------------------------
%pre

#
# e.g. adding user
#
/usr/sbin/groupadd -r %{webyast_ws_user} &>/dev/null ||:
/usr/sbin/useradd  -g %{webyast_ws_user} -s /bin/false -r -c "User for YaST-Webservice" -d %{pkg_home} %{webyast_ws_user} &>/dev/null ||:

# services will not be restarted correctly if
# the package name will changed while the update
# So the service will be restarted by an update-script
# which will be called AFTER the installation
if /bin/rpm -q yast2-webservice > /dev/null ; then
  echo "renaming yast2-webservice to webyast-base-ws"
  if /usr/sbin/rcyastws status > /dev/null ; then
    echo "yastws is running"
    echo "#!/bin/sh" > %name-%version-%release-1
    echo "/usr/sbin/rcyastws restart" >> %name-%version-%release-1
    install -D -m 755 %name-%version-%release-1 /var/adm/update-scripts
    rm %name-%version-%release-1
    echo "Please restart WebYaST service with \"rcyastws restart\" if the update has not been called with zypper,yast or packagekit"
  fi
fi
exit 0

#---------------------------------------------------------------
%post
%fillup_and_insserv %{webyast_ws_service}
#
#granting permissions for yastws
#
if [ `/usr/bin/polkit-auth --user %{webyast_ws_user} | grep -c "org.freedesktop.packagekit.system-update"` -eq 0 ]; then
  # FIXME: remove ||: (don't hide errors), has to be correctly implemented for package update...
  /usr/bin/polkit-auth --user %{webyast_ws_user} --grant org.freedesktop.packagekit.system-update > /dev/null ||:
fi
if [ `/usr/bin/polkit-auth --user %{webyast_ws_user} | grep -c "org.freedesktop.policykit.read"` -eq 0 ]; then
  # FIXME: remove ||: (don't hide errors), has to be correctly implemented for package update...
  /usr/bin/polkit-auth --user %{webyast_ws_user} --grant org.freedesktop.policykit.read > /dev/null ||:
fi
if [ `/usr/bin/polkit-auth --user %{webyast_ws_user} | grep -c "org.opensuse.yast.module-manager.import"` -eq 0 ]; then
  # FIXME: remove ||: (don't hide errors), has to be correctly implemented for package update...
  /usr/bin/polkit-auth --user %{webyast_ws_user} --grant org.opensuse.yast.module-manager.import > /dev/null ||:
fi
#
# granting all permissions for root 
#
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null ||:
#
# create database 
#
cd %{webyast_ws_dir}
#migrate database
RAILS_ENV=production rake db:migrate
chown -R %{webyast_ws_user}: db
chown -R %{webyast_ws_user}: log
echo "Database is ready"
#
# try-reload D-Bus config (bnc#635826)
#
dbus-send --print-reply --system --dest=org.freedesktop.DBus / org.freedesktop.DBus.ReloadConfig >/dev/null ||:

#---------------------------------------------------------------
%preun
%stop_on_removal %{webyast_ws_service}

#---------------------------------------------------------------
%postun
%restart_on_update %{webyast_ws_service}
%{insserv_cleanup}

#---------------------------------------------------------------
# restart yastws on lighttpd update (bnc#559534)
%triggerin -- lighttpd
%restart_on_update %{webyast_ws_service}

#---------------------------------------------------------------
%files 
%defattr(-,root,root)
#this /etc/yastws is for ligght conf for yastws
%dir /etc/yastws
%dir %{webyast_ws_dir}
%dir %{_datadir}/PolicyKit
%dir %{_datadir}/PolicyKit/policy
%attr(-,%{webyast_ws_user},%{webyast_ws_user}) %dir %{pkg_home}
%attr(-,%{webyast_ws_user},%{webyast_ws_user}) %dir %{pkg_home}/sockets
%attr(-,%{webyast_ws_user},%{webyast_ws_user}) %dir %{pkg_home}/cache
%attr(-,%{webyast_ws_user},%{webyast_ws_user}) %dir %{_var}/log/%{webyast_ws_user}

#logrotate configuration file
%config(noreplace) /etc/logrotate.d/webyast-ws.lr.conf

#this /etc/webyast is for webyast configuration files
%dir /etc/webyast/
%dir %{_datadir}/yastws
%dir %attr(-,%{webyast_ws_user},root) /var/lib/yastws
%dir %{webyast_ws_dir}/db
%{webyast_ws_dir}/app
%{webyast_ws_dir}/db/migrate
%ghost %{webyast_ws_dir}/db/schema.rb
%{webyast_ws_dir}/doc
%{webyast_ws_dir}/lib
%{webyast_ws_dir}/public
%{webyast_ws_dir}/Rakefile
%{webyast_ws_dir}/script
%dir %{webyast_ws_dir}/config
%{webyast_ws_dir}/config/boot.rb
%{webyast_ws_dir}/config/database.yml
%{webyast_ws_dir}/config/environments
%{webyast_ws_dir}/config/initializers
%{webyast_ws_dir}/config/routes.rb
#also users can run granting script, as permissions is handled by policyKit right for granting permissions
%attr(555,root,root) /usr/sbin/grantwebyastrights
%attr(755,root,root) %{webyast_ws_dir}/start.sh
%attr(500,root,root) /usr/sbin/webyastPermissionsService.rb
%attr(444,root,root) /usr/share/dbus-1/system-services/webyast.permissions.service.service
%attr(644,root,root) %config /etc/dbus-1/system.d/webyast.permissions.conf
%doc %{webyast_ws_dir}/README
%attr(-,%{webyast_ws_user},%{webyast_ws_user}) %{webyast_ws_dir}/log
%attr(-,%{webyast_ws_user},%{webyast_ws_user}) %{webyast_ws_dir}/tmp
%config(noreplace) /etc/yastws/lighttpd.conf
%config /etc/yastws/modules.conf
%config /etc/sysconfig/SuSEfirewall2.d/services/webyast
%config /usr/share/PolicyKit/policy/org.opensuse.yast.permissions.policy
%config %{webyast_ws_dir}/config/environment.rb
%config(noreplace) /etc/yast_user_roles
%config(noreplace)  %{_sysconfdir}/init.d/%{webyast_ws_service}
%{_sbindir}/rc%{webyast_ws_service}
%doc COPYING

%files testsuite
%defattr(-,root,root)
%{webyast_ws_dir}/test
%ghost %attr(755,root,root) /var/adm/update-scripts/%name-%version-%release-1

#---------------------------------------------------------------
%changelog
