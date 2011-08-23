#
# spec file for package webyast-time (Version 0.1)
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           webyast-time
Provides:       WebYaST(org.opensuse.yast.modules.yapi.time)
Provides:       yast2-webservice-time = %{version}
Obsoletes:      yast2-webservice-time < %{version}
PreReq:         yast2-webservice
License:        GPL-2.0	
Group:          Productivity/Networking/Web/Utilities
URL:            http://en.opensuse.org/Portal:WebYaST
Autoreqprov:    on
Version:        0.2.3
Release:        0
Summary:        WebYaST - time management
Source:         www.tar.bz2
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch

# YaPI/TIME.pm
%if 0%{?suse_version} == 0 || %suse_version > 1110
# 11.2 or newer
Requires:       yast2-country >= 2.18.10
%else
# 11.1 or SLES11
Requires:       yast2-country >= 2.17.34.2
%endif

BuildRequires:  webyast-base-testsuite webyast-services webyast-ntp
BuildRequires:	rubygem-test-unit rubygem-mocha tidy vim

#
%define plugin_name time
%define plugin_dir %{webyast_dir}/vendor/plugins/%{plugin_name}
#

%package testsuite
Group:    Productivity/Networking/Web/Utilities
Requires: %{name} = %{version}
Requires: webyast-base-testsuite
Summary:  Testsuite for webyast-time package

%description
WebYaST - Plugin providing REST based interface to handle time zone, system time and date.

Authors:
--------
    Stefan Schubert <schubi@opensuse.org>
    Josef Reidinger <jreidinger@suse.cz>

%description testsuite
This package contains complete testsuite for webyast-time package.
It's only needed for verifying the functionality of the module and it's not
needed at runtime.

%prep
%setup -q -n www

%build
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
cp -a * $RPM_BUILD_ROOT%{plugin_dir}
rm -f $RPM_BUILD_ROOT%{plugin_dir}/COPYING
mkdir -p $RPM_BUILD_ROOT/usr/share/PolicyKit/policy

# remove .po files (no longer needed)
rm -rf $RPM_BUILD_ROOT/%{plugin_dir}/po
# search locale files
%find_lang webyast-time


%clean
rm -rf $RPM_BUILD_ROOT

%post
#
# granting all permissions for root 
#
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null
# XXX not nice to get webyast all permissions, but now not better solution
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant > /dev/null

%files -f webyast-time.lang 
%defattr(-,root,root)
%dir %{webyast_dir}
%dir %{webyast_dir}/vendor
%dir %{webyast_dir}/vendor/plugins
%dir %{plugin_dir}
%dir %{plugin_dir}/doc
%dir /usr/share/PolicyKit
%dir /usr/share/PolicyKit/policy/
%{plugin_dir}/README
%{plugin_dir}/shortcuts.yml
%{plugin_dir}/Rakefile
%{plugin_dir}/init.rb
%{plugin_dir}/install.rb
%{plugin_dir}/uninstall.rb
%{plugin_dir}/app
%{plugin_dir}/config
%{plugin_dir}/lib
%{plugin_dir}/doc/README_FOR_APP
%{plugin_dir}/locale
%doc COPYING

%files testsuite
%defattr(-,root,root)
%{plugin_dir}/test

%changelog