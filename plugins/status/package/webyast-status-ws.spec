#
# spec file for package webyast-status-ws (Version 0.1)
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           webyast-status-ws
Provides:       yast2-webservice-status = %{version}
Obsoletes:      yast2-webservice-status < %{version}
License:	GPL v2 only
Group:          Productivity/Networking/Web/Utilities
Autoreqprov:    on
Version:        0.0.12
Release:        0
Summary:        YaST2 - Webservice - Status
Source:         www.tar.bz2
Source1:        org.opensuse.yast.system.status.policy
Source2:	org.opensuse.yast.modules.logfile.policy
Source3:	LogFile.rb
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
PreReq:         yast2-webservice, collectd, %insserv_prereq
Requires:       rrdtool
# for calling ruby module via YastService:
Requires:	yast2-ruby-bindings >= 0.3.2.1

BuildRequires:  rubygem-yast2-webservice-tasks rubygem-restility

#
%define pkg_user yastws
%define plugin_name status
#


%description
YaST2 - Webservice - REST based interface of YaST in order to handle firewall and ssh settings.
Authors:
--------
    Björn Geuken <bgeuken@suse.de>
    Duncan Mac-Vicar Prett <dmacvicar@suse.de>
    Stefan Schubert <schubi@suse.de>

%prep
%setup -q -n www


%build
# create the output directory for the generated documentation
 mkdir -p public/%{plugin_name}/restdoc
 # build restdoc documentation
 export RAILS_PARENT=/srv/www/%{pkg_user}
 env LANG=en rake restdoc

 # do not package restdoc sources
 rm -rf restdoc

%install

#
# Install all web and frontend parts.
#
mkdir -p $RPM_BUILD_ROOT/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
cp -a * $RPM_BUILD_ROOT/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
rm -f $RPM_BUILD_ROOT/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/COPYING

# Policies
mkdir -p $RPM_BUILD_ROOT/usr/share/PolicyKit/policy
install -m 0644 %SOURCE1 $RPM_BUILD_ROOT/usr/share/PolicyKit/policy/
install -m 0644 %SOURCE2 $RPM_BUILD_ROOT/usr/share/PolicyKit/policy/

# LogFile.rb
mkdir -p $RPM_BUILD_ROOT/usr/share/YaST2/modules/
cp %{SOURCE3} $RPM_BUILD_ROOT/usr/share/YaST2/modules/

%clean
rm -rf $RPM_BUILD_ROOT

%post
#
# granting all permissions for root
#
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null

#
# nslookup of static hostnames can result to an error. Due this error collectd
# will not be started. So FQDN (fully qualified domain name) is disabled.
#
sed -i "s/^FQDNLookup.*/FQDNLookup false/" "/etc/collectd.conf"

#
# enable "df" plugin of collectd
#
sed -i "s/^#LoadPlugin df.*/LoadPlugin df/" "/etc/collectd.conf"

#
# set "Hostname" to WebYaST
#
sed -i "s/^#Hostname[[:space:]].*/#If you change hostname please delete \/var\/lib\/collectd\/WebYaST\nHostname \"WebYaST\"/" "/etc/collectd.conf"
#
# enable and start  collectd
# 
%{fillup_and_insserv -Y collectd}
rccollectd try-restart

%files
%defattr(-,root,root)
%dir /usr/share/YaST2/
%dir /usr/share/YaST2/modules/
/usr/share/YaST2/modules/LogFile.rb
%dir /srv/www/%{pkg_user}
%dir /srv/www/%{pkg_user}/vendor
%dir /srv/www/%{pkg_user}/vendor/plugins
%dir /srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
%dir /srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/doc
%dir /srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/config
%dir /usr/share/PolicyKit
%dir /usr/share/PolicyKit/policy
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/*
%attr(644,root,root) %config /usr/share/PolicyKit/policy/org.opensuse.yast.system.%{plugin_name}.policy
%attr(644,root,root) %config /usr/share/PolicyKit/policy/org.opensuse.yast.modules.logfile.policy
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/doc/README_FOR_APP
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/doc/logs.yml

%doc COPYING

%changelog
