#
# spec file for package webyast-base
#
# Copyright (c) 2013 SUSE LINUX Products GmbH, Nuernberg, Germany.
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


Name:           webyast-base
Version:        0.3.44
Release:        0
Provides:       yast2-webservice = %{version}
Obsoletes:      yast2-webservice < %{version}
Provides:       webyast-language-ws = 0.1.0
Obsoletes:      webyast-language-ws <= 0.1.0

Obsoletes:      webyast-base-ui < %{version}
Obsoletes:      webyast-base-ws < %{version}
Obsoletes:      webyast-firstboot-ws < %{version}
Obsoletes:      yast2-webclient < %{version}
Obsoletes:      yast2-webservice < %{version}
Provides:       webyast-base-ui = %{version}
Provides:       webyast-base-ws = %{version}
Provides:       webyast-firstboot-ws = %{version}
Provides:       yast2-webclient = %{version}
Provides:       yast2-webservice = %{version}

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
%else
# 11.1 or SLES11
Requires:       sysvinit > 2.86-195.3.1
Requires:       yast2-core >= 2.17.30.1
%endif
%if 0%{?suse_version} == 1220
Requires:       rubygem-passenger-nginx >= 3.0.12
%else
Requires:       rubygem-passenger-nginx >= 3.0.14
%endif
Requires:       check-create-certificate
Requires:       nginx >= 1.0.15
Requires:       rubygem-ruby-dbus
Requires:       syslog
Requires:       yast2-dbus-server

Requires:       rubygem-webyast-rake-tasks >= 0.3.5
Requires:       webyast-base-branding
PreReq:         rubygem-bundler
# 634404
Recommends:     logrotate
%if 0%{?suse_version} == 0 || %suse_version > 1110
PreReq:         polkit, rubygem-polkit1
PreReq:         rubygem-rake
%else
# <11.1 or SLES11
PreReq:         PolicyKit, rubygem-polkit
PreReq:         rubygem-rake < 0.9
%endif
PreReq:         rubygem-sqlite3 >= 1.3.6
PreReq:         rubygem-rails-3_2 >= 3.2.3
PreReq:         rubygem-fast_gettext, rubygem-gettext_i18n_rails

# conflict with all old Webyast-1.2 plugins (to force upgrade)
Conflicts:      webyast-activedirectory-ui < 0.3.0
Conflicts:      webyast-firewall-ui < 0.3.0
Conflicts:      webyast-ldap-ui < 0.3.0
Conflicts:      webyast-licenses-ui < 0.3.0
Conflicts:      webyast-mail-ui < 0.3.0
Conflicts:      webyast-network-ui < 0.3.0
Conflicts:      webyast-reboot-ui < 0.3.0
Conflicts:      webyast-registration-ui < 0.3.0
Conflicts:      webyast-roles-ui < 0.3.0
Conflicts:      webyast-root-user-ui < 0.3.0
Conflicts:      webyast-services-ui < 0.3.0
Conflicts:      webyast-slms-ui < 0.3.0
Conflicts:      webyast-software-ui <= 0.3.20
Conflicts:      webyast-status-ui < 0.3.0
Conflicts:      webyast-time-ui < 0.3.0
Conflicts:      webyast-users-ui < 0.3.0

Conflicts:      webyast-activedirectory-ws < 0.3.0
Conflicts:      webyast-firewall-ws < 0.3.0
Conflicts:      webyast-firstboot-ws < 0.3.0
Conflicts:      webyast-kerberos-ws < 0.3.0
Conflicts:      webyast-ldap-ws < 0.3.0
Conflicts:      webyast-licenses-ws < 0.3.0
Conflicts:      webyast-mail-ws < 0.3.0
Conflicts:      webyast-network-ws < 0.3.0
Conflicts:      webyast-ntp-ws < 0.3.0
Conflicts:      webyast-reboot-ws < 0.3.0
Conflicts:      webyast-registration-ws < 0.3.0
Conflicts:      webyast-roles-ws < 0.3.0
Conflicts:      webyast-root-user-ws < 0.3.0
Conflicts:      webyast-services-ws < 0.3.0
Conflicts:      webyast-slms-ws < 0.3.0
Conflicts:      webyast-software-ws <= 0.3.20
Conflicts:      webyast-status-ws < 0.3.0
Conflicts:      webyast-time-ws < 0.3.0
Conflicts:      webyast-users-ws < 0.3.0

Url:            http://en.opensuse.org/Portal:WebYaST
Summary:        WebYaST - base components
License:        LGPL-2.1 and GPL-2.0 and Apache-2.0
Group:          Productivity/Networking/Web/Utilities
Source:         www.tar.bz2
Source1:        webyastPermissionsService.rb
Source2:        webyast.permissions.conf
Source3:        webyast.permissions.service.service
Source4:        org.opensuse.yast.permissions.policy
Source5:        grantwebyastrights
Source6:        yast_user_roles
Source9:        rcwebyast
Source10:       webyast
Source11:       webyast.lr.conf
Source12:       nginx.conf
Source13:       control_panel.yml
Source14:       config.yml
Source15:       config.yml.new
Source16:       update_webyast_service
Source17:       50-default-webyast-base.rules

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  pkg-config
BuildRequires:  ruby
BuildRequires:  rubygem-mocha
# if we run the tests during build, we need most of Requires here too,
# except for deployment specific stuff
BuildRequires:  dbus-1
BuildRequires:  rubygem-rails-3_2
BuildRequires:  rubygem-ruby-dbus
BuildRequires:  rubygem-sqlite3 >= 1.3.6
BuildRequires:  rubygem-webyast-rake-tasks >= 0.3.5
%if 0%{?suse_version} == 0 || %suse_version > 1110
BuildRequires:  polkit
BuildRequires:  rubygem-polkit1
%else
# <11.1 or SLES11
BuildRequires:  PolicyKit
BuildRequires:  rubygem-polkit
%endif
%if 0%{?suse_version} > 1220
BuildRequires:  polkit-default-privs
%endif
# the testsuite is run during build
BuildRequires:  nginx >= 1.0
BuildRequires:  rubygem-builder-3_0
BuildRequires:  rubygem-bundler
BuildRequires:  rubygem-cancan
BuildRequires:  rubygem-devise
BuildRequires:  rubygem-devise-i18n
BuildRequires:  rubygem-devise_unix2_chkpwd_authenticatable
BuildRequires:  rubygem-haml
BuildRequires:  rubygem-mocha
BuildRequires:  rubygem-test-unit

BuildRequires:  rubygem-gettext

BuildRequires:  rubygem-factory_girl
BuildRequires:  rubygem-factory_girl_rails
BuildRequires:  rubygem-mocha

Requires:       rubygem-builder-3_0
Requires:       rubygem-fast_gettext
Requires:       rubygem-gettext_i18n_rails
Requires:       rubygem-haml
Requires:       rubygem-rails-i18n
Requires:       rubygem-sqlite3

Requires:       rubygem-cancan
Requires:       rubygem-devise
Requires:       rubygem-devise-i18n
Requires:       rubygem-devise_unix2_chkpwd_authenticatable

# This is for Hudson (build service) to setup the build env correctly
%if 0
BuildRequires:  rubygem-rcov >= 0.9.3.2
BuildRequires:  rubygem-test-unit
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
Requires:       webyast-base = %{version}
Summary:        Testsuite for webyast-base package
Group:          Productivity/Networking/Web/Utilities

#
%define pkg_home /var/lib/%{webyast_user}
#

Requires:       rubygem-factory_girl
Requires:       rubygem-factory_girl_rails
Requires:       rubygem-mocha
Requires:       tidy

%description
WebYaST - Core components for UI and REST based interface to system manipulation.
Authors:
--------
    Duncan Mac-Vicar Prett <dmacvicar@suse.de>
    Klaus Kaempf <kkaempf@suse.de>
    Bjoern Geuken <bgeuken@suse.de>
    Stefan Schubert <schubi@suse.de>

%description testsuite
Testsuite for core WebYaST package.

%package branding-default
Provides:       webyast-base-branding = %{version}
PreReq:         %{name} = %{version}
Conflicts:      otherproviders(webyast-base-branding)
Supplements:    packageand(webyast-base:branding-default)

Provides:       webyast-base-ui-branding-default = %{version}
Obsoletes:      webyast-base-ui-branding-default < %{version}

Summary:        Branding package for webyast-base package
Group:          Productivity/Networking/Web/Utilities

%description branding-default
This package contains css, icons and images for webyast-base package.


%prep
%setup -q -n www

%build
%if %suse_version <= 1110
export WEBYAST_POLICYKIT='true'
%endif
# build *.mo files (redirect sterr to /dev/null as it contains tons of warnings about obsoleted (commented) msgids)
# if the task fails run it again and show the details of the failure for debugging
LANG=en rake gettext:pack 2> /dev/null || LANG=en rake -t gettext:pack
# gettext:pack for some reason creates empty db/development.sqlite3 file
rm -rf db/development.sqlite3

# precompile assets
rake assets:precompile

# split manifest file
rake assets:split_manifest
rm -rf public/assets/manifest.yml

# cleanup
rm -rf tmp
rm -rf log

# remove Gemfile.lock created by the above rake calls
rm Gemfile.lock

%check

%if %suse_version <= 1110
export WEBYAST_POLICYKIT='true'
%endif
# run the testsuite
RAILS_ENV=test rake db:migrate
rake tmp:create
RAILS_ENV=test $RPM_BUILD_ROOT%{webyast_dir}/test/dbus-launch-simple rake test

#---------------------------------------------------------------
%install

%if %suse_version <= 1110
export WEBYAST_POLICYKIT='true'
%endif

#
# Install all web and frontend parts.
#
mkdir -p $RPM_BUILD_ROOT%{webyast_dir}
cp -a * $RPM_BUILD_ROOT%{webyast_dir}/
rm -f $RPM_BUILD_ROOT%{webyast_dir}/log
rm -rf $RPM_BUILD_ROOT/%{webyast_dir}/po
rm -f $RPM_BUILD_ROOT%{webyast_dir}/COPYING

# install production mode Gemfile
rake -s gemfile:production > $RPM_BUILD_ROOT%{webyast_dir}/Gemfile
# install test mode Gemfile
rake -s gemfile:test > $RPM_BUILD_ROOT%{webyast_dir}/Gemfile.test
# install assets mode Gemfile
rake -s gemfile:assets > $RPM_BUILD_ROOT%{webyast_dir}/Gemfile.assets

# remove .gitkeep files
find $RPM_BUILD_ROOT%{webyast_dir} -name .gitkeep -delete

# remove *.po files (compiled *.mo files are sufficient)
find $RPM_BUILD_ROOT%{webyast_dir}/locale -name '*.po' -delete

%{__install} -d -m 0755                            \
    %{buildroot}%{pkg_home}/sockets/               \
    %{buildroot}%{pkg_home}/cache/                 \
    %{buildroot}%{_sbindir}                        \
    %{buildroot}%{_var}/log/%{webyast_user}
#
# init script
#
%{__install} -D -m 0755 -T %SOURCE9 \
    %{buildroot}%{_sysconfdir}/init.d/%{webyast_service}
%{__ln_s} -f %{_sysconfdir}/init.d/%{webyast_service} %{buildroot}%{_sbindir}/rc%{webyast_service}
#

# configure nginx web service
mkdir -p $RPM_BUILD_ROOT/etc/nginx/certs

# configure nginx web service
mkdir -p $RPM_BUILD_ROOT/etc/webyast/
install -m 0644 %SOURCE12 $RPM_BUILD_ROOT/etc/webyast/
# create symlinks to nginx config files
ln -s /etc/nginx/fastcgi.conf $RPM_BUILD_ROOT/etc/webyast
ln -s /etc/nginx/fastcgi_params $RPM_BUILD_ROOT/etc/webyast
ln -s /etc/nginx/koi-utf $RPM_BUILD_ROOT/etc/webyast
ln -s /etc/nginx/koi-win $RPM_BUILD_ROOT/etc/webyast
ln -s /etc/nginx/mime.types $RPM_BUILD_ROOT/etc/webyast
ln -s /etc/nginx/scgi_params $RPM_BUILD_ROOT/etc/webyast
ln -s /etc/nginx/uwsgi_params $RPM_BUILD_ROOT/etc/webyast
ln -s /etc/nginx/win-utf $RPM_BUILD_ROOT/etc/webyast

# Policies
mkdir -p $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}
install -m 0644 %SOURCE4 $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}
install -m 0644 %SOURCE6 $RPM_BUILD_ROOT/etc/
install -m 0555 %SOURCE5 $RPM_BUILD_ROOT/usr/sbin/
%if %suse_version >= 1230
install -m 0644 %SOURCE17 $RPM_BUILD_ROOT/etc/polkit-1/rules.d/
%endif

# firewall service definition, bnc#545627
mkdir -p $RPM_BUILD_ROOT/etc/sysconfig/SuSEfirewall2.d/services
install -m 0644 %SOURCE10 $RPM_BUILD_ROOT/etc/sysconfig/SuSEfirewall2.d/services

# logrotate configuration bnc#634404
mkdir $RPM_BUILD_ROOT/etc/logrotate.d
install -m 0644 %SOURCE11 $RPM_BUILD_ROOT/etc/logrotate.d

#  create webyast dirs (config, var and data)
mkdir -p $RPM_BUILD_ROOT/etc/webyast
mkdir -p $RPM_BUILD_ROOT/var/lib/webyast
mkdir -p $RPM_BUILD_ROOT/usr/share/webyast

#  create empty tmp directory
mkdir -p $RPM_BUILD_ROOT%{webyast_dir}/tmp
mkdir -p $RPM_BUILD_ROOT%{webyast_dir}/tmp/cache
mkdir -p $RPM_BUILD_ROOT%{webyast_dir}/tmp/pids
mkdir -p $RPM_BUILD_ROOT%{webyast_dir}/tmp/sessions
mkdir -p $RPM_BUILD_ROOT%{webyast_dir}/tmp/sockets

# install YAML config file
mkdir -p $RPM_BUILD_ROOT/etc/webyast/
cp %SOURCE13 $RPM_BUILD_ROOT/etc/webyast/

%if %suse_version <= 1110
cp %SOURCE14 $RPM_BUILD_ROOT/etc/webyast/
%else
cp %SOURCE15 $RPM_BUILD_ROOT/etc/webyast/config.yml
%endif

# install permissions service
mkdir -p $RPM_BUILD_ROOT/usr/sbin/
install -m 0500 %SOURCE1 $RPM_BUILD_ROOT/usr/sbin/
mkdir -p $RPM_BUILD_ROOT/etc/dbus-1/system.d/
install -m 0644 %SOURCE2 $RPM_BUILD_ROOT/etc/dbus-1/system.d/
mkdir -p $RPM_BUILD_ROOT/usr/share/dbus-1/system-services/
install -m 0444 %SOURCE3 $RPM_BUILD_ROOT/usr/share/dbus-1/system-services/

#create dummy update-script
mkdir -p %buildroot/var/adm/update-scripts
touch %buildroot/var/adm/update-scripts/%name-%version-%release-1

# for basesystem setup (firstboot)
mkdir -p $RPM_BUILD_ROOT%{webyast_vardir}/basesystem

# install restart script
install -m 0755 %SOURCE16 $RPM_BUILD_ROOT/usr/sbin/

# restart Webyast at the end of the transaction
%create_restart_script

# create restart script for *-branding subpackage
ln -s /usr/sbin/update_webyast_service $RPM_BUILD_ROOT/var/adm/update-scripts/webyast-base-branding-default-%version-%release-update

#---------------------------------------------------------------
%clean
rm -rf $RPM_BUILD_ROOT

#---------------------------------------------------------------
%pre

#
# e.g. adding user
#
/usr/sbin/groupadd -r %{webyast_user} &>/dev/null ||:
/usr/sbin/useradd  -g %{webyast_user} -s /bin/false -r -c "User for WebYaST" -d %{pkg_home} %{webyast_user} &>/dev/null ||:

# services will not be restarted correctly if
# the package name will changed while the update
# So the service will be restarted by an update-script
# which will be called AFTER the installation
if /bin/rpm -q webyast-base-ui > /dev/null ; then
  echo "renaming webyast-base-ui to webyast-base"
  if /sbin/chkconfig -l yastwc 2> /dev/null | grep " 3:on " >/dev/null ; then
    echo "webyast is inserted into the runlevel"
    echo "#!/bin/sh" > %name-%version-%release-1
    echo "/sbin/chkconfig -a webyast" >> %name-%version-%release-1
    echo "/usr/sbin/rcwebyast restart" >> %name-%version-%release-1
  else
    if /usr/sbin/rcyastwc status > /dev/null ; then
      echo "webyast is running"
      echo "#!/bin/sh" > %name-%version-%release-1
      echo "/usr/sbin/rcwebyast restart" >> %name-%version-%release-1
    fi
  fi

  # move the current SSL certificates to the new location
  if [ -f /etc/lighttpd/certs/webyast.pem ]; then
    mkdir -p /etc/nginx/certs
    mv /etc/lighttpd/certs/webyast* /etc/nginx/certs
  fi
fi
#We are switching from lighttpd to nginx. So lighttpd has to be killed
#at first
if rpm -q --requires %{name}|grep lighttpd > /dev/null ; then
  if /usr/sbin/rcyastws status > /dev/null ; then
    echo "yastws is running under lighttpd -> switching to nginx"
    /usr/sbin/rcyastws stop > /dev/null

    # check if the restart file already exists
    if [ ! -f %name-%version-%release-1 ] ; then
      echo "#!/bin/sh" > %name-%version-%release-1
      echo "/usr/sbin/rcwebyast restart" >> %name-%version-%release-1
    fi
  fi
fi
if [ -f %name-%version-%release-1 ] ; then
  install -D -m 755 %name-%version-%release-1 /var/adm/update-scripts
  rm %name-%version-%release-1
  echo "Please check the service runlevels and restart WebYaST service with \"rcwebyast restart\" if the update has not been called with zypper,yast or packagekit"
fi
exit 0

#---------------------------------------------------------------
%post
%fillup_and_insserv %{webyast_service}

%if %suse_version < 1230
#
#granting permissions for webyast
#
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant --policy org.opensuse.yast.module-manager.import > /dev/null ||:

#
# granting all permissions for root
#
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null ||:
%endif

#
# create database
#
cd %{webyast_dir}

# force refreshing the Gemfile.lock
rm -f Gemfile.lock

#migrate database
%if %suse_version <= 1110
export WEBYAST_POLICYKIT='true'
%endif
(umask 0077; RAILS_ENV=production rake db:migrate)
chown %{webyast_user}: db/*.sqlite3
chmod o-r db/production.sqlite3
chown -R %{webyast_user}: /var/log/webyast
chmod -R o-r /var/log/webyast
echo "Database is ready"

# try-reload D-Bus config (bnc#635826)
# check if the system bus socket is present to avoid errors/hangs during RPM build (bnc#767066)
if [ -S /var/run/dbus/system_bus_socket ]; then
  echo "Reloading DBus configuration..."
  dbus-send --print-reply --system --dest=org.freedesktop.DBus / org.freedesktop.DBus.ReloadConfig >/dev/null ||:
fi

# update firewall config
if [ -f /etc/sysconfig/SuSEfirewall2 ]; then
  if grep -q webyast-ui /etc/sysconfig/SuSEfirewall2; then
    echo "Updating firewall config..."
    sed -i "s/\(^[ \t]*FW_CONFIGURATIONS_.*[ \t]*=[ \t]*\".*[ \t]*\)webyast-ui\(.*$\)/\1webyast\2/" /etc/sysconfig/SuSEfirewall2

    # reload the changes
    echo "Restarting firewall..."
    /sbin/rcSuSEfirewall2 try-restart
  fi
fi

# move the base system status to avoid running it after update
if [ -f /var/lib/yastws/basesystem/finish ]; then
    mv /var/lib/yastws/basesystem/finish /var/lib/webyast/basesystem/
fi

%restart_webyast

#---------------------------------------------------------------
%preun
%stop_on_removal %{webyast_service}

#---------------------------------------------------------------
%postun
%restart_on_update %{webyast_service}
%{insserv_cleanup}

#---------------------------------------------------------------
# restart webyast on nginx update (bnc#559534)
%triggerin -- nginx
%restart_on_update %{webyast_service}

%post branding-default
# make sure the directory exists
mkdir -p /var/lib/webyast
%restart_webyast

%postun branding-default
%webyast_update_assets

#---------------------------------------------------------------
%files
%defattr(-,root,root)
#this /etc/webyast is for nginx conf for webyast
%dir /etc/webyast
%dir %{webyast_dir}
%attr(-,root,root) %{_datadir}/%{webyast_polkit_dir}
%attr(-,%{webyast_user},%{webyast_user}) %dir %{pkg_home}
%attr(-,%{webyast_user},%{webyast_user}) %dir %{pkg_home}/sockets
%attr(-,%{webyast_user},%{webyast_user}) %dir %{pkg_home}/cache
%attr(-,%{webyast_user},%{webyast_user}) %dir %{_var}/log/%{webyast_user}

# include the restart script
%restart_script_name
%attr(755,root,root) /usr/sbin/update_webyast_service

#logrotate configuration file
%config(noreplace) /etc/logrotate.d/webyast.lr.conf

%dir %{_datadir}/webyast
%dir %attr(-,root,root) /var/lib/webyast
%attr(-,%{webyast_user},%{webyast_user}) %dir %{webyast_dir}/db
%{webyast_dir}/locale
%{webyast_dir}/app
%{webyast_dir}/db/migrate
%ghost %{webyast_dir}/db/schema.rb
%{webyast_dir}/doc
%{webyast_dir}/lib
%dir %{webyast_dir}/public
%{webyast_dir}/public/*.html
%{webyast_dir}/public/dispatch.*
%{webyast_dir}/public/apache.htaccess
%{webyast_dir}/public/favicon.ico
%{webyast_dir}/Gemfile
%{webyast_dir}/Gemfile.assets
%{webyast_dir}/Rakefile
%{webyast_dir}/config.ru
%{webyast_dir}/script
%dir %{webyast_dir}/config
%{webyast_dir}/config/boot.rb
%{webyast_dir}/config/database.yml
%{webyast_dir}/config/environments
%{webyast_dir}/config/initializers
%{webyast_dir}/config/routes.rb
%{webyast_dir}/config/application.rb
#also users can run granting script, as permissions is handled by polkit right for granting permissions
%attr(555,root,root) /usr/sbin/grantwebyastrights
%attr(755,root,root) %{webyast_dir}/start.sh
%attr(500,root,root) /usr/sbin/webyastPermissionsService.rb
%attr(444,root,root) /usr/share/dbus-1/system-services/webyast.permissions.service.service
%attr(644,root,root) %config /etc/dbus-1/system.d/webyast.permissions.conf
%doc %{webyast_dir}/README
%attr(-,%{webyast_user},%{webyast_user}) %{webyast_dir}/tmp
%dir %{webyast_vardir}
%attr(-,%{webyast_user},%{webyast_user}) %dir %{webyast_vardir}/basesystem

%dir /etc/nginx/certs
#this /etc/webyast is for webyast configuration files
%dir /etc/webyast/
%config /etc/webyast/control_panel.yml
%config /etc/webyast/config.yml
#nginx stuff
%config /etc/webyast/nginx.conf
%config /etc/webyast/fastcgi.conf
%config /etc/webyast/fastcgi_params
%config /etc/webyast/koi-utf
%config /etc/webyast/koi-win
%config /etc/webyast/mime.types
%config /etc/webyast/scgi_params
%config /etc/webyast/uwsgi_params
%config /etc/webyast/win-utf

%config /etc/sysconfig/SuSEfirewall2.d/services/webyast
%config /usr/share/%{webyast_polkit_dir}/org.opensuse.yast.permissions.policy
%config %{webyast_dir}/config/initializers/secret_token.rb
%config %{webyast_dir}/config/environment.rb
%config(noreplace) /etc/yast_user_roles
%config %{_sysconfdir}/init.d/%{webyast_service}
%{_sbindir}/rc%{webyast_service}
%doc COPYING

### include JS assets
%exclude %{webyast_dir}/app/assets/icons
%exclude %{webyast_dir}/app/assets/images
%exclude %{webyast_dir}/app/assets/stylesheets
%{webyast_dir}/app/assets/javascripts
%{webyast_dir}/public/assets/*.js
%{webyast_dir}/public/assets/*.js.gz
%{webyast_dir}/public/assets/manifest.yml.base

%exclude %{webyast_dir}/test

%ghost %attr(755,root,root) /var/adm/update-scripts/%name-%version-%release-1

%files testsuite
%defattr(-,root,root)
%{webyast_dir}/test
%{webyast_dir}/Gemfile.test

%files branding-default
%defattr(-,root,root)
### include css, icons and images 
%{webyast_dir}/app/assets
%{webyast_dir}/public/assets
# exclude files belonging to the base
%exclude %{webyast_dir}/app/assets/javascripts/*
%exclude %{webyast_dir}/public/assets/*.js
%exclude %{webyast_dir}/public/assets/*.js.gz
%exclude %{webyast_dir}/public/assets/manifest.yml.base
# restart script
/var/adm/update-scripts/webyast-base-branding-default-%version-%release-update

#---------------------------------------------------------------

%changelog
