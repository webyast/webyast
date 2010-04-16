#
# spec file for package webyast-services-ws (Version 0.1)
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           webyast-services-ws
Provides:       WebYaST(org.opensuse.yast.modules.yapi.services)
Provides:       yast2-webservice-services = %{version}
Obsoletes:      yast2-webservice-services < %{version}
PreReq:         yast2-webservice
License:	GPL v2 only
Group:          Productivity/Networking/Web/Utilities
Autoreqprov:    on
Version:        0.1.10
Release:        0
Summary:        WebYaST - system services management service
Source:         www.tar.bz2
Source1:        org.opensuse.yast.modules.yapi.services.policy
Source2:	YML.rb
Source3:	filter_services.yml
Source4:	SERVICES.pm
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
BuildRequires:  rubygem-yast2-webservice-tasks rubygem-restility

BuildRequires:  webyast-base-ws-testsuite
BuildRequires:	rubygem-test-unit rubygem-mocha

# so SERVICES.pm is able to call YML.rb
Requires:       yast2-ruby-bindings >= 0.3.2.1
# for SERVICES.pm
Requires:	yast2-runlevel

#
%define pkg_user yastws
%define plugin_name services
#

%package testsuite
Requires: %{name} = %{version}
Requires: webyast-base-ws-testsuite
Summary:  Testsuite for webyast-services-ws package

%description
WebYaST - Plugin providing REST based interface to handle system services.
Authors:
--------
    Stefan Schubert <schubi@opensuse.org>
    Jiri Suchomel <jsuchome@suse.cz>
    Ladislav Slezak <lslezak@suse.cz>

%description testsuite
This package contains complete testsuite for webyast-services-ws webservice package.
It's only needed for verifying the functionality of the module and it's not
needed at runtime.

%prep
%setup -q -n www

%build

# build restdoc documentation
mkdir -p public/services/restdoc
%webyast_ws_restdoc

# do not package restdoc sources
rm -rf restdoc

%check
# run the testsuite
%webyast_ws_check

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

# YML.rb
mkdir -p $RPM_BUILD_ROOT/usr/share/YaST2/modules/
cp %{SOURCE2} $RPM_BUILD_ROOT/usr/share/YaST2/modules/

# SERVICES.pm
mkdir -p $RPM_BUILD_ROOT/usr/share/YaST2/modules/YaPI/
cp %{SOURCE4} $RPM_BUILD_ROOT/usr/share/YaST2/modules/YaPI/

# copy example filter_services.yml
mkdir -p $RPM_BUILD_ROOT/etc/webyast/
cp %SOURCE3 $RPM_BUILD_ROOT/etc/webyast/


%clean
rm -rf $RPM_BUILD_ROOT

%post
#
# granting all permissions for root 
#
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null ||:
/usr/sbin/grantwebyastrights --user yastws --action grant > /dev/null ||:

%files 
%defattr(-,root,root)
%dir /srv/www/%{pkg_user}
%dir /srv/www/%{pkg_user}/vendor
%dir /srv/www/%{pkg_user}/vendor/plugins
%dir /srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
%dir /srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/doc
%dir /usr/share/YaST2/
%dir /usr/share/YaST2/modules/
%dir /usr/share/YaST2/modules/YaPI/
%dir /usr/share/PolicyKit
%dir /usr/share/PolicyKit/policy
%dir /etc/webyast/
%config /etc/webyast/filter_services.yml
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/README
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/Rakefile
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/init.rb
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/install.rb
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/uninstall.rb
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/app
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/config
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/tasks
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/doc
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/public
/usr/share/YaST2/modules/YML.rb
/usr/share/YaST2/modules/YaPI/SERVICES.pm

%attr(644,root,root) %config /usr/share/PolicyKit/policy/org.opensuse.yast.modules.yapi.%{plugin_name}.policy
%doc COPYING

%files testsuite
%defattr(-,root,root)
%{webyast_ws_dir}/vendor/plugins/%{plugin_name}/test

%changelog