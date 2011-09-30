#
# spec file for package webyast-software (Version 0.1.x)
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           webyast-software
Provides:       WebYaST(org.opensuse.yast.system.repositories)
Provides:       WebYaST(org.opensuse.yast.system.patches)
Provides:       WebYaST(org.opensuse.yast.system.packages)
Provides:       yast2-webservice-patches = %{version}
Obsoletes:      yast2-webservice-patches < %{version}

# for testing
BuildRequires:  ruby-dbus >= 0.3.1

PreReq:         yast2-webservice
# ruby-dbus is required by webyast-base already
# but here we use a recent feature of on_signal
Requires:       ruby-dbus >= 0.3.1

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

License:	GPL-2.0
Group:          Productivity/Networking/Web/Utilities
URL:            http://en.opensuse.org/Portal:WebYaST
Autoreqprov:    on
Version:        0.3.12
Release:        0
Summary:        WebYaST - software management 
Source:         www.tar.bz2
Source1:        org.opensuse.yast.system.patches.policy
Source2:        org.opensuse.yast.system.packages.policy
Source3:        org.opensuse.yast.system.repositories.policy
Source4:	01-org.opensuse.yast.software.pkla
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch

BuildRequires:  webyast-base-testsuite
BuildRequires:	rubygem-test-unit rubygem-mocha

#
%define plugin_dir %{webyast_dir}/vendor/plugins/software
#

%package testsuite
Group:    Productivity/Networking/Web/Utilities
Requires: %{name} = %{version}
Requires: webyast-base-testsuite
Summary:  Testsuite for webyast-software package

%description
WebYaST - Plugin providing REST based interface to handle repositories, patches and packages.

Authors:
--------
    Stefan Schubert <schubi@opensuse.org>

%description testsuite
This package contains complete testsuite for webyast-software package.
It's only needed for verifying the functionality of the module and it's not
needed at runtime.

%prep
%setup -q -n www

%build

#do not package developer doc
rm -rf doc

export RAILS_PARENT=%{webyast_dir}
env LANG=en rake makemo

%check
# run the testsuite
#
# Disabled for now.
# PackageKit/DBus need /proc and thus don't run in build environment.
# But both are required for testing :-/
# reference: bnc#597868
# -percent-webyast_check

%install

#
# Install all web and frontend parts.
#
mkdir -p $RPM_BUILD_ROOT%{plugin_dir}
cp -a * $RPM_BUILD_ROOT%{plugin_dir}
rm -f $RPM_BUILD_ROOT%{plugin_dir}/COPYING

# remove .po files (no longer needed)
rm -rf $RPM_BUILD_ROOT/%{plugin_dir}/po

# search locale files
%find_lang webyast-software

# Policies
mkdir -p $RPM_BUILD_ROOT/usr/share/polkit-1/actions
install -m 0644 %SOURCE1 $RPM_BUILD_ROOT/usr/share/polkit-1/actions/
install -m 0644 %SOURCE2 $RPM_BUILD_ROOT/usr/share/polkit-1/actions/
install -m 0644 %SOURCE3 $RPM_BUILD_ROOT/usr/share/polkit-1/actions/

%if 0%{?suse_version} == 0 || 0%{?suse_version} > 1130
# openSUSE-11.4 has policykit-1 which uses .pkla files
mkdir -p $RPM_BUILD_ROOT/var/lib/polkit-1/localauthority/10-vendor.d
install -m 0644 %SOURCE4 $RPM_BUILD_ROOT/var/lib/polkit-1/localauthority/10-vendor.d/
%if 0%{?suse_version} == 1130
# openSUSE-11.3+ has policykit-1 which uses .pkla files
mkdir -p $RPM_BUILD_ROOT/etc/polkit-1/localauthority/10-vendor.d
install -m 0644 %SOURCE4 $RPM_BUILD_ROOT/etc/polkit-1/localauthority/10-vendor.d/
%endif
%endif

mkdir -p $RPM_BUILD_ROOT/var/lib/webyast/software/licenses/accepted

%clean
rm -rf $RPM_BUILD_ROOT

%post
#
# granting all permissions for root
#
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null ||:
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant > /dev/null ||:


# grant the permission for the webyast user
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant --policy org.freedesktop.packagekit.system-sources-configure >& /dev/null || true
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant --policy org.freedesktop.packagekit.system-update >& /dev/null || true
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant --policy org.freedesktop.packagekit.package-eula-accept >& /dev/null || true

%files -f webyast-software.lang
%defattr(-,root,root)
%dir %{webyast_dir}
%dir %{webyast_dir}/vendor
%dir %{webyast_dir}/vendor/plugins
%dir %{plugin_dir}
%dir /usr/share/polkit-1
%dir /usr/share/polkit-1/actions
%{plugin_dir}/README
%{plugin_dir}/Rakefile
%{plugin_dir}/init.rb
%{plugin_dir}/install.rb
%{plugin_dir}/uninstall.rb
%{plugin_dir}/app
%{plugin_dir}/lib
%{plugin_dir}/config
%{plugin_dir}/locale
%{plugin_dir}/shortcuts.yml
%attr(644,root,root) %config /usr/share/polkit-1/actions/org.opensuse.yast.system.patches.policy
%attr(644,root,root) %config /usr/share/polkit-1/actions/org.opensuse.yast.system.packages.policy
%attr(644,root,root) %config /usr/share/polkit-1/actions/org.opensuse.yast.system.repositories.policy
%attr(775,%{webyast_user},root) /var/lib/webyast/software
%doc COPYING
%if 0%{?suse_version} == 0 || 0%{?suse_version} > 1130
%dir /var/lib/polkit-1/localauthority
%dir /var/lib/polkit-1/localauthority/10-vendor.d
%config /var/lib/polkit-1/localauthority/10-vendor.d/*
%if 0%{?suse_version} == 1130
%config /etc/polkit-1/localauthority/10-vendor.d/*
%endif
%endif

%files testsuite
%defattr(-,root,root)
%{plugin_dir}/test

%changelog
