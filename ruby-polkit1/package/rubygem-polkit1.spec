#
# spec file for package rubygem-polkit1 (Version 0.0.1)
#
# Copyright (c) 2009 SUSE LINUX Products GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild
Name:           rubygem-polkit1
Version:        0.0.2
Release:        0
%define mod_name polkit1
#
Group:          Development/Languages/Ruby
License:        GPL-2.0+
Requires:       rubygem-inifile polkit
#
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  rubygems_with_buildroot_patch
BuildRequires:  gcc ruby-devel polkit-devel dbus-1-devel
%rubygems_requires
BuildRequires:  rubygem-inifile
BuildRequires:  rubygem-rake-compiler
BuildRequires:  rubygem-yard >= 0
#
Url:            http://www.opensuse.org
Source:         %{mod_name}-%{version}.gem
#
Summary:        Polkit bindings for ruby
%description
This extension provides polkit integration. The library provides a stable API for applications to use the authorization policies from polkit.

%package doc
Summary:        RDoc documentation for %{mod_name}
Group:          Development/Languages/Ruby
License:        GPL-2.0+
Requires:       %{name} = %{version}
%description doc
Documentation generated at gem installation time.
Usually in RDoc and RI formats.


%package testsuite
Summary:        Test suite for %{mod_name}
Group:          Development/Languages/Ruby
License:        GPL-2.0+
Requires:       %{name} = %{version}
%description testsuite
Test::Unit or RSpec files, useful for developers.


%prep
%build
%install
%gem_install %{S:0}
%gem_cleanup
rm -f %{buildroot}/%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_name}-%{version}/ext/polkit1/polkit1.c

%check
cd %{buildroot}/%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_name}-%{version}
# rake test # fails to connect to D-Bus

%clean
%{__rm} -rf %{buildroot}

%files
%defattr(-,root,root,-)
%{_libdir}/ruby/gems/%{rb_ver}/cache/%{mod_name}-%{version}.gem
%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_name}-%{version}/
#%exclude %{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_name}-%{version}/test
%{_libdir}/ruby/gems/%{rb_ver}/specifications/%{mod_name}-%{version}.gemspec

%files doc
%defattr(-,root,root,-)
%doc %{_libdir}/ruby/gems/%{rb_ver}/doc/%{mod_name}-%{version}/

%files testsuite
%defattr(-,root,root,-)
#%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_name}-%{version}/test

%changelog
