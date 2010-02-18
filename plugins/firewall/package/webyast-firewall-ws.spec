#
# spec file for package yast2-webservice-firewall (Version 0.1)
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           webyast-firewall-ws
PreReq:         webyast-base-ws
License:        GPL v2 only
Group:          Productivity/Networking/Web/Utilities
Autoreqprov:    on
Version:        1.0.1
Release:        0
Summary:        YaST2 - Webservice - Firewall
Source:         www.tar.bz2
Source1:        org.opensuse.yast.modules.yapi.firewall.policy
Source2:        FIREWALL.pm
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
BuildRequires:  rubygem-yast2-webservice-tasks rubygem-restility

#
%define pkg_user yastws
%define plugin_name firewall
#


%description
YaST2 - Webservice - REST based interface of YaST in order to handle firewall settings.
Authors:
--------
    Martin Kudlvasr<mkudlvasr@novell.com>

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

# Policies
mkdir -p $RPM_BUILD_ROOT/usr/share/PolicyKit/policy
install -m 0644 %SOURCE1 $RPM_BUILD_ROOT/usr/share/PolicyKit/policy/

#YaPI
mkdir -p $RPM_BUILD_ROOT/usr/share/YaST2/modules/YaPI/
cp %{SOURCE2} $RPM_BUILD_ROOT/usr/share/YaST2/modules/YaPI/

%clean
rm -rf $RPM_BUILD_ROOT

%post
#
# granting all permissions for root
#
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null ||:
/usr/sbin/grantwebyastrights --user %{pkg_user} --action grant > /dev/null ||:

%files
%defattr(-,root,root)
%dir /srv/www/%{pkg_user}
%dir /srv/www/%{pkg_user}/vendor
%dir /srv/www/%{pkg_user}/vendor/plugins
%dir /srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
%dir /usr/share/YaST2/
%dir /usr/share/YaST2/modules/
%dir /usr/share/YaST2/modules/YaPI/
%dir /usr/share/PolicyKit
%dir /usr/share/PolicyKit/policy
%config /srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/README
%config /srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/Rakefile
%config /srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/init.rb
%config /srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/install.rb
%config /srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/uninstall.rb
%config /srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/app
%config /srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/config
%config /srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/tasks
#%config /srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/test
/usr/share/YaST2/modules/YaPI/FIREWALL.pm
%attr(644,root,root) %config /usr/share/PolicyKit/policy/org.opensuse.yast.modules.yapi.%{plugin_name}.policy
%doc COPYING
