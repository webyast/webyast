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
URL:            http://en.opensuse.org/Portal:WebYaST
Autoreqprov:    on
Version:        0.2.0
Release:        0
Summary:        WebYaST - license management service
Source:         www.tar.bz2
Source1:        eulas-sles11.yml
Source2:        org.opensuse.yast.modules.eulas.policy
Source3:        eulas-opensuse11_1.yml
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch

BuildRequires:  webyast-base-ws-testsuite
BuildRequires:	rubygem-test-unit rubygem-mocha

#
%define plugin_name eulas
%define plugin_dir %{webyast_ws_dir}/vendor/plugins/%{plugin_name}
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
/usr/sbin/grantwebyastrights --user %{webyast_ws_user} --action grant > /dev/null

%install

#
# Install all web and frontend parts.
#
mkdir -p $RPM_BUILD_ROOT/usr/share/%{webyast_ws_user}/%{plugin_name}
%if 0%{?sles_version} == 0
  # use an openSUSE license by default
  SOURCE_CONFIG=%SOURCE3
  rm -r "config/resources/licenses/SLES-11"
%else
  # use a sles11 license by default
  SOURCE_CONFIG=%SOURCE1
  rm -r "config/resources/licenses/openSUSE-11.1"
%endif
mv config/resources/licenses $RPM_BUILD_ROOT/usr/share/%{webyast_ws_user}/%{plugin_name}/

mkdir -p $RPM_BUILD_ROOT%{webyast_ws_vardir}/%{plugin_name}/accepted-licenses

mkdir -p $RPM_BUILD_ROOT%{plugin_dir}
cp -a * $RPM_BUILD_ROOT%{plugin_dir}/
rm -f $RPM_BUILD_ROOT%{plugin_dir}/COPYING

mkdir -p $RPM_BUILD_ROOT/etc/webyast/
cp $SOURCE_CONFIG $RPM_BUILD_ROOT/etc/webyast/eulas.yml

mkdir -p $RPM_BUILD_ROOT/usr/share/PolicyKit/policy
cp %{SOURCE2} $RPM_BUILD_ROOT/usr/share/PolicyKit/policy/

%clean
rm -rf $RPM_BUILD_ROOT


%files 
%defattr(-,root,root)
%dir %{webyast_ws_dir}
%dir %{webyast_ws_dir}/vendor
%dir %{webyast_ws_dir}/vendor/plugins
%dir %{plugin_dir}
%dir %{plugin_dir}/doc
%dir /usr/share/%{webyast_ws_user}
%dir /usr/share/%{webyast_ws_user}/%{plugin_name}
%dir %{webyast_ws_vardir}
%dir %{webyast_ws_vardir}/%{plugin_name}
%{plugin_dir}/README
%{plugin_dir}/Rakefile
%{plugin_dir}/init.rb
%{plugin_dir}/install.rb
%{plugin_dir}/uninstall.rb
%{plugin_dir}/app
%{plugin_dir}/config
%{plugin_dir}/doc/README_FOR_APP
%{plugin_dir}/doc/eulas_example.yml
/usr/share/%{webyast_ws_user}/%{plugin_name}/licenses
%dir /etc/webyast/
%config /etc/webyast/eulas.yml

%attr(-,%{webyast_ws_user},%{webyast_ws_user}) %dir %{webyast_ws_vardir}/%{plugin_name}/accepted-licenses
/usr/share/PolicyKit/policy/org.opensuse.yast.modules.eulas.policy
%doc COPYING

%files testsuite
%defattr(-,root,root)
%{plugin_dir}/test

%changelog
