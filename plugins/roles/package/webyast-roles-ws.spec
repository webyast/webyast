#
# spec file for package webyast-roles-ws (Version 0.1)
#
# Copyright (c) 2010 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           webyast-roles-ws
Provides:       WebYaST(org.opensuse.yast.roles)
PreReq:         yast2-webservice
License:	GPL v2 only
Group:          Productivity/Networking/Web/Utilities
URL:            http://en.opensuse.org/Portal:WebYaST
Autoreqprov:    on
Version:        0.1.0
Release:        0
Summary:        WebYaST - role management service
Source:         www.tar.bz2
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
Source1:        roles.yml
Source2:        roles_assign.yml
Source3:        org.opensuse.yast.roles.policy

BuildRequires:  webyast-base-ws-testsuite
BuildRequires:	rubygem-test-unit rubygem-mocha

#
%define plugin_name roles
%define plugin_dir %{webyast_ws_dir}/vendor/plugins/%{plugin_name}
#

%package testsuite
Group:    Productivity/Networking/Web/Utilities
Requires: %{name} = %{version}
Requires: webyast-base-ws-testsuite
Summary:  Testsuite for webyast-roles-ws package

%description
WebYaST - Plugin providing REST based interface for roles management.

Authors:
--------
    Josef Reidinger <jreidinger@suse.cz>

%description testsuite
This package contains complete testsuite for webyast-roles-ws webservice package.
It's only needed for verifying the functionality of the module and it's not
needed at runtime.

%prep
%setup -q -n www

%build

%check
# run the testsuite
%webyast_ws_check

%install

#
# Install all web and frontend parts.
#
mkdir -p $RPM_BUILD_ROOT%{plugin_dir}
cp -a * $RPM_BUILD_ROOT%{plugin_dir}/
rm -f $RPM_BUILD_ROOT%{plugin_dir}/COPYING

mkdir -p $RPM_BUILD_ROOT/usr/share/PolicyKit/policy

mkdir -p $RPM_BUILD_ROOT%{webyast_ws_vardir}/roles
cp %{SOURCE1} %{SOURCE2} $RPM_BUILD_ROOT%{webyast_ws_vardir}/roles

cp %{SOURCE3} $RPM_BUILD_ROOT/usr/share/PolicyKit/policy/

%clean
rm -rf $RPM_BUILD_ROOT

%post
#
# granting all permissions for root 
#
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null
# XXX not nice to get yastws all permissions, but now not better solution
/usr/sbin/grantwebyastrights --user %{webyast_ws_user} --action grant > /dev/null

%files 
%defattr(-,root,root)
%dir %{webyast_ws_dir}
%dir %{webyast_ws_dir}/vendor
%dir %{webyast_ws_dir}/vendor/plugins
%dir %{plugin_dir}
%dir %{plugin_dir}/doc

%dir /usr/share/PolicyKit
%dir /usr/share/PolicyKit/policy/
%{plugin_dir}/README
%{plugin_dir}/Rakefile
%{plugin_dir}/init.rb
%{plugin_dir}/install.rb
%{plugin_dir}/uninstall.rb
%{plugin_dir}/app
%{plugin_dir}/config
%{plugin_dir}/lib
%{plugin_dir}/doc/README_FOR_APP
%attr(0700,%{webyast_ws_user},%{webyast_ws_user}) %dir %{webyast_ws_vardir}/roles
%attr(0600,%{webyast_ws_user},%{webyast_ws_user}) %config %{webyast_ws_vardir}/roles/*
/usr/share/PolicyKit/policy/org.opensuse.yast.roles.policy

%doc COPYING

%files testsuite
%defattr(-,root,root)
%{plugin_dir}/test

%changelog
