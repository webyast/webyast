#
# spec file for package webyast-activedirectory
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           webyast-activedirectory
Provides:       WebYaST(org.opensuse.yast.modules.yapi.activedirectory)
Provides: 	webyast-activedirectory-ws = 0.2.10 webyast-activedirectory-ui = 0.2.13
Obsoletes: 	webyast-activedirectory-ws <= 0.2.10 webyast-activedirectory-ui <= 0.2.13
PreReq:         webyast-base
License:        GPL-2.0	
Group:          Productivity/Networking/Web/Utilities
URL:            http://en.opensuse.org/Portal:WebYaST
Autoreqprov:    on
Version:        0.3.0
Release:        0
Summary:        WebYaST - configuration of Active Directory client
Source:         www.tar.bz2
Source1:        org.opensuse.yast.modules.yapi.activedirectory.policy
Source2:        ActiveDirectory.pm
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
BuildRequires:  rubygem-webyast-rake-tasks rubygem-restility

BuildRequires:  webyast-base-testsuite tidy
BuildRequires:  rubygem-test-unit rubygem-mocha

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
%define plugin_dir %{webyast_dir}/vendor/plugins/%{plugin_name}
#

%package testsuite
Group:    Productivity/Networking/Web/Utilities
Requires: %{name} = %{version}
Requires: webyast-base-testsuite
Provides:  webyast-activedirectory-ws-testsuite = 0.2.10 webyast-activedirectory-ui-testsuite = 0.2.13
Obsoletes: webyast-activedirectory-ws-testsuite <= 0.2.10 webyast-activedirectory-ui-testsuite <= 0.2.13
Summary:  Testsuite for webyast-activedirectory package

%description
WebYaST - Plugin for configuration of Active Directory client

Authors:
--------
    Jiri Suchomel <jsuchome@novell.com>

%description testsuite
This package contains complete testsuite for webyast-activedirectory package.
It's only needed for verifying the functionality of the module and it's not
needed at runtime.

%prep
%setup -q -n www

%build
# build restdoc documentation
mkdir -p public/activedirectory/restdoc
%webyast_restdoc

# do not package restdoc sources
rm -rf restdoc

export RAILS_PARENT=%{webyast_dir}
export LANG=en
rake makemo

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

#YaPI
mkdir -p $RPM_BUILD_ROOT/usr/share/YaST2/modules/YaPI/
cp %{SOURCE2} $RPM_BUILD_ROOT/usr/share/YaST2/modules/YaPI/

# remove .po files (no longer needed)
rm -rf $RPM_BUILD_ROOT/%{plugin_dir}/po

# search locale files
%find_lang webyast-activedirectory

%clean
rm -rf $RPM_BUILD_ROOT

%post
# granting all permissions for the web user
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant > /dev/null

%postun

%files -f webyast-activedirectory.lang
%defattr(-,root,root)
%dir %{webyast_dir}
%dir %{webyast_dir}/vendor
%dir %{webyast_dir}/vendor/plugins
%dir %{plugin_dir}
# YaPI dir
%dir /usr/share/YaST2/
%dir /usr/share/YaST2/modules/
%dir /usr/share/YaST2/modules/YaPI/
/usr/share/YaST2/modules/YaPI/ActiveDirectory.pm
%{plugin_dir}/locale
%{plugin_dir}/README
%{plugin_dir}/Rakefile
%{plugin_dir}/shortcuts.yml
%{plugin_dir}/init.rb
%{plugin_dir}/app
%{plugin_dir}/config
%{plugin_dir}/doc
%{plugin_dir}/public
%dir /usr/share/polkit-1
%dir /usr/share/polkit-1/actions
%attr(644,root,root) %config /usr/share/polkit-1/actions/org.opensuse.yast.modules.yapi.activedirectory.policy
%doc COPYING

%files testsuite
%defattr(-,root,root)
%{webyast_dir}/vendor/plugins/%{plugin_name}/test

%changelog
