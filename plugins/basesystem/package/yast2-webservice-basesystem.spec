#
# spec file for package yast2-webservice-basesystem (Version 0.1)
#
# Copyright (c) 2008-09 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-webservice-basesystem
PreReq:         yast2-webservice
License:	GPL v2 only
Group:          Productivity/Networking/Web/Utilities
Autoreqprov:    on
Version:        0.0.10
Release:        0
Summary:        YaST2 - Webservice - Basesystem
Source:         www.tar.bz2
Source1:        basesystem.yml
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
BuildRequires:  rubygem-mocha

#
%define pkg_user yastws
%define plugin_name basesystem
#


%description
YaST2 - Webservice - REST based interface of YaST in order to handle initial basic system settings.

Authors:
--------
    Josef Reidinger <jreidinger@suse.cz>
    Martin Kudlvasr <mkudlvasr@suse.cz>

%prep
%setup -q -n www

%build

%install

#
# Install all web and frontend parts.
#
mkdir -p $RPM_BUILD_ROOT/var/lib/yastws/%{plugin_name}
mkdir -p $RPM_BUILD_ROOT/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
cp -a * $RPM_BUILD_ROOT/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
rm -f $RPM_BUILD_ROOT/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/COPYING
#FIXME maybe location change in future

mkdir -p $RPM_BUILD_ROOT/etc/webyast/
cp %SOURCE1 $RPM_BUILD_ROOT/etc/webyast/

%clean
rm -rf $RPM_BUILD_ROOT


%files 
%defattr(-,root,root)
%dir /srv/www/%{pkg_user}
%dir /srv/www/%{pkg_user}/vendor
%dir /srv/www/%{pkg_user}/vendor/plugins
%dir /srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
%dir /srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/doc
#var dir to store basesystem status
%dir %attr (-,%{pkg_user},root) /var/lib/yastws
%dir %attr (-,%{pkg_user},root) /var/lib/yastws/%{plugin_name}
%dir /etc/webyast/
%config /etc/webyast/basesystem.yml
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/README
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/Rakefile
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/init.rb
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/install.rb
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/uninstall.rb
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/app
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/config
#/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/tasks
#/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/test
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/doc/README_FOR_APP
%doc COPYING

