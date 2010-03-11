#
# spec file for package webyast-ntp-ws
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           webyast-ntp-ws
Provides:       yast2-webservice-ntp = %{version}
Obsoletes:      yast2-webservice-ntp < %{version}
#webservice already require yast2-dbus-server which is needed for yapi
PreReq:         yast2-webservice
#for YaPI needs ntp
Requires:	ntp
#for YaPI hwclock
Requires:	util-linux
License:	GPL v2 only
Group:          Productivity/Networking/Web/Utilities
Autoreqprov:    on
Version:        0.1.2
Release:        0
Summary:        YaST2 - Webservice - NTP
Source:         www.tar.bz2
Source1:        NTP.pm
Source2:        org.opensuse.yast.modules.yapi.ntp.policy
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
BuildRequires:  rubygem-yast2-webservice-tasks rubygem-restility

#
%define pkg_user yastws
%define plugin_name ntp
#


%description
YaST2 - Webservice - REST based interface for basic ntp access

Authors:
--------
    Josef Reidinger <jreidinger@novell.com>

%prep
%setup -q -n www

%build
# build restdoc documentation
mkdir -p public/ntp/restdoc
export RAILS_PARENT=/srv/www/yastws
env LANG=en rake restdoc

# do not package restdoc sources
rm -rf restdoc
#do not package development documentation
rm -rf doc

%install

#
# Install all web and frontend parts.
#
mkdir -p $RPM_BUILD_ROOT/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
cp -a * $RPM_BUILD_ROOT/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
rm -f $RPM_BUILD_ROOT/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/COPYING
mkdir -p $RPM_BUILD_ROOT/usr/share/YaST2/modules/YaPI/
cp %{SOURCE1} $RPM_BUILD_ROOT/usr/share/YaST2/modules/YaPI/
mkdir -p $RPM_BUILD_ROOT/usr/share/PolicyKit/policy/
cp %{SOURCE2} $RPM_BUILD_ROOT/usr/share/PolicyKit/policy/

%clean
rm -rf $RPM_BUILD_ROOT

%post
# granting all permissions for the web user
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null
/usr/sbin/grantwebyastrights --user yastws --action grant > /dev/null

%postun

%files 
%defattr(-,root,root)
%dir /srv/www/%{pkg_user}
%dir /srv/www/%{pkg_user}/vendor
%dir /srv/www/%{pkg_user}/vendor/plugins
%dir /srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
# ntp require only yast2-dbus server, so it must ensure that directory exist
%dir /usr/share/YaST2/
%dir /usr/share/YaST2/modules/
%dir /usr/share/YaST2/modules/YaPI/
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/README
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/Rakefile
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/init.rb
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/install.rb
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/uninstall.rb
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/app
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/config
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/public
/usr/share/YaST2/modules/YaPI/NTP.pm
/usr/share/PolicyKit/policy/org.opensuse.yast.modules.yapi.ntp.policy
%doc COPYING

