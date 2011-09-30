#
# spec file for package webyast-terminal (Version 0.1)
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           webyast-terminal
Provides:       WebYaST(org.opensuse.yast.modules.yapi.terminal)
PreReq:         yast2-webservice
License:        GPL-2.0
Group:          Productivity/Networking/Web/Utilities
URL:            http://en.opensuse.org/Portal:WebYaST
Autoreqprov:    on
Version:        0.0.1
Release:        0
Summary:        WebYaST - AJAX terminal plugin
Source:         www.tar.bz2
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch

BuildRequires:  webyast-base-testsuite webyast-services
BuildRequires:  rubygem-test-unit rubygem-mocha tidy vim

#
%define plugin_name terminal
%define plugin_dir %{webyast_dir}/vendor/plugins/%{plugin_name}
#

%package testsuite
Group:    Productivity/Networking/Web/Utilities
Requires: %{name} = %{version}
Requires: webyast-base-testsuite
Summary:  Testsuite for webyast-terminal package

%description
WebYaST - integration of SHELLINABOX - web based AJAX terminal emulator in WebYaST UI

Authors:
Vladislav Lewin <vlewin@suse.de>

%description testsuite
This package contains complete testsuite for webyast-terminal package.
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

# Install all web and frontend parts.
mkdir -p $RPM_BUILD_ROOT%{plugin_dir}
cp -a * $RPM_BUILD_ROOT%{plugin_dir}
rm -f $RPM_BUILD_ROOT%{plugin_dir}/COPYING
mkdir -p $RPM_BUILD_ROOT/usr/share/PolicyKit/policy

# remove .po files (no longer needed)
rm -rf $RPM_BUILD_ROOT/%{plugin_dir}/po

# search locale files
%find_lang webyast-terminal


%clean
rm -rf $RPM_BUILD_ROOT

%post

# granting all permissions for root
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant > /dev/null

%files -f webyast-terminal.lang
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

