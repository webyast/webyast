#
# spec file for package webyast-mail-ws
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           webyast-mail-ws
Provides:       WebYaST(org.opensuse.yast.modules.yapi.mailsettings)
Provides:       yast2-webservice-mailsettings = %{version}
Obsoletes:      yast2-webservice-mailsettings < %{version}
PreReq:         yast2-webservice rubygem-gettext_rails
License:	GPL v2 only
Group:          Productivity/Networking/Web/Utilities
Autoreqprov:    on
Version:        0.1.19
Release:        0
Summary:        WebYaST - system mail settings service
Source:         www.tar.bz2
Source1:        MailSettings.pm
Source2:	org.opensuse.yast.modules.yapi.mailsettings.policy
Source3:        postfix-update-hostname
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
BuildRequires:  rubygem-yast2-webservice-tasks rubygem-restility

BuildRequires:  webyast-base-ws-testsuite rubygem-gettext_rails
BuildRequires:	rubygem-test-unit rubygem-mocha

# install these packages into Hudson chroot environment
# the exact versions are checked in checks.rake task
%if 0
BuildRequires:  yast2 yast2-mail
%endif

Requires:	postfix mailx

# Mail.ycp
%if 0%{?suse_version} == 0 || 0%{?suse_version} >= 1120
# openSUSE11.2, Factory
Requires:       yast2-mail >= 2.18.3
%else
# SLE11SP1
Requires:       yast2-mail >= 2.17.5
%endif

#
%define plugin_name mail
%define plugin_dir %{webyast_ws_dir}/vendor/plugins/%{plugin_name}
#

%package testsuite
Group:    Productivity/Networking/Web/Utilities
Requires: %{name} = %{version}
Requires: webyast-base-ws-testsuite
Summary:  Testsuite for webyast-mail-ws package

%description
WebYaST - Plugin provides REST based interface to system mail settings.
It does not provide mail server configuration, just redirecting of system mails.

Authors:
--------
    Jiri Suchomel <jsuchome@novell.com>

%description testsuite
This package contains complete testsuite for webyast-mail-ws webservice package.
It's only needed for verifying the functionality of the module and it's not
needed at runtime.

%prep
%setup -q -n www

%build
# build restdoc documentation
mkdir -p public/mail/restdoc
%webyast_ws_restdoc

# do not package restdoc sources
rm -rf restdoc

export RAILS_PARENT=%{webyast_ws_dir}
env LANG=en rake makemo

%check
# run the testsuite
%webyast_ws_check

%install

#
# Install all web and frontend parts.
#
mkdir -p $RPM_BUILD_ROOT%{webyast_ws_vardir}%{plugin_name}
mkdir -p $RPM_BUILD_ROOT%{plugin_dir}
cp -a * $RPM_BUILD_ROOT%{plugin_dir}
rm -f $RPM_BUILD_ROOT%{plugin_dir}/COPYING

# Policies
mkdir -p $RPM_BUILD_ROOT/usr/share/PolicyKit/policy
install -m 0644 %SOURCE2 $RPM_BUILD_ROOT/usr/share/PolicyKit/policy/

#YaPI
mkdir -p $RPM_BUILD_ROOT/usr/share/YaST2/modules/YaPI/
cp %{SOURCE1} $RPM_BUILD_ROOT/usr/share/YaST2/modules/YaPI/

#hook script
mkdir -p $RPM_BUILD_ROOT/etc/sysconfig/network/scripts/
install -m 0755 %SOURCE3 $RPM_BUILD_ROOT/etc/sysconfig/network/scripts/

# remove .po files (no longer needed)
rm -rf $RPM_BUILD_ROOT/%{plugin_dir}/po

# search locale files
%find_lang webyast-mail-ws

%clean
rm -rf $RPM_BUILD_ROOT

%post
# granting all permissions for the web user
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null ||:
/usr/sbin/grantwebyastrights --user %{webyast_ws_user} --action grant > /dev/null ||:

%postun

%files -f webyast-mail-ws.lang
%defattr(-,root,root)
%dir %{webyast_ws_dir}
%dir %{webyast_ws_dir}/vendor
%dir %{webyast_ws_dir}/vendor/plugins
%dir %{plugin_dir}
# YaPI dir
%dir /usr/share/YaST2/
%dir /usr/share/YaST2/modules/
%dir /usr/share/YaST2/modules/YaPI/
#var dir to store mail test status
%dir %attr (-,%{webyast_ws_user},root) %{webyast_ws_vardir}
%dir %attr (-,%{webyast_ws_user},root) %{webyast_ws_vardir}/%{plugin_name}
%dir %{plugin_dir}/locale
%{plugin_dir}/README
%{plugin_dir}/Rakefile
%{plugin_dir}/init.rb
%{plugin_dir}/install.rb
%{plugin_dir}/uninstall.rb
%{plugin_dir}/app
%{plugin_dir}/config
%{plugin_dir}/doc
%{plugin_dir}/public
/usr/share/YaST2/modules/YaPI/MailSettings.pm
/etc/sysconfig/network/scripts/postfix-update-hostname
%dir /usr/share/PolicyKit
%dir /usr/share/PolicyKit/policy
%attr(644,root,root) %config /usr/share/PolicyKit/policy/org.opensuse.yast.modules.yapi.mailsettings.policy
%doc COPYING

%files testsuite
%defattr(-,root,root)
%{plugin_dir}/test

%changelog
