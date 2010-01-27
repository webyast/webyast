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
Provides:       yast2-webservice-mailsettings = %{version}
Obsoletes:      yast2-webservice-mailsettings < %{version}
PreReq:         yast2-webservice
License:	GPL v2 only
Group:          Productivity/Networking/Web/Utilities
Autoreqprov:    on
Version:        0.1.1
Release:        0
Summary:        YaST2 - Webservice - Mail Settings
Source:         www.tar.bz2
Source1:        MailSettings.pm
Source2:	org.opensuse.yast.modules.yapi.mailsettings.policy
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
BuildRequires:  rubygem-yast2-webservice-tasks rubygem-restility

# install these packages into Hudson chroot environment
# the exact versions are checked in checks.rake task
%if 0
BuildRequires:  yast2 yast2-mail
%endif

Requires:	postfix

# Mail.ycp
%if 0%{?suse_version} == 0 || %suse_version > 1110
# 11.2 or newer
Requires:       yast2-mail >= 2.18.4
%else
# 11.1 or SLES11
Requires:       yast2-mail >= 2.17.4
%endif

#
%define pkg_user yastws
%define plugin_name mailsettings
#


%description
YaST2 - Webservice - REST based interface for mail settings

Authors:
--------
    Jiri Suchomel <jsuchome@novell.com>

%prep
%setup -q -n www

%build
# build restdoc documentation
mkdir -p public/mail_settings/restdoc
export RAILS_PARENT=/srv/www/yastws
env LANG=en rake restdoc

# do not package restdoc sources
rm -rf restdoc

%install

#
# Install all web and frontend parts.
#
mkdir -p $RPM_BUILD_ROOT/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
cp -a * $RPM_BUILD_ROOT/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
rm -f $RPM_BUILD_ROOT/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/COPYING

# Policies
mkdir -p $RPM_BUILD_ROOT/usr/share/PolicyKit/policy
install -m 0644 %SOURCE2 $RPM_BUILD_ROOT/usr/share/PolicyKit/policy/

#YaPI
mkdir -p $RPM_BUILD_ROOT/usr/share/YaST2/modules/YaPI/
cp %{SOURCE1} $RPM_BUILD_ROOT/usr/share/YaST2/modules/YaPI/

%clean
rm -rf $RPM_BUILD_ROOT

%post
# granting all permissions for the web user
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null
/usr/sbin/grantwebyastrights --user yastws --action grant > /dev/null

%postun

%files 
%defattr(-,root,root)
%dir /srv/www/%{pkg_user}
%dir /srv/www/%{pkg_user}/vendor
%dir /srv/www/%{pkg_user}/vendor/plugins
%dir /srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}
%dir /usr/share/YaST2/
%dir /usr/share/YaST2/modules/
%dir /usr/share/YaST2/modules/YaPI/
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/README
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/Rakefile
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/init.rb
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/install.rb
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/uninstall.rb
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/app
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/config
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/doc
/srv/www/%{pkg_user}/vendor/plugins/%{plugin_name}/public
/usr/share/YaST2/modules/YaPI/MailSettings.pm
%dir /usr/share/PolicyKit
%dir /usr/share/PolicyKit/policy
%attr(644,root,root) %config /usr/share/PolicyKit/policy/org.opensuse.yast.modules.yapi.%{plugin_name}.policy
%doc COPYING

%changelog
