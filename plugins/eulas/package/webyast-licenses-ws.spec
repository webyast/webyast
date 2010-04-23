#
# spec file for package yast2-webservice-eula (Version 0.0.1)
#
# Copyright (c) 2008-09 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           webyast-licenses-ws
Provides:       WebYaST(org.opensuse.yast.modules.eulas)
Provides:       yast2-webservice-eulas = %{version}
Obsoletes:      yast2-webservice-eulas < %{version}
PreReq:         yast2-webservice
License:	GPL v2 only
Group:          Productivity/Networking/Web/Utilities
Autoreqprov:    on
Version:        0.1.0
Release:        0
Summary:        WebYaST - license management service
Source:         www.tar.bz2
Source1:        eulas-sles11.yml
Source2:        org.opensuse.yast.modules.eulas.policy
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch

BuildRequires:  webyast-base-ws-testsuite
BuildRequires:	rubygem-test-unit rubygem-mocha

#
%define pkg_user yastws
%define plugin_name eulas
#

%package testsuite
Group:    Productivity/Networking/Web/Utilities
Requires: %{name} = %{version}
Requires: webyast-base-ws-testsuite
Summary:  Testsuite for webyast-licenses-ws package

%description
WebYaST - Plugin providing REST based interface to handle user acceptation of EULAs.

Authors:
--------
    Martin Kudlvasr <mkudlvasr@suse.cz>
    Josef Reidinger <jreidinger@suse.cz>

%description testsuite
This package contains complete testsuite for webyast-licenses-ws webservice package.
It's only needed for verifying the functionality of the module and it's not
needed at runtime.

%prep
%setup -q -n www

%build

%check
# run the testsuite
%webyast_ws_check

%post
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null
/usr/sbin/grantwebyastrights --user yastws --action grant > /dev/null

%install

#
# Install all web and frontend parts.
#
mkdir -p $RPM_BUILD_ROOT/usr/share/%{pkg_user}/%{plugin_name}
rm -r "config/resources/licenses/openSUSE-11.1"
mv config/resources/licenses $RPM_BUILD_ROOT/usr/share/%{pkg_user}/%{plugin_name}/

mkdir -p $RPM_BUILD_ROOT/var/lib/%{pkg_user}/%{plugin_name}/accepted-licenses

mkdir -p $RPM_BUILD_ROOT/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
cp -a * $RPM_BUILD_ROOT/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
rm -f $RPM_BUILD_ROOT/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/COPYING
#FIXME maybe location change in future

mkdir -p $RPM_BUILD_ROOT/etc/webyast/
cp %SOURCE1 $RPM_BUILD_ROOT/etc/webyast/eulas.yml

mkdir -p $RPM_BUILD_ROOT/usr/share/PolicyKit/policy
cp %{SOURCE2} $RPM_BUILD_ROOT/usr/share/PolicyKit/policy/

%clean
rm -rf $RPM_BUILD_ROOT


%files 
%defattr(-,root,root)
%dir /srv/www/%{pkg_user}
%dir /srv/www/%{pkg_user}/vendor
%dir /srv/www/%{pkg_user}/vendor/plugins
%dir /srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
%dir /srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/doc
%dir /usr/share/%{pkg_user}
%dir /usr/share/%{pkg_user}/%{plugin_name}
%dir /var/lib/%{pkg_user}
%dir /var/lib/%{pkg_user}/%{plugin_name}
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/README
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/Rakefile
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/init.rb
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/install.rb
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/uninstall.rb
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/app
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/config
#/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/tasks
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/doc/README_FOR_APP
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/doc/eulas_example.yml
/usr/share/%{pkg_user}/%{plugin_name}/licenses
%dir /etc/webyast/
%config /etc/webyast/eulas.yml
%defattr(-,%{pkg_user},%{pkg_user})
%dir /var/lib/%{pkg_user}/%{plugin_name}/accepted-licenses
/usr/share/PolicyKit/policy/org.opensuse.yast.modules.eulas.policy
%doc COPYING

%files testsuite
%defattr(-,root,root)
%{webyast_ws_dir}/vendor/plugins/%{plugin_name}/test

%changelog
