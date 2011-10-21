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
PreReq:         webyast-base
License:        GPL-2.0
Group:          Productivity/Networking/Web/Utilities
URL:            http://en.opensuse.org/Portal:WebYaST
Autoreqprov:    on
Version:        0.3.0
Release:        0
Summary:        WebYaST - AJAX terminal plugin
Source:         www.tar.bz2
Source1:        org.opensuse.yast.modules.yapi.terminal.policy
Source2:        wicd-rpmlintrc
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch

BuildRequires:  webyast-base-testsuite
BuildRequires:  rubygem-test-unit rubygem-mocha

%define plugin_name terminal
%define plugin_dir %{webyast_dir}/vendor/plugins/%{plugin_name}

%package testsuite
Group:    Productivity/Networking/Web/Utilities
Requires: %{name} = %{version}
Requires: webyast-base-testsuite
Requires: shellinabox
Summary:  Testsuite for webyast-terminal package

%description
WebYaST integration of shellinabox (web based AJAX terminal plugin)

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

%check
%webyast_check

%install

# Install all web and frontend parts.
mkdir -p $RPM_BUILD_ROOT%{plugin_dir}
cp -a * $RPM_BUILD_ROOT%{plugin_dir}
rm -f $RPM_BUILD_ROOT%{plugin_dir}/COPYING
mkdir -p $RPM_BUILD_ROOT/usr/share/polkit-1/actions
cp %{SOURCE1} $RPM_BUILD_ROOT/usr/share/polkit-1/actions/

%clean
rm -rf $RPM_BUILD_ROOT

%post
# granting all permissions for root
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null

%files
%defattr(-,root,root)
%dir %{webyast_dir}
%dir %{webyast_dir}/vendor
%dir %{webyast_dir}/vendor/plugins
%dir %{plugin_dir}
%{plugin_dir}/README
%{plugin_dir}/shortcuts.yml
%{plugin_dir}/Rakefile
%{plugin_dir}/init.rb
%{plugin_dir}/doc
%{plugin_dir}/app
%{plugin_dir}/config
%{plugin_dir}/lib
%attr(644,root,root) /usr/share/polkit-1/actions/org.opensuse.yast.modules.yapi.terminal.policy
%doc COPYING

%files testsuite
%defattr(-,root,root)
%{plugin_dir}/test

%changelog

