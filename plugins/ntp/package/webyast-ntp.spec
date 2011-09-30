#
# spec file for package webyast-ntp
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           webyast-ntp
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
Summary:        WebYaST - NTP 
Source:         www.tar.bz2
Source1:        NTP.pm
Source2:        org.opensuse.yast.modules.yapi.ntp.policy
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
BuildRequires:  rubygem-webyast-rake-tasks rubygem-restility

BuildRequires:  webyast-base-testsuite
BuildRequires:	rubygem-test-unit rubygem-mocha

#
%define plugin_dir %{webyast_dir}/vendor/plugins/ntp
#

%package testsuite
Group:    Productivity/Networking/Web/Utilities
Requires: %{name} = %{version}
Requires: webyast-base-testsuite
Summary:  Testsuite for webyast-ntp package

%description
WebYaST - Plugin providing REST based interface to basic ntp time synchronization

Authors:
--------
    Josef Reidinger <jreidinger@novell.com>

%description testsuite
This package contains complete testsuite for webyast-ntp package.
It's only needed for verifying the functionality of the module and it's not
needed at runtime.

%prep
%setup -q -n www

%build
# build restdoc documentation
mkdir -p public/ntp/restdoc
%webyast_restdoc

# do not package restdoc sources
rm -rf restdoc
#do not package development documentation
rm -rf doc

%check
# run the testsuite
%webyast_check

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
mkdir -p $RPM_BUILD_ROOT/usr/share/polkit-1/actions/
cp %{SOURCE2} $RPM_BUILD_ROOT/usr/share/polkit-1/actions/

%clean
rm -rf $RPM_BUILD_ROOT

%post
# granting all permissions for the webservice user and root
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant > /dev/null

%postun

%files 
%defattr(-,root,root)
%dir %{webyast_dir}
%dir %{webyast_dir}/vendor
%dir %{webyast_dir}/vendor/plugins
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
%attr(644,root,root) /usr/share/polkit-1/actions/org.opensuse.yast.modules.yapi.ntp.policy
%doc COPYING

%files testsuite
%defattr(-,root,root)
%{plugin_dir}/test

%changelog
