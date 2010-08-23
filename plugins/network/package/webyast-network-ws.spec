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
Provides:       WebYaST(org.opensuse.yast.modules.yapi.network.routes)
Provides:       WebYaST(org.opensuse.yast.modules.yapi.network.interfaces)
Provides:       WebYaST(org.opensuse.yast.modules.yapi.network.hostname)
Provides:       WebYaST(org.opensuse.yast.modules.yapi.network.dns)
Provides:       yast2-webservice-network = %{version}
Obsoletes:      yast2-webservice-network < %{version}
License:	GPL v2 only
Group:          Productivity/Networking/Web/Utilities
URL:            http://en.opensuse.org/Portal:WebYaST
Autoreqprov:    on
Version:        0.1.8
Release:        0
Summary:        WebYaST - Network service
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

BuildRequires:  webyast-base-ws-testsuite
BuildRequires:	rubygem-test-unit rubygem-mocha

#
%define plugin_name network
%define plugin_dir %{webyast_ws_dir}/vendor/plugins/%{plugin_name}
#

%package testsuite
Group:    Productivity/Networking/Web/Utilities
Requires: %{name} = %{version}
Requires: webyast-base-ws-testsuite
Summary:  Testsuite for webyast-network-ws package

%description
WebYaST - Plugin providing REST based interface for network configuration.
Authors:
--------
    Michael Zugec <mzugec@suse.cz>

%description testsuite
This package contains complete testsuite for webyast-network-ws webservice package.
It's only needed for verifying the functionality of the module and it's not
needed at runtime.

%prep
%setup -q -n www


%build
# build restdoc documentation
mkdir -p public/network/restdoc
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
mkdir -p $RPM_BUILD_ROOT%{plugin_dir}
cp -a * $RPM_BUILD_ROOT%{plugin_dir}/
rm -f $RPM_BUILD_ROOT%{plugin_dir}/COPYING

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
/usr/sbin/grantwebyastrights --user %{webyast_ws_user} --action grant > /dev/null ||:

%files
%defattr(-,root,root)
%dir %{webyast_ws_dir}
%dir %{webyast_ws_dir}/vendor
%dir %{webyast_ws_dir}/vendor/plugins
%dir %{plugin_dir}
%{plugin_dir}/Rakefile
%{plugin_dir}/app
%{plugin_dir}/config
%{plugin_dir}/doc
%{plugin_dir}/public

%dir /usr/share/PolicyKit
%dir /usr/share/PolicyKit/policy
%attr(644,root,root) %config /usr/share/PolicyKit/policy/org.opensuse.yast.modules.yapi.network.policy
%doc COPYING

%files testsuite
%defattr(-,root,root)
%{plugin_dir}/test

%changelog
