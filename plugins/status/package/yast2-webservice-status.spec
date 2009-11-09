#
# spec file for package yast2-webservice-status (Version 0.1)
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-webservice-status
License:	GPL v2 only
Group:          Productivity/Networking/Web/Utilities
Autoreqprov:    on
Version:        0.0.6
Release:        0
Summary:        YaST2 - Webservice - Status
Source:         www.tar.bz2
Source1:        org.opensuse.yast.system.status.policy
Source2:	org.opensuse.yast.modules.logfile.policy
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
PreReq:         yast2-webservice, collectd, %insserv_prereq
Requires:       rrdtool
# for calling ruby module via YastService:
Requires:	yast2-ruby-bindings >= 0.3.2.1

# This is for Hudson (build server) to prepare the build env correctly.
%if 0
BuildRequires:  collectd
%endif

#
%define pkg_user yastws
%define plugin_name status
#


%description
YaST2 - Webservice - REST based interface of YaST in order to handle firewall and ssh settings.
Authors:
--------
    Björn Geuken <bgeuken@suse.de>

%prep
%setup -q -n www


%build

%install

#
# Install all web and frontend parts.
#
mkdir -p $RPM_BUILD_ROOT/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
cp -a * $RPM_BUILD_ROOT/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
rm -f $RPM_BUILD_ROOT/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/COPYING
#rm $RPM_BUILD_ROOT/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/config/status_limits.yaml

# Policies
mkdir -p $RPM_BUILD_ROOT/usr/share/PolicyKit/policy
install -m 0644 %SOURCE1 $RPM_BUILD_ROOT/usr/share/PolicyKit/policy/
install -m 0644 %SOURCE2 $RPM_BUILD_ROOT/usr/share/PolicyKit/policy/

%clean
rm -rf $RPM_BUILD_ROOT

%post
#
# granting all permissions for root
#
/etc/yastws/tools/policyKit-rights.rb --user root --action grant >& /dev/null || :
#
# enable and start  collectd
# 
%{fillup_and_insserv -Y collectd}
rccollectd start

%files
%defattr(-,root,root)
%dir /srv/www/%{pkg_user}
%dir /srv/www/%{pkg_user}/vendor
%dir /srv/www/%{pkg_user}/vendor/plugins
%dir /srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
%attr(-,%{pkg_user},%{pkg_user}) %dir /srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/config
%dir /usr/share/PolicyKit
%dir /usr/share/PolicyKit/policy
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/*
%attr(644,root,root) %config /usr/share/PolicyKit/policy/org.opensuse.yast.system.%{plugin_name}.policy
%attr(644,root,root) %config /usr/share/PolicyKit/policy/org.opensuse.yast.modules.logfile.policy
%doc COPYING

%changelog
