#
# spec file for package webyast-kerberos
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           webyast-kerberos
Provides:       WebYaST(org.opensuse.yast.modules.yapi.kerberos)
Provides:       webyast-kerberos-ws = 0.2.9 webyast-kerberos-ui = 0.2.10
Obsoletes:      webyast-kerberos-ws <= 0.2.9 webyast-kerberos-ui <= 0.2.10
PreReq:         webyast-base
License:        GPL-2.0	
Group:          Productivity/Networking/Web/Utilities
URL:            http://en.opensuse.org/Portal:WebYaST
Autoreqprov:    on
Version:        0.3.0
Release:        0
Summary:        WebYaST - configuration of Kerberos client
Source:         www.tar.bz2
Source1:	org.opensuse.yast.modules.yapi.kerberos.policy
Source2:	KERBEROS.pm
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
BuildRequires:  rubygem-webyast-tasks rubygem-restility
BuildRequires:  webyast-base-testsuite
BuildRequires:	rubygem-test-unit rubygem-mocha

# KERBEROS.pm is using yast2-kerberos-client API
Requires:	yast2-kerberos-client krb5 pam_krb5 krb5-client
# reasonable PATH set (bnc#617442) 
Requires:       yast2-dbus-server >= 2.17.3

#
%define plugin_name kerberos
%define plugin_dir %{webyast_dir}/vendor/plugins/%{plugin_name}
#

%package testsuite
Group:     Productivity/Networking/Web/Utilities
Requires:  %{name} = %{version}
Requires:  webyast-base-testsuite
Provides:  webyast-kerberos-ws-testsuite = 0.2.9 webyast-kerberos-ui-testsuite = 0.2.10
Obsoletes: webyast-kerberos-ws-testsuite <= 0.2.9 webyast-kerberos-ui-testsuite <= 0.2.10
Summary:   Testsuite for webyast-kerberos package

%description
WebYaST - Plugin for configuration of Kerberos client

Authors:
--------
    Jiri Suchomel <jsuchome@novell.com>

%description testsuite
This package contains complete testsuite for webyast-kerberos package.
It's only needed for verifying the functionality of the module and it's not
needed at runtime.

%prep
%setup -q -n www

%build
# build restdoc documentation
mkdir -p public/kerberos/restdoc
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
%find_lang webyast-kerberos

%clean
rm -rf $RPM_BUILD_ROOT

%post
# granting all permissions for the web user
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant > /dev/null

%postun

%files -f webyast-kerberos.lang
%defattr(-,root,root)
%dir %{webyast_dir}
%dir %{webyast_dir}/vendor
%dir %{webyast_dir}/vendor/plugins
%dir %{plugin_dir}
# YaPI dir
%dir /usr/share/YaST2/
%dir /usr/share/YaST2/modules/
%dir /usr/share/YaST2/modules/YaPI/
/usr/share/YaST2/modules/YaPI/KERBEROS.pm
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
%attr(644,root,root) %config /usr/share/polkit-1/actions/org.opensuse.yast.modules.yapi.kerberos.policy
%doc COPYING

%files testsuite
%defattr(-,root,root)
%{webyast_dir}/vendor/plugins/%{plugin_name}/test

%changelog
