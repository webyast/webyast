#
# spec file for package yast2-webservice-administrator
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-webservice-administrator
PreReq:         yast2-webservice
Provides:       yast2-webservice:/srv/www/yastws/app/controllers/administrator_controller.rb
License:	GPL v2 only
Group:          Productivity/Networking/Web/Utilities
Autoreqprov:    on
Version:        0.0.8
Release:        0
Summary:        YaST2 - Webservice - Administrator
Source:         www.tar.bz2
Source1:	org.opensuse.yast.modules.yapi.administrator.policy
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
BuildRequires:  rubygem-yast2-webservice-tasks rubygem-restility

# requires YaPI::USERS
%if 0%{?suse_version} == 0 || %suse_version > 1110
# 11.2 or newer
Requires:       yast2-users >= 2.18.13
%else
# 11.1 or SLES11
Requires:       yast2-users >= 2.17.29
%endif

#
%define pkg_user yastws
%define plugin_name administrator
#


%description
YaST2 - Webservice - REST based interface for administrator's attributes

Authors:
--------
    Jiri Suchomel <jsuchome@novell.com>

%prep
%setup -q -n www

%build
# build restdoc documentation
mkdir -p public/administrator/restdoc
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
# granting all permissions for the web user
/etc/yastws/tools/policyKit-rights.rb --user root --action grant >& /dev/null || :
/etc/yastws/tools/policyKit-rights.rb --user yastws --action grant >& /dev/null || :

%postun

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
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/doc
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/public
%dir /usr/share/PolicyKit
%dir /usr/share/PolicyKit/policy
%attr(644,root,root) %config /usr/share/PolicyKit/policy/org.opensuse.yast.modules.yapi.%{plugin_name}.policy
%doc COPYING


%changelog
