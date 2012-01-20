#
# spec file for package webyast-root-user
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           webyast-root-user
Provides:       WebYaST(org.opensuse.yast.modules.yapi.administrator)
Provides:       yast2-webservice-administrator = %{version}
Obsoletes:      yast2-webservice-administrator < %{version}
PreReq:         yast2-webservice
License:        GPL-2.0	
Group:          Productivity/Networking/Web/Utilities
URL:            http://en.opensuse.org/Portal:WebYaST
Autoreqprov:    on
Version:        0.2.4
Release:        0
Summary:        WebYaST - configuration of root account
Source:         www.tar.bz2
Source1:	org.opensuse.yast.modules.yapi.administrator.policy
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
BuildRequires:  rubygem-webyast-rake-tasks rubygem-restility

BuildRequires:  webyast-base-testsuite
BuildRequires:	rubygem-test-unit rubygem-mocha

# requires YaPI::USERS
%if 0%{?suse_version} == 0 || %suse_version > 1110
# 11.2 or newer
Requires:       yast2-users >= 2.18.13
%else
# 11.1 or SLES11
Requires:       yast2-users >= 2.17.28.1
%endif

#
%define plugin_name administrator
%define plugin_dir %{webyast_dir}/vendor/plugins/%{plugin_name}
#

%package testsuite
Group:    Productivity/Networking/Web/Utilities
Requires: %{name} = %{version}
Requires: webyast-base-testsuite
Summary:  Testsuite for webyast-root-user package

%description
WebYaST - Plugin for configuration of root user account

Authors:
--------
    Jiri Suchomel <jsuchome@novell.com>

%description testsuite
This package contains complete testsuite for webyast-root package.
It's only needed for verifying the functionality of the module and it's not
needed at runtime.

%prep
%setup -q -n www

%build
# build restdoc documentation
mkdir -p public/administrator/restdoc
%webyast_restdoc

# do not package restdoc sources
rm -rf restdoc

export RAILS_PARENT=%{webyast_dir}
export LANG=en
rake gettext:pack

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
mkdir -p $RPM_BUILD_ROOT/usr/share/polkit-1/actions
install -m 0644 %SOURCE1 $RPM_BUILD_ROOT/usr/share/polkit-1/actions/

# remove .po files (no longer needed)
rm -rf $RPM_BUILD_ROOT/%{plugin_dir}/locale/*/*.po

# search locale files
%find_lang webyast-root-user


%clean
rm -rf $RPM_BUILD_ROOT

%post
# granting all permissions for the web user
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant > /dev/null

%postun

%files -f webyast-root-user.lang
%defattr(-,root,root)
%dir %{webyast_dir}
%dir %{webyast_dir}/vendor
%dir %{webyast_dir}/vendor/plugins
%dir %{plugin_dir}

%{plugin_dir}/locale
%{plugin_dir}/README
%{plugin_dir}/Rakefile
%{plugin_dir}/shortcuts.yml
%{plugin_dir}/init.rb
%{plugin_dir}/install.rb
%{plugin_dir}/uninstall.rb
%{plugin_dir}/app
%{plugin_dir}/config
%{plugin_dir}/doc
%{plugin_dir}/public
%dir /usr/share/polkit-1
%dir /usr/share/polkit-1/actions
%attr(644,root,root) %config /usr/share/polkit-1/actions/org.opensuse.yast.modules.yapi.administrator.policy
%doc COPYING

%files testsuite
%defattr(-,root,root)
%{webyast_dir}/vendor/plugins/%{plugin_name}/test

%changelog
