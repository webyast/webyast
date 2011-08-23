#
# spec file for package webyast-roles (Version 0.1)
#
# Copyright (c) 2010 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           webyast-roles
Provides:       WebYaST(org.opensuse.yast.roles)
PreReq:         yast2-webservice
License:        GPL-2.0	
Group:          Productivity/Networking/Web/Utilities
URL:            http://en.opensuse.org/Portal:WebYaST
Autoreqprov:    on
Version:        0.2.5
Release:        0
Summary:        WebYaST - role management
Source:         www.tar.bz2
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
Source1:        roles.yml
Source2:        roles_assign.yml

BuildRequires:  webyast-base-testsuite
BuildRequires:	rubygem-test-unit rubygem-mocha

#
%define plugin_name roles
%define plugin_dir %{webyast_dir}/vendor/plugins/%{plugin_name}
#

%package testsuite
Group:    Productivity/Networking/Web/Utilities
Requires: %{name} = %{version}
Requires: webyast-base-testsuite
Summary:  Testsuite for webyast-roles package

%description
WebYaST - Plugin providing REST based interface for roles management.

Authors:
--------
    Josef Reidinger <jreidinger@suse.cz>

%description testsuite
This package contains complete testsuite for webyast-roles package.
It's only needed for verifying the functionality of the module and it's not
needed at runtime.

%prep
%setup -q -n www

%build
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

mkdir -p $RPM_BUILD_ROOT%{webyast_vardir}/roles
cp %{SOURCE1} %{SOURCE2} $RPM_BUILD_ROOT%{webyast_vardir}/roles

# remove .po files (no longer needed)
rm -rf $RPM_BUILD_ROOT/%{plugin_dir}/po

# search locale files
%find_lang webyast-roles


%clean
rm -rf $RPM_BUILD_ROOT

%post
#
# granting all permissions for root 
#
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null
# XXX not nice to get webyast all permissions, but now not better solution
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant > /dev/null

%files -f webyast-roles.lang
%defattr(-,root,root)
%dir %{webyast_dir}
%dir %{webyast_dir}/vendor
%dir %{webyast_dir}/vendor/plugins
%dir %{plugin_dir}
%dir %{plugin_dir}/doc

%{plugin_dir}/locale
%{plugin_dir}/README
%{plugin_dir}/shortcuts.yml
%{plugin_dir}/Rakefile
%{plugin_dir}/init.rb
%{plugin_dir}/install.rb
%{plugin_dir}/uninstall.rb
%{plugin_dir}/app
%{plugin_dir}/config
%{plugin_dir}/lib
%{plugin_dir}/doc/README_FOR_APP
%attr(0700,%{webyast_user},%{webyast_user}) %dir %{webyast_vardir}/roles
%attr(0600,%{webyast_user},%{webyast_user}) %config %{webyast_vardir}/roles/*

%doc COPYING

%files testsuite
%defattr(-,root,root)
%{plugin_dir}/test

%changelog
