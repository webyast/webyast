#
# spec file for package webyast-services (Version 0.1)
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           webyast-services
Provides:       WebYaST(org.opensuse.yast.modules.yapi.services)
Provides:       yast2-webservice-services = %{version}
Obsoletes:      yast2-webservice-services < %{version}
PreReq:         yast2-webservice
License:        GPL-2.0	
Group:          Productivity/Networking/Web/Utilities
URL:            http://en.opensuse.org/Portal:WebYaST
Autoreqprov:    on
Version:        0.2.11
Release:        0
Summary:        WebYaST - system services management service
Source:         www.tar.bz2
Source1:        org.opensuse.yast.modules.yapi.services.policy
Source2:	YML.rb
Source3:	filter_services.yml
Source4:	SERVICES.pm
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
BuildRequires:  rubygem-webyast-rake-tasks rubygem-restility

BuildRequires:  webyast-base-testsuite
BuildRequires:  tidy rubygem-test-unit rubygem-mocha

# so SERVICES.pm is able to call YML.rb
Requires:       yast2-ruby-bindings >= 0.3.2.1
# for SERVICES.pm
Requires:	yast2-runlevel

#
%define plugin_name services
%define plugin_dir %{webyast_dir}/vendor/plugins/%{plugin_name}
#

%package testsuite
Group:    Productivity/Networking/Web/Utilities
Requires: %{name} = %{version}
Requires: webyast-base-testsuite
Summary:  Testsuite for webyast-services package

%description
WebYaST - Plugin providing REST based interface to handle system services.
Authors:
--------
    Stefan Schubert <schubi@opensuse.org>
    Jiri Suchomel <jsuchome@suse.cz>
    Ladislav Slezak <lslezak@suse.cz>

%description testsuite
This package contains complete testsuite for webyast-services package.
It's only needed for verifying the functionality of the module and it's not
needed at runtime.

%prep
%setup -q -n www

%build

# build restdoc documentation
mkdir -p public/services/restdoc
%webyast_restdoc

# do not package restdoc sources
rm -rf restdoc

export RAILS_PARENT=%{webyast_dir}
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

# YML.rb
mkdir -p $RPM_BUILD_ROOT/usr/share/YaST2/modules/
cp %{SOURCE2} $RPM_BUILD_ROOT/usr/share/YaST2/modules/

# SERVICES.pm
mkdir -p $RPM_BUILD_ROOT/usr/share/YaST2/modules/YaPI/
cp %{SOURCE4} $RPM_BUILD_ROOT/usr/share/YaST2/modules/YaPI/

# copy example filter_services.yml
mkdir -p $RPM_BUILD_ROOT/etc/webyast/
cp %SOURCE3 $RPM_BUILD_ROOT/etc/webyast/

# remove .po files (no longer needed)
rm -rf $RPM_BUILD_ROOT/%{plugin_dir}/po

# search locale files
%find_lang webyast-services

%clean
rm -rf $RPM_BUILD_ROOT

%post
#
# granting all permissions for root 
#
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null ||:
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant > /dev/null ||:

%files -f webyast-services.lang 
%defattr(-,root,root)
%dir %{webyast_dir}
%dir %{webyast_dir}/vendor
%dir %{webyast_dir}/vendor/plugins
%dir %{plugin_dir}
%dir %{plugin_dir}/doc

%dir /usr/share/YaST2/
%dir /usr/share/YaST2/modules/
%dir /usr/share/YaST2/modules/YaPI/

%dir /usr/share/PolicyKit
%dir /usr/share/PolicyKit/policy

%dir /etc/webyast/
%config /etc/webyast/filter_services.yml

%{plugin_dir}/locale
%{plugin_dir}/README
%{plugin_dir}/shortcuts.yml
%{plugin_dir}/Rakefile
%{plugin_dir}/init.rb
%{plugin_dir}/install.rb
%{plugin_dir}/uninstall.rb
%{plugin_dir}/app
%{plugin_dir}/config
%{plugin_dir}/public
%{plugin_dir}/doc
%{plugin_dir}/lib

/usr/share/YaST2/modules/YML.rb
/usr/share/YaST2/modules/YaPI/SERVICES.pm

%attr(644,root,root) %config /usr/share/PolicyKit/policy/org.opensuse.yast.modules.yapi.services.policy

%doc COPYING


%files testsuite
%defattr(-,root,root)
%{plugin_dir}/test

%changelog
