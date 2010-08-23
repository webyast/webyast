#
# spec file for package webyast-software-ws (Version 0.1.x)
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           webyast-software-ws
Provides:       WebYaST(org.opensuse.yast.system.repositories)
Provides:       WebYaST(org.opensuse.yast.system.patches)
Provides:       WebYaST(org.opensuse.yast.system.packages)
Provides:       yast2-webservice-patches = %{version}
Obsoletes:      yast2-webservice-patches < %{version}

# for testing
BuildRequires:  ruby-dbus >= 0.3.0

PreReq:         yast2-webservice
# ruby-dbus is required by webyast-base-ws already
# but here we use a recent feature, InterfaceElement#add_fparam
Requires:       ruby-dbus >= 0.3.0

%if 0%{?suse_version} == 0 || 0%{?suse_version} > 1120
# openSUSE-11.3 (Factory) or newer
Requires:       PackageKit >= 0.5.1-6
%if 0%{?suse_version} == 1120
# openSUSE-11.2
Requires:       PackageKit >= 0.5.1-4
%else
# openSUSE-11.1 or SLES11
Requires:       PackageKit >= 0.3.14-3
%endif
%endif

License:	GPL v2 only
Group:          Productivity/Networking/Web/Utilities
URL:            http://en.opensuse.org/Portal:WebYaST
Autoreqprov:    on
Version:        0.2.0
Release:        0
Summary:        WebYaST - software management service
Source:         www.tar.bz2
Source1:        org.opensuse.yast.system.patches.policy
Source2:        org.opensuse.yast.system.packages.policy
Source3:        org.opensuse.yast.system.repositories.policy
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch

BuildRequires:  webyast-base-ws-testsuite
BuildRequires:	rubygem-test-unit rubygem-mocha

#
%define plugin_dir %{webyast_ws_dir}/vendor/plugins/software
#

%package testsuite
Group:    Productivity/Networking/Web/Utilities
Requires: %{name} = %{version}
Requires: webyast-base-ws-testsuite
Summary:  Testsuite for webyast-software-ws package

%description
WebYaST - Plugin providing REST based interface to handle repositories, patches and packages.

Authors:
--------
    Stefan Schubert <schubi@opensuse.org>

%description testsuite
This package contains complete testsuite for webyast-software-ws package.
It's only needed for verifying the functionality of the module and it's not
needed at runtime.

%prep
%setup -q -n www

%build

#do not package developer doc
rm -rf doc

%check
# run the testsuite
#
# Disabled for now.
# PackageKit/DBus need /proc and thus don't run in build environment.
# But both are required for testing :-/
# reference: bnc#597868
# -percent-webyast_ws_check

%install

#
# Install all web and frontend parts.
#
mkdir -p $RPM_BUILD_ROOT%{plugin_dir}
cp -a * $RPM_BUILD_ROOT%{plugin_dir}
rm -f $RPM_BUILD_ROOT%{plugin_dir}/COPYING

# Policies
mkdir -p $RPM_BUILD_ROOT/usr/share/PolicyKit/policy
install -m 0644 %SOURCE1 $RPM_BUILD_ROOT/usr/share/PolicyKit/policy/
install -m 0644 %SOURCE2 $RPM_BUILD_ROOT/usr/share/PolicyKit/policy/
install -m 0644 %SOURCE3 $RPM_BUILD_ROOT/usr/share/PolicyKit/policy/

%clean
rm -rf $RPM_BUILD_ROOT

%post
#
# granting all permissions for root
#
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null ||:
/usr/sbin/grantwebyastrights --user %{webyast_ws_user} --action grant > /dev/null ||:

# grant the permission for the webservice user
polkit-auth --user %{webyast_ws_user} --grant org.freedesktop.packagekit.system-sources-configure >& /dev/null || true

%files
%defattr(-,root,root)
%dir %{webyast_ws_dir}
%dir %{webyast_ws_dir}/vendor
%dir %{webyast_ws_dir}/vendor/plugins
%dir %{plugin_dir}
%dir /usr/share/PolicyKit
%dir /usr/share/PolicyKit/policy
%{plugin_dir}/README
%{plugin_dir}/Rakefile
%{plugin_dir}/init.rb
%{plugin_dir}/install.rb
%{plugin_dir}/uninstall.rb
%{plugin_dir}/app
%{plugin_dir}/lib
%{plugin_dir}/scripts
%{plugin_dir}/config
%attr(644,root,root) %config /usr/share/PolicyKit/policy/org.opensuse.yast.system.patches.policy
%attr(644,root,root) %config /usr/share/PolicyKit/policy/org.opensuse.yast.system.packages.policy
%attr(644,root,root) %config /usr/share/PolicyKit/policy/org.opensuse.yast.system.repositories.policy
%doc COPYING

%files testsuite
%defattr(-,root,root)
%{plugin_dir}/test

%changelog
