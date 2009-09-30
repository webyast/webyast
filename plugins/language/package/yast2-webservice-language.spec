#
# spec file for package yast2-webservice-language (Version 0.1)
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-webservice-language
PreReq:         yast2-webservice
Provides:       yast2-webservice:/srv/www/yastws/app/controllers/language_controller.rb
License:        MIT
Group:          Productivity/Networking/Web/Utilities
Autoreqprov:    on
Version:        0.0.4
Release:        0
Summary:        YaST2 - Webservice - Language
Source:         www.tar.bz2
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
BuildRequires:  rubygem-mocha
Requires:       yast2-country >= 2.18.9

#
%define pkg_user yastws
%define plugin_name language
#


%description
YaST2 - Webservice - REST based interface of YaST in order to handle language settings.
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

%clean
rm -rf $RPM_BUILD_ROOT

%post
#
# granting all permissions for root 
#
/etc/yastws/tools/policyKit-rights.rb --user root --action grant >& /dev/null || :

%files 
%defattr(-,root,root)
%dir /srv/www/%{pkg_user}
%dir /srv/www/%{pkg_user}/vendor
%dir /srv/www/%{pkg_user}/vendor/plugins
%dir /srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
%dir /srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/doc
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/MIT-LICENSE
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/README
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/Rakefile
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/init.rb
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/install.rb
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/uninstall.rb
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/app
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/config
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/tasks
#/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/test
/srv/www/yastws/vendor/plugins/language/doc/README_FOR_APP

