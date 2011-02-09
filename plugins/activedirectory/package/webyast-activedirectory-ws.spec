#
# spec file for package webyast-activedirectory-ws
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           webyast-activedirectory-ws
Provides:       WebYaST(org.opensuse.yast.modules.yapi.activedirectory)
PreReq:         webyast-base-ws
License:	GPL v2 only
Group:          Productivity/Networking/Web/Utilities
URL:            http://en.opensuse.org/Portal:WebYaST
Autoreqprov:    on
Version:        0.2.7
Release:        0
Summary:        WebYaST - service for configuration of Active Directory client
Source:         www.tar.bz2
Source1:	org.opensuse.yast.modules.yapi.activedirectory.policy
Source2:	ActiveDirectory.pm
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
BuildRequires:  rubygem-yast2-webservice-tasks rubygem-restility

BuildRequires:  webyast-base-ws-testsuite
BuildRequires:	rubygem-test-unit rubygem-mocha

# for enabling winbind and Kerberos configuration
Requires:	samba-winbind samba-client pam_mount yast2-kerberos-client krb5 krb5-client
# for dig
Requires:	bind-utils
# reasonable PATH set (bnc#617442)
Requires:       yast2-dbus-server >= 2.17.3


# ActiveDirectory.pm is using yast2-samba-client API
# specific versin for SambaAD::SetRealm
Requires:	yast2-samba-client >= 2.17.18

#
%define plugin_name activedirectory
%define plugin_dir %{webyast_ws_dir}/vendor/plugins/%{plugin_name}
#

%package testsuite
Group:    Productivity/Networking/Web/Utilities
Requires: %{name} = %{version}
Requires: webyast-base-ws-testsuite
Summary:  Testsuite for webyast-activedirectory-ws package

%description
WebYaST - Plugin providing REST service for configuration of Active Directory client

Authors:
--------
    Jiri Suchomel <jsuchome@novell.com>

%description testsuite
This package contains complete testsuite for webyast-activedirectory-ws webservice package.
It's only needed for verifying the functionality of the module and it's not
needed at runtime.

%prep
%setup -q -n www

%build
# build restdoc documentation
mkdir -p public/activedirectory/restdoc
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

#YaPI
mkdir -p $RPM_BUILD_ROOT/usr/share/YaST2/modules/YaPI/
cp %{SOURCE2} $RPM_BUILD_ROOT/usr/share/YaST2/modules/YaPI/

%clean
rm -rf $RPM_BUILD_ROOT

%post
# granting all permissions for the web user
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null
/usr/sbin/grantwebyastrights --user %{webyast_ws_user} --action grant > /dev/null

%postun

%files 
%defattr(-,root,root)
%dir %{webyast_ws_dir}
%dir %{webyast_ws_dir}/vendor
%dir %{webyast_ws_dir}/vendor/plugins
%dir %{plugin_dir}
# YaPI dir
%dir /usr/share/YaST2/
%dir /usr/share/YaST2/modules/
%dir /usr/share/YaST2/modules/YaPI/
/usr/share/YaST2/modules/YaPI/ActiveDirectory.pm
%{plugin_dir}/README
%{plugin_dir}/Rakefile
%{plugin_dir}/init.rb
%{plugin_dir}/install.rb
%{plugin_dir}/uninstall.rb
%{plugin_dir}/app
%{plugin_dir}/config
%{plugin_dir}/doc
%{plugin_dir}/public
%dir /usr/share/PolicyKit
%dir /usr/share/PolicyKit/policy
%attr(644,root,root) %config /usr/share/PolicyKit/policy/org.opensuse.yast.modules.yapi.activedirectory.policy
%doc COPYING

%files testsuite
%defattr(-,root,root)
%{webyast_ws_dir}/vendor/plugins/%{plugin_name}/test

%changelog
