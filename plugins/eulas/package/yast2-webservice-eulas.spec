#
# spec file for package yast2-webservice-eula (Version 0.0.1)
#
# Copyright (c) 2008-09 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-webservice-eulas
PreReq:         yast2-webservice
Provides:       yast2-webservice:/srv/www/yastws/app/controllers/eulas_controller.rb
License:	GPL v2 only
Group:          Productivity/Networking/Web/Utilities
Autoreqprov:    on
Version:        0.0.3
Release:        0
Summary:        YaST2 - Webservice - EULA
Source:         www.tar.bz2
Source1:        eulas-sles11.yml
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
BuildRequires:  rubygem-mocha

#
%define pkg_user yastws
%define plugin_name eulas
#


%description
YaST2 - Webservice - REST based interface of YaST in order to handle user acceptation of EULAs.

Authors:
--------
    Martin Kudlvasr <mkudlvasr@suse.cz>
    Josef Reidinger <jreidinger@suse.cz>

%prep
%setup -q -n www

%build

%install

#
# Install all web and frontend parts.
#
mkdir -p $RPM_BUILD_ROOT/usr/share/%{pkg_user}/%{plugin_name}
rm -r "config/resources/licenses/openSUSE-11.1"
mv config/resources/licenses $RPM_BUILD_ROOT/usr/share/%{pkg_user}/%{plugin_name}/

mkdir -p $RPM_BUILD_ROOT/var/lib/%{pkg_user}/%{plugin_name}/accepted-licenses

mkdir -p $RPM_BUILD_ROOT/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
cp -a * $RPM_BUILD_ROOT/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
rm -f $RPM_BUILD_ROOT/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/COPYING
#FIXME maybe location change in future

mkdir -p $RPM_BUILD_ROOT/etc/webyast/
cp %SOURCE1 $RPM_BUILD_ROOT/etc/webyast/eulas.yml

%clean
rm -rf $RPM_BUILD_ROOT


%files 
%defattr(-,root,root)
%dir /srv/www/%{pkg_user}
%dir /srv/www/%{pkg_user}/vendor
%dir /srv/www/%{pkg_user}/vendor/plugins
%dir /srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
%dir /srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/doc
%dir /usr/share/%{pkg_user}
%dir /usr/share/%{pkg_user}/%{plugin_name}
%dir /var/lib/%{pkg_user}
%dir /var/lib/%{pkg_user}/%{plugin_name}
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
/usr/share/%{pkg_user}/%{plugin_name}/licenses
%dir /etc/webyast/
%config /etc/webyast/eulas.yml
%defattr(-,%{pkg_user},%{pkg_user})
%dir /var/lib/%{pkg_user}/%{plugin_name}/accepted-licenses
%doc COPYING

