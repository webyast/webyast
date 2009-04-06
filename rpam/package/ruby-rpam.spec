#
# spec file for package ruby-rpam (Version 1.0.1)
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


Name:           ruby-rpam
Version:        1.0.1
Release:        2
License:        GPL v2 or later
Url:            http://rubyforge.org/projects/rpam
Group:          Development/Libraries/Ruby
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  gcc pam-devel ruby-devel
Requires:       ruby
Source:         %{name}-%{version}.tar.bz2
#Source1:        %{name}-%{version}-rpmlintrc
Summary:        PAM (Pluggable Authentication Modules) integration with Ruby

%description
This extension provides PAM (Pluggable Authentication Modules)
integration for the Ruby language.
The library provides a stable API for applications to defer to for
authentication tasks.



Authors:
--------
    Andre Osti de Moura <andreoandre@gmail.com>
    Klaus Kaempf <kkaempf@suse.de>

%prep
%setup -n rpam

%build
%{__make} CFLAGS="-fPIC $RPM_OPT_FLAGS"
%{__make} doc

%check
%{__make} test

%install
%makeinstall

%clean
%{__rm} -rf %{buildroot}

%files
%defattr(-,root,root,-)
%config /etc/pam.d/rpam
%if 0%{?sles_version} == 10
%{_libdir}/ruby/site_ruby/%{rb_ver}/%{rb_arch}/rpam.so
%else
%{_libdir}/ruby/vendor_ruby/%{rb_ver}/%{rb_arch}/rpam.so
%endif
%doc ext/Rpam/rdoc
%changelog
* Thu Feb 05 2009 kkaempf@suse.de
- Initial release 1.0.1 for YaST rest-service
