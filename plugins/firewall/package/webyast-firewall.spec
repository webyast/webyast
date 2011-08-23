# spec file for package webyast-firewall (Version 0.1)
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           webyast-firewall
Provides:       WebYaST(org.opensuse.yast.modules.yapi.firewall)
License:        GPL-2.0 
Group:          Productivity/Networking/Web/Utilities
URL:            http://en.opensuse.org/Portal:WebYaST
Autoreqprov:    on
Version:        0.2.14
Release:        0
Summary:        WebYaST - Firewall management service
Source:         www.tar.bz2
Source1:        org.opensuse.yast.modules.yapi.firewall.policy
Source2:        FIREWALL.pm
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
BuildRequires:  rubygem-yast2-webservice-tasks rubygem-restility
PreReq:         webyast-base
Requires:       SuSEfirewall2 yast2

BuildRequires:  webyast-base-testsuite
BuildRequires:	rubygem-test-unit rubygem-mocha

#
%define plugin_name firewall
%define plugin_dir %{webyast_dir}/vendor/plugins/%{plugin_name}
#

%package testsuite
Group:    Productivity/Networking/Web/Utilities
Requires: %{name} = %{version}
Requires: webyast-base-testsuite
Summary:  Testsuite for webyast-firewall package

%description
WebYaST - Plugin provides REST based interface to handle firewall settings.
Authors:
--------
    Martin Kudlvasr<mkudlvasr@novell.com>

%description testsuite
This package contains complete testsuite for webyast-firewall package.
It's only needed for verifying the functionality of the module and it's not
needed at runtime.

%prep
%setup -q -n www

%build
# build restdoc documentation
mkdir -p public/firewall/restdoc
%webyast_restdoc

# do not package restdoc sources
rm -rf restdoc
#remove generated doc
rm -rf doc

export RAILS_PARENT=%{webyast_ui_dir}
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

# Policies
mkdir -p $RPM_BUILD_ROOT/usr/share/PolicyKit/policy
install -m 0644 %SOURCE1 $RPM_BUILD_ROOT/usr/share/PolicyKit/policy/

#YaPI
mkdir -p $RPM_BUILD_ROOT/usr/share/YaST2/modules/YaPI/
cp %{SOURCE2} $RPM_BUILD_ROOT/usr/share/YaST2/modules/YaPI/

# remove .po files (no longer needed)
rm -rf $RPM_BUILD_ROOT/%{plugin_dir}/po

# search locale files
%find_lang webyast-firewall

%clean
rm -rf $RPM_BUILD_ROOT

%post
#
# granting all permissions for root
#
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null ||:
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant > /dev/null ||:

%files -f webyast-firewall.lang
%defattr(-,root,root)
%dir %{webyast_dir}
%dir %{webyast_dir}/vendor
%dir %{webyast_dir}/vendor/plugins
%dir %{plugin_dir}

%dir /usr/share/YaST2/
%dir /usr/share/YaST2/modules/
%dir /usr/share/YaST2/modules/YaPI/
%dir /usr/share/PolicyKit
%dir /usr/share/PolicyKit/policy
%{plugin_dir}/locale
%{plugin_dir}/README
%{plugin_dir}/Rakefile
%{plugin_dir}/init.rb
%{plugin_dir}/install.rb
%{plugin_dir}/uninstall.rb
%{plugin_dir}/app
%{plugin_dir}/config
%{plugin_dir}/public
%{plugin_dir}/lib
/usr/share/YaST2/modules/YaPI/FIREWALL.pm
%attr(644,root,root) %config /usr/share/PolicyKit/policy/org.opensuse.yast.modules.yapi.firewall.policy
%doc COPYING

%files testsuite
%defattr(-,root,root)
%{plugin_dir}/test

%changelog
