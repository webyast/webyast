#
# spec file for package yast2-webservice-samba-server
#
# Copyright (c) 2009 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

%define pkg_user yastws
%define plugin_name samba-server

Name:           yast2-webservice-samba-server
Provides:       WebYaST(org.opensuse.yast.system.sambashares)
PreReq:         yast2-webservice
Provides:       yast2-webservice:/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/app/controllers/sambashares_controller.rb
License:	GPL v2 only
Group:          Productivity/Networking/Web/Utilities
Autoreqprov:    on
Version:        0.0.3
Release:        0
Summary:        YaST2 - Webservice - REST API for Samba Server configuration
Source:         www.tar.bz2
Source1:        org.opensuse.yast.modules.yapi.samba.policy
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch



%description
YaST2 - Webservice - REST based interface of YaST which handles Samba server settings.
Authors:
--------
    Ladislav Slezák <lslezak@novell.com>

%prep
%setup -q -n www

%build
#remove generated doc
rm -rf doc 

%install

#
# Install all web and frontend parts.
#
mkdir -p $RPM_BUILD_ROOT/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
cp -a * $RPM_BUILD_ROOT/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
rm -f $RPM_BUILD_ROOT/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/COPYING

# install policies
mkdir -p $RPM_BUILD_ROOT/usr/share/PolicyKit/policy
install -m 0644 %SOURCE1 $RPM_BUILD_ROOT/usr/share/PolicyKit/policy/


%clean
rm -rf $RPM_BUILD_ROOT

%post
# grant the needed privileges to the server user
/usr/sbin/grantwebyastrights --user yastws --action grant > /dev/null

# grant the needed privileges to root
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null

%files 
%defattr(-,root,root)
%dir /srv/www/%{pkg_user}
%dir /srv/www/%{pkg_user}/vendor
%dir /srv/www/%{pkg_user}/vendor/plugins
%dir /srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/README
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/Rakefile
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/init.rb
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/install.rb
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/uninstall.rb
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/app
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/config
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/tasks
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/rakelib
%dir /usr/share/PolicyKit
%dir /usr/share/PolicyKit/policy
%attr(644,root,root) %config /usr/share/PolicyKit/policy/org.opensuse.yast.modules.yapi.samba.policy
%doc COPYING
