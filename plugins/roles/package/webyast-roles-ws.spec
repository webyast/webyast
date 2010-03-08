#
# spec file for package webyast-roles-ws (Version 0.1)
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           webyast-roles-ws
PreReq:         yast2-webservice
License:	GPL v2 only
Group:          Productivity/Networking/Web/Utilities
Autoreqprov:    on
Version:        0.1.0
Release:        0
Summary:        Webyast rest service which provides operations on roles
Source:         www.tar.bz2
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
BuildRequires:  rubygem-mocha
Source1:        roles.yml
Source2:        roles_assign.yml

#
%define pkg_user yastws
%define plugin_name roles
#


%description
YaST2 - Webservice - REST based interface of YaST in order to handle time and date.
Authors:
--------
    Stefan Schubert <schubi@opensuse.org>
    Josef Reidinger <jreidinger@suse.cz>

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
mkdir -p $RPM_BUILD_ROOT/usr/share/PolicyKit/policy
mkdir -p $RPM_BUILD_ROOT/var/lib/yastws/roles
cp %{SOURCE1} %{SOURCE2} $RPM_BUILD_ROOT/var/lib/yastws/roles

%clean
rm -rf $RPM_BUILD_ROOT

%post
#
# granting all permissions for root 
#
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null
# XXX not nice to get yastws all permissions, but now not better solution
/usr/sbin/grantwebyastrights --user yastws --action grant > /dev/null

%files 
%defattr(-,root,root)
%dir /srv/www/%{pkg_user}
%dir /srv/www/%{pkg_user}/vendor
%dir /srv/www/%{pkg_user}/vendor/plugins
%dir /srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
%dir /srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/doc
%dir /usr/share/PolicyKit
%dir /usr/share/PolicyKit/policy/
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/README
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/Rakefile
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/init.rb
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/install.rb
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/uninstall.rb
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/app
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/config
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/tasks
#/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/test
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/doc/README_FOR_APP
%config /var/lib/yastws/roles

%doc COPYING
