#
# spec file for package webyast-network-ws
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           webyast-network-ws
Provides:       yast2-webservice-network = %{version}
Obsoletes:      yast2-webservice-network < %{version}
License:	GPL v2 only
Group:          Productivity/Networking/Web/Utilities
Autoreqprov:    on
Version:        0.1.3
Release:        0
Summary:        YaST2 - Webservice - Network
Source:         www.tar.bz2
Source1:        org.opensuse.yast.modules.yapi.network.policy
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
BuildRequires:  rubygem-yast2-webservice-tasks rubygem-restility
PreReq:         yast2-webservice
# YaPI/NETWORK.pm
%if 0%{?suse_version} == 0 || %suse_version > 1110
Requires:       yast2-network >= 2.18.51
%else
Requires:       yast2-network >= 2.17.78.1
%endif

#
%define pkg_user yastws
%define plugin_name network
#


%description
YaST2 - Webservice - REST based interface of YaST in order to handle firewall and ssh settings.
Authors:
--------
    Michael Zugec <mzugec@suse.cz>

%prep
%setup -q -n www


%build
# build restdoc documentation
mkdir -p public/network/restdoc
export RAILS_PARENT=/srv/www/yastws
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

%clean
rm -rf $RPM_BUILD_ROOT

%post
#
# granting all permissions for root
#
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null ||:
# and for yastws
/usr/sbin/grantwebyastrights --user %{pkg_user} --action grant > /dev/null ||:

%files
%defattr(-,root,root)
%dir /srv/www/%{pkg_user}
%dir /srv/www/%{pkg_user}/vendor
%dir /srv/www/%{pkg_user}/vendor/plugins
%dir /srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/*
%dir /usr/share/PolicyKit
%dir /usr/share/PolicyKit/policy
%attr(644,root,root) %config /usr/share/PolicyKit/policy/org.opensuse.yast.modules.yapi.%{plugin_name}.policy
%doc COPYING
