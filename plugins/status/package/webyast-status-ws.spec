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
Provides:       WebYaST(org.opensuse.yast.system.metrics)
Provides:       WebYaST(org.opensuse.yast.system.logs)
Provides:       WebYaST(org.opensuse.yast.system.graphs)
Provides:       yast2-webservice-status = %{version}
Obsoletes:      yast2-webservice-status < %{version}
License:	GPL v2 only
Group:          Productivity/Networking/Web/Utilities
URL:            http://en.opensuse.org/Portal:WebYaST
Autoreqprov:    on
Version:        0.2.2
Release:        0
Summary:        WebYaST - system status service
Source:         www.tar.bz2
Source1:        org.opensuse.yast.system.status.policy
Source2:	org.opensuse.yast.modules.logfile.policy
Source3:	LogFile.rb
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
PreReq:         yast2-webservice, collectd, rubygem-gettext_rails, %insserv_prereq
Requires:       rrdtool
# for calling ruby module via YastService:
Requires:	yast2-ruby-bindings >= 0.3.2.1

BuildRequires:  rubygem-yast2-webservice-tasks rubygem-restility

BuildRequires:  webyast-base-ws-testsuite rubygem-gettext_rails
BuildRequires:	rubygem-test-unit rubygem-mocha

#
%define plugin_name status
%define plugin_dir %{webyast_ws_dir}/vendor/plugins/%{plugin_name}
#

%package testsuite
Group:    Productivity/Networking/Web/Utilities
Requires: %{name} = %{version}
Requires: webyast-base-ws-testsuite
Summary:  Testsuite for webyast-status-ws package

%description
WebYaST - Plugin providing REST based interface to provide information about system status.

Authors:
--------
    Björn Geuken <bgeuken@suse.de>
    Duncan Mac-Vicar Prett <dmacvicar@suse.de>
    Stefan Schubert <schubi@suse.de>

%description testsuite
This package contains complete testsuite for webyast-status-ws webservice package.
It's only needed for verifying the functionality of the module and it's not
needed at runtime.

%prep
%setup -q -n www


%build
# create the output directory for the generated documentation
 mkdir -p public/%{plugin_name}/restdoc
 # build restdoc documentation
%webyast_ws_restdoc
 
 # do not package restdoc sources
 rm -rf restdoc

export RAILS_PARENT=%{webyast_ws_dir}
env LANG=en rake makemo

%check
# run the testsuite
%webyast_ws_check

%install

#
# Install all web and frontend parts.
#
mkdir -p $RPM_BUILD_ROOT%{plugin_dir}
cp -a * $RPM_BUILD_ROOT%{plugin_dir}/
rm -f $RPM_BUILD_ROOT%{plugin_dir}/COPYING

# Policies
mkdir -p $RPM_BUILD_ROOT/usr/share/PolicyKit/policy
install -m 0644 %SOURCE1 $RPM_BUILD_ROOT/usr/share/PolicyKit/policy/
install -m 0644 %SOURCE2 $RPM_BUILD_ROOT/usr/share/PolicyKit/policy/

# LogFile.rb
mkdir -p $RPM_BUILD_ROOT/usr/share/YaST2/modules/
cp %{SOURCE3} $RPM_BUILD_ROOT/usr/share/YaST2/modules/

mkdir -p $RPM_BUILD_ROOT/etc/webyast/vendor
cp $RPM_BUILD_ROOT/%{plugin_dir}/doc/logs.yml $RPM_BUILD_ROOT/etc/webyast

# remove .po files (no longer needed)
rm -rf $RPM_BUILD_ROOT/%{plugin_dir}/po

# search locale files
%find_lang webyast-status-ws

%clean
rm -rf $RPM_BUILD_ROOT

%post
#
# granting all permissions for root
#
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null
/usr/sbin/grantwebyastrights --user %{webyast_ws_user} --action grant > /dev/null

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
# set "Hostname" to WebYaST and remove already generated old log files
#
sed -i "s/^#Hostname[[:space:]].*/#If you change hostname please delete \/var\/lib\/collectd\/WebYaST\nHostname \"WebYaST\"/" "/etc/collectd.conf"
rm -rf /var/lib/collectd/*

#
# enable and restart  collectd if it running
# 
%{fillup_and_insserv -Y collectd}
rccollectd try-restart

%files  -f webyast-status-ws.lang
%defattr(-,root,root)
%dir /usr/share/YaST2/
%dir /usr/share/YaST2/modules/
/usr/share/YaST2/modules/LogFile.rb

%dir %{webyast_ws_dir}
%dir %{webyast_ws_dir}/vendor
%dir %{webyast_ws_dir}/vendor/plugins
%dir %{plugin_dir}
%dir %{plugin_dir}/doc
%dir %{plugin_dir}/locale
%{plugin_dir}/app
%{plugin_dir}/doc/README_FOR_APP
%{plugin_dir}/doc/logs.yml
%{plugin_dir}/Rakefile
%{plugin_dir}/README
%{plugin_dir}/lib
%{plugin_dir}/public
%{plugin_dir}/config/*
%dir %attr (-,%{webyast_ws_user},root) %{plugin_dir}/config

%dir /usr/share/PolicyKit
%dir /usr/share/PolicyKit/policy
%attr(644,root,root) %config /usr/share/PolicyKit/policy/org.opensuse.yast.system.status.policy
%attr(644,root,root) %config /usr/share/PolicyKit/policy/org.opensuse.yast.modules.logfile.policy
%dir /etc/webyast/vendor
%config /etc/webyast/logs.yml
%doc COPYING

%files testsuite
%defattr(-,root,root)
%{plugin_dir}/test

%changelog
