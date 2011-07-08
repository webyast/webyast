#
# spec file for package webyast-ntp-ws
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           webyast-ntp-ws
Provides:       WebYaST(org.opensuse.yast.modules.yapi.ntp)
Provides:       yast2-webservice-ntp = %{version}
Obsoletes:      yast2-webservice-ntp < %{version}
#webservice already require yast2-dbus-server which is needed for yapi
PreReq:         yast2-webservice
#for YaPI needs ntp
Requires:	ntp
#for YaPI hwclock
Requires:	util-linux
License:        GPL-2.0	
Group:          Productivity/Networking/Web/Utilities
URL:            http://en.opensuse.org/Portal:WebYaST
Autoreqprov:    on
Version:        0.2.5
Release:        0
Summary:        WebYaST - NTP service
Source:         www.tar.bz2
Source1:        NTP.pm
Source2:        org.opensuse.yast.modules.yapi.ntp.policy
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
BuildRequires:  rubygem-yast2-webservice-tasks rubygem-restility

BuildRequires:  webyast-base-ws-testsuite
BuildRequires:	rubygem-test-unit rubygem-mocha

#
%define plugin_dir %{webyast_ws_dir}/vendor/plugins/ntp
#

%package testsuite
Group:    Productivity/Networking/Web/Utilities
Requires: %{name} = %{version}
Requires: webyast-base-ws-testsuite
Summary:  Testsuite for webyast-ntp-ws package

%description
WebYaST - Plugin providing REST based interface to basic ntp time synchronization

Authors:
--------
    Josef Reidinger <jreidinger@novell.com>

%description testsuite
This package contains complete testsuite for webyast-ntp-ws webservice package.
It's only needed for verifying the functionality of the module and it's not
needed at runtime.

%prep
%setup -q -n www

%build
# build restdoc documentation
mkdir -p public/ntp/restdoc
%webyast_ws_restdoc

# do not package restdoc sources
rm -rf restdoc
#do not package development documentation
rm -rf doc

%check
# run the testsuite
%webyast_ws_check

%install

#
# Install all web and frontend parts.
#
mkdir -p $RPM_BUILD_ROOT%{plugin_dir}
cp -a * $RPM_BUILD_ROOT%{plugin_dir}
rm -f $RPM_BUILD_ROOT%{plugin_dir}/COPYING
#YaPI module
mkdir -p $RPM_BUILD_ROOT/usr/share/YaST2/modules/YaPI/
cp %{SOURCE1} $RPM_BUILD_ROOT/usr/share/YaST2/modules/YaPI/
#policies
mkdir -p $RPM_BUILD_ROOT/usr/share/PolicyKit/policy/
cp %{SOURCE2} $RPM_BUILD_ROOT/usr/share/PolicyKit/policy/

%clean
rm -rf $RPM_BUILD_ROOT

%post
# granting all permissions for the webservice user and root
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null
/usr/sbin/grantwebyastrights --user %{webyast_ws_user} --action grant > /dev/null

%postun

%files 
%defattr(-,root,root)
%dir %{webyast_ws_dir}
%dir %{webyast_ws_dir}/vendor
%dir %{webyast_ws_dir}/vendor/plugins
%dir %{plugin_dir}
# ntp require only yast2-dbus server, so it must ensure that directory exist
%dir /usr/share/YaST2/
%dir /usr/share/YaST2/modules/
%dir /usr/share/YaST2/modules/YaPI/
%{plugin_dir}/README
%{plugin_dir}/Rakefile
%{plugin_dir}/init.rb
%{plugin_dir}/install.rb
%{plugin_dir}/uninstall.rb
%{plugin_dir}/app
%{plugin_dir}/config
%{plugin_dir}/public
%attr(644,root,root) /usr/share/YaST2/modules/YaPI/NTP.pm
%attr(644,root,root) /usr/share/PolicyKit/policy/org.opensuse.yast.modules.yapi.ntp.policy
%doc COPYING

%files testsuite
%defattr(-,root,root)
%{plugin_dir}/test

%changelog
