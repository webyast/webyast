#
# spec file for package webyast-network
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           webyast-network
Provides:       WebYaST(org.opensuse.yast.modules.yapi.network.routes)
Provides:       WebYaST(org.opensuse.yast.modules.yapi.network.interfaces)
Provides:       WebYaST(org.opensuse.yast.modules.yapi.network.hostname)
Provides:       WebYaST(org.opensuse.yast.modules.yapi.network.dns)
Provides:       yast2-webservice-network = %{version}
Obsoletes:      yast2-webservice-network < %{version}
License:        GPL-2.0	
Group:          Productivity/Networking/Web/Utilities
URL:            http://en.opensuse.org/Portal:WebYaST
Autoreqprov:    on
Version:        0.2.6
Release:        0
Summary:        WebYaST - Network 
Source:         www.tar.bz2
Source1:        org.opensuse.yast.modules.yapi.network.policy
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
BuildRequires:  tidy rubygem-webyast-rake-tasks rubygem-restility
PreReq:         yast2-webservice
# YaPI/NETWORK.pm
%if 0%{?suse_version} == 0 || %suse_version > 1110
Requires:       yast2-network >= 2.18.51
%else
Requires:       yast2-network >= 2.17.78.1
%endif

BuildRequires:  webyast-base-testsuite
BuildRequires:	rubygem-test-unit rubygem-mocha

#
%define plugin_name network
%define plugin_dir %{webyast_dir}/vendor/plugins/%{plugin_name}
#

%package testsuite
Group:    Productivity/Networking/Web/Utilities
Requires: %{name} = %{version}
Requires: webyast-base-testsuite
Summary:  Testsuite for webyast-network package

%description
WebYaST - Plugin providing REST based interface for network configuration.
Authors:
--------
    Michael Zugec <mzugec@suse.cz>

%description testsuite
This package contains complete testsuite for webyast-network package.
It's only needed for verifying the functionality of the module and it's not
needed at runtime.

%prep
%setup -q -n www


%build
# build restdoc documentation
mkdir -p public/network/restdoc
%webyast_restdoc

# do not package restdoc sources
rm -rf restdoc

export RAILS_PARENT=%{webyast_dir}
env LANG=en rake makemo

%check
# run the testsuite
%webyast_check

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

# remove .po files (no longer needed)
rm -rf $RPM_BUILD_ROOT/%{plugin_dir}/po

# search locale files
%find_lang webyast-network

%clean
rm -rf $RPM_BUILD_ROOT

%post
#
# granting all permissions for root
#
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null ||:
# and for webyast
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant > /dev/null ||:

%files -f webyast-network.lang
%defattr(-,root,root)
%dir %{webyast_dir}
%dir %{webyast_dir}/vendor
%dir %{webyast_dir}/vendor/plugins
%dir %{plugin_dir}
%{plugin_dir}/Rakefile
%{plugin_dir}/shortcuts.yml
%{plugin_dir}/app
%{plugin_dir}/config
%{plugin_dir}/doc
%{plugin_dir}/public
%{plugin_dir}/locale

%dir /usr/share/PolicyKit
%dir /usr/share/PolicyKit/policy
%attr(644,root,root) %config /usr/share/PolicyKit/policy/org.opensuse.yast.modules.yapi.network.policy
%doc COPYING

%files testsuite
%defattr(-,root,root)
%{plugin_dir}/test

%changelog
