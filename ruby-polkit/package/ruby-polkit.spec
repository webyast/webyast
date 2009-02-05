#
# spec file for package ruby-polkit (Version 0.0.1)
#
# Copyright (c) 2009 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild

Name:           ruby-polkit
Version:        0.0.1
Release:        0
License:        GPLv2
Group:          Development/Languages/Ruby
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  gcc ruby-devel PolicyKit-devel dbus-1-devel
Requires:       ruby
Source:         %{name}-%{version}.tar.bz2
#Source1:        %{name}-%{version}-rpmlintrc
Summary:        Ruby bindings for PolicyKit
%description
Ruby bindings for PolicyKit

 Authors:
----------
    Stefan Schubert <schubi@suse.de>
    Klaus Kaempf <kkaempf@suse.de>

%prep
%setup -n %{name}

%build
%{__make} DEFS="$RPM_OPT_FLAGS"
%{__make} doc

%check
#%{__make} test   # not yet working in buildenv

%install
%makeinstall

%clean
%{__rm} -rf %{buildroot}

%files
%defattr(-,root,root,-)
%if 0%{?sles_version} == 10
%{_libdir}/ruby/site_ruby/%{rb_ver}/%{rb_arch}/polkit.so
%else
%{_libdir}/ruby/vendor_ruby/%{rb_ver}/%{rb_arch}/polkit.so
%endif
%doc src/rdoc
