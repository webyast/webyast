#
# spec file for package ruby-rpam (Version 1.0.1)
#
# Copyright (c) 2009 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild

Name:           ruby-rpam
Version:        1.0.1
Release:        0
License:        GPLv2
Url:            http://rubyforge.org/projects/rpam
Group:          Development/Languages/Ruby
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  gcc ruby-devel pam-devel
Requires:       ruby
Source:         %{name}-%{version}.tar.bz2
#Source1:        %{name}-%{version}-rpmlintrc
Summary:        Ruby bindings for PAM
%description
Ruby bindings for PAM

 Authors:
----------
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
