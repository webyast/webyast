#
# spec file for package yast2-webservice (Version 0.1)
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-webservice

%if 0%{?suse_version} == 0 || %suse_version > 1110
# 11.2 or newer
Requires:       yast2-core >= 2.18.10
# Require startproc respecting -p, bnc#559534#c44
Requires:       sysvinit > 2.86-215.2
# Require lighttpd whose postun does not mass kill, bnc#559534#c19
# (Updating it later does not work because postun uses the old version.)
PreReq:         lighttpd > 1.4.20-3.6
%else
# 11.1 or SLES11
Requires:       yast2-core >= 2.17.30.1
Requires:       sysvinit > 2.86-195.3.1
PreReq:         lighttpd > 1.4.20-2.29.1
%endif

Requires:	lighttpd-mod_magnet, ruby-fcgi, ruby-dbus, sqlite
Requires:       rubygem-yast2-webservice-tasks
Requires:	yast2-dbus-server
# gamin gives problems with lighttpd, so better conflict with it for now
Conflicts:      gamin
PreReq:         PolicyKit, PackageKit, rubygem-rake, rubygem-sqlite3
PreReq:         rubygem-rails-2_3 >= 2.3.4
PreReq:         ruby-rpam, ruby-polkit, rubygem-test-unit
License:	LGPL v2.1 only
Group:          Productivity/Networking/Web/Utilities
Autoreqprov:    on
Version:        0.0.19
Release:        0
Summary:        YaST2 - Webservice 
Source:         www.tar.bz2
Source1:        yast.conf
Source2:        rails.include
Source3:        cleanurl-v5.lua
Source4:        org.opensuse.yast.permissions.policy
Source5:        grantwebyastrights
Source6:        yast_user_roles
Source7:        lighttpd.conf
Source8:        modules.conf
Source9:        yastws
Source10:       webyast
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  ruby, pkg-config, rubygem-mocha
# if we run the tests during build, we need most of Requires here too,
# except for deployment specific stuff
BuildRequires:  rubygem-yast2-webservice-tasks, rubygem-restility
BuildRequires:  yast2-core, yast2-dbus-server, ruby-dbus, sqlite, dbus-1
BuildRequires:  PolicyKit, PackageKit, rubygem-sqlite3
BuildRequires:  rubygem-rails-2_3 >= 2.3.4
BuildRequires:  ruby-rpam, ruby-polkit

# This is for Hudson (build service) to setup the build env correctly
%if 0
BuildRequires:  rubygem-test-unit
BuildRequires:  rubygem-rcov >= 0.9.3.2
%endif

# rpmlint warns about file duplicates, this should take care but
# doesn't build (?!)
#%if 0%{?suse_version} > 1020
#BuildRequires:  fdupes
#%endif

BuildArch:      noarch

#
%define pkg_user yastws
%define pkg_home /var/lib/%{pkg_user}
#


%description
YaST2 - Webservice - REST based interface of YaST.
Authors:
--------
    Duncan Mac-Vicar Prett <dmacvicar@suse.de>
    Klaus Kaempf <kkaempf@suse.de>
    Bjoern Geuken <bgeuken@suse.de>
    Stefan Schubert <schubi@suse.de>

%prep
%setup -q -n www

%build

#---------------------------------------------------------------
%install

#
# Install all web and frontend parts.
#
mkdir -p $RPM_BUILD_ROOT/srv/www/%{pkg_user}/log/
cp -a * $RPM_BUILD_ROOT/srv/www/%{pkg_user}/
rm -f $RPM_BUILD_ROOT/srv/www/%{pkg_user}/log/*
rm -f $RPM_BUILD_ROOT/srv/www/%{pkg_user}/COPYING
touch $RPM_BUILD_ROOT/srv/www/%{pkg_user}/db/schema.rb

%{__install} -d -m 0755                            \
    %{buildroot}%{pkg_home}/sockets/               \
    %{buildroot}%{pkg_home}/cache/                 \
    %{buildroot}%{_sbindir}                        \
    %{buildroot}%{_var}/log/%{pkg_user}
#
# init script
#
%{__install} -D -m 0755 %SOURCE9 \
    %{buildroot}%{_sysconfdir}/init.d/%{pkg_user}
%{__ln_s} -f %{_sysconfdir}/init.d/%{pkg_user} %{buildroot}%{_sbindir}/rc%{pkg_user}
#

# configure lighttpd web service
mkdir -p $RPM_BUILD_ROOT/etc/yastws/vhosts.d/
install -m 0644 %SOURCE1 $RPM_BUILD_ROOT/etc/yastws/vhosts.d/
install -m 0644 %SOURCE2 $RPM_BUILD_ROOT/etc/yastws/vhosts.d/rails.inc
install -m 0644 %SOURCE3 $RPM_BUILD_ROOT/etc/yastws/
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

#  create yastwsdirs (config, var and data)
mkdir -p $RPM_BUILD_ROOT/etc/webyast
mkdir -p $RPM_BUILD_ROOT/var/lib/yastws
mkdir -p $RPM_BUILD_ROOT/usr/share/yastws

#  create empty tmp directory
mkdir -p $RPM_BUILD_ROOT/srv/www/%{pkg_user}/tmp
mkdir -p $RPM_BUILD_ROOT/srv/www/%{pkg_user}/tmp/cache
mkdir -p $RPM_BUILD_ROOT/srv/www/%{pkg_user}/tmp/pids
mkdir -p $RPM_BUILD_ROOT/srv/www/%{pkg_user}/tmp/sessions
mkdir -p $RPM_BUILD_ROOT/srv/www/%{pkg_user}/tmp/sockets


#---------------------------------------------------------------
%clean
rm -rf $RPM_BUILD_ROOT

#---------------------------------------------------------------
%pre
#
# e.g. adding user
#
/usr/sbin/groupadd -r %{pkg_user} &>/dev/null ||:
/usr/sbin/useradd  -g %{pkg_user} -s /bin/false -r -c "User for YaST-Webservice" -d %{pkg_home} %{pkg_user} &>/dev/null ||:

#---------------------------------------------------------------
%post
%fillup_and_insserv %{pkg_user}
#
#granting permissions for yastws
#
if [ `/usr/bin/polkit-auth --user yastws | grep -c "org.freedesktop.packagekit.system-update"` -eq 0 ]; then
  /usr/bin/polkit-auth --user yastws --grant org.freedesktop.packagekit.system-update > /dev/null
fi
if [ `/usr/bin/polkit-auth --user yastws | grep -c "org.freedesktop.policykit.read"` -eq 0 ]; then
  /usr/bin/polkit-auth --user yastws --grant org.freedesktop.policykit.read > /dev/null
fi
if [ `/usr/bin/polkit-auth --user yastws | grep -c "org.opensuse.yast.module-manager.import"` -eq 0 ]; then
  /usr/bin/polkit-auth --user yastws --grant org.opensuse.yast.module-manager.import > /dev/null
fi
#
# granting all permissions for root 
#
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null
#
# create database 
#
cd srv/www/%{pkg_user}
#generate install specific secret key
sed -i 's/9d11bfc98abcf9799082d9c34ec94dc1cc926f0f1bf4bea8c440b497d96b14c1f712c8784d0303ee7dd69e382c3e5e4d38d4c56d1b619eae7acaa6516cd733b1/'`rake -s secret`/ config/environment.rb
#migrate database
RAILS_ENV=production rake db:migrate
chown -R yastws: db
chown -R yastws: log
echo "Database is ready"

#---------------------------------------------------------------
%preun
%stop_on_removal %{pkg_user}

#---------------------------------------------------------------
%postun
%restart_on_update %{pkg_user}
%{insserv_cleanup}

#---------------------------------------------------------------
# restart yastws on lighttpd update (bnc#559534)
%triggerin -- lighttpd
%restart_on_update %{pkg_user}

#---------------------------------------------------------------
%files 
%defattr(-,root,root)
#this /etc/yastws is for ligght conf for yastws
%dir /etc/yastws
%dir /srv/www/yastws
%dir /etc/yastws/vhosts.d
%dir %{_datadir}/PolicyKit
%dir %{_datadir}/PolicyKit/policy
%attr(-,%{pkg_user},%{pkg_user}) %dir %{pkg_home}
%attr(-,%{pkg_user},%{pkg_user}) %dir %{pkg_home}/sockets
%attr(-,%{pkg_user},%{pkg_user}) %dir %{pkg_home}/cache
%attr(-,%{pkg_user},%{pkg_user}) %dir %{_var}/log/%{pkg_user}

#this /etc/webyast is for webyast configuration files
%dir /etc/webyast/
%dir %{_datadir}/yastws
%dir %attr(-,%{pkg_user},root) /var/lib/yastws
%dir /srv/www/yastws/db
%dir /srv/www/yastws/db
/srv/www/yastws/app
%dir /srv/www/yastws/db
/srv/www/yastws/db/migrate
%ghost /srv/www/yastws/db/schema.rb
/srv/www/yastws/doc
/srv/www/yastws/lib
/srv/www/yastws/public
/srv/www/yastws/Rakefile
/srv/www/yastws/script
#/srv/www/yastws/test
%dir /srv/www/yastws/config
/srv/www/yastws/config/boot.rb
/srv/www/yastws/config/database.yml
/srv/www/yastws/config/environments
/srv/www/yastws/config/initializers
/srv/www/yastws/config/routes.rb
/srv/www/yastws/start.sh
#also users can run granting script, as permissions is handled by policyKit right for granting permissions
%attr(555,root,root) %config /usr/sbin/grantwebyastrights
%attr(755,root,root) /srv/www/yastws/start.sh
%doc /srv/www/yastws/README
%attr(-,%{pkg_user},%{pkg_user}) /srv/www/yastws/log
%attr(-,%{pkg_user},%{pkg_user}) /srv/www/yastws/tmp
%config(noreplace) /etc/yastws/vhosts.d/yast.conf
%config(noreplace) /etc/yastws/lighttpd.conf
%config /etc/yastws/vhosts.d/rails.inc
%config /etc/yastws/cleanurl-v5.lua
%config /etc/yastws/modules.conf
%config /etc/sysconfig/SuSEfirewall2.d/services/webyast
%config /usr/share/PolicyKit/policy/org.opensuse.yast.permissions.policy
%config /srv/www/yastws/config/environment.rb
%config(noreplace) /etc/yast_user_roles
%config(noreplace)  %{_sysconfdir}/init.d/%{pkg_user}
%{_sbindir}/rc%{pkg_user}
%doc COPYING

#---------------------------------------------------------------
%changelog
