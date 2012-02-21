#
# spec file for package webyast-activedirectory
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#
# norootforbuild

Name:           rubygem-webyast-activedirectory
Version:        0.1
Release:        0
%define mod_name webyast-activedirectory
%define mod_full_name %{mod_name}-%{version}
#
License:        GPL-2.0	
Group:          Productivity/Networking/Web/Utilities
URL:            http://en.opensuse.org/Portal:WebYaST
#
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  rubygems_with_buildroot_patch
%rubygems_requires
BuildRequires:	webyast-base, rubygem-sqlite3-ruby
BuildRequires:	rubygem-webyast-rake-tasks >= 0.2
BuildRequires:	webyast-base-testsuite
PreReq:	        webyast-base
PreReq: 	rubygem-webyast-rake-tasks >= 0.2

# for enabling winbind and Kerberos configuration
Requires:	samba-winbind samba-client pam_mount yast2-kerberos-client krb5 krb5-client
# for dig
Requires:	bind-utils
# reasonable PATH set (bnc#617442)
Requires:       yast2-dbus-server >= 2.17.3

# ActiveDirectory.pm is using yast2-samba-client API
# specific versin for SambaAD::SetRealm
Requires:	yast2-samba-client >= 2.17.18


Source:         www.tar.bz2
Source1:        org.opensuse.yast.modules.yapi.activedirectory.policy
Source2:        ActiveDirectory.pm

Summary:        WebYaST - configuration of Active Directory client
%description
WebYaST - Plugin for configuration of Active Directory client

%package testsuite
Summary:        Test suite for %{mod_name}
Group:          Development/Languages/Ruby
Requires:       %{name} = %{version}
%description testsuite
Test::Unit or RSpec files, useful for developers.

%prep

%build

#export RAILS_PARENT=%{webyast_dir}
#export LANG=en
#rake gettext:pack

%check
# run the testsuite
%webyast_check

%install
%gem_install %{S:0}

# Policies
mkdir -p $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}
install -m 0644 %SOURCE1 $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}

#YaPI
mkdir -p $RPM_BUILD_ROOT/usr/share/YaST2/modules/YaPI/
cp %{SOURCE2} $RPM_BUILD_ROOT/usr/share/YaST2/modules/YaPI/

# search locale files
#%find_lang webyast-activedirectory

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%post
# granting all permissions for the web user
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant > /dev/null
%webyast_update_assets

%postun
%webyast_update_assets

%files
%defattr(-,root,root)

%{_libdir}/ruby/gems/%{rb_ver}/cache/%{mod_full_name}.gem
%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/
%exclude %{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/test
%{_libdir}/ruby/gems/%{rb_ver}/specifications/%{mod_full_name}.gemspec

# precompiled assets
%dir %{webyast_dir}/public/assets
%{webyast_dir}/public/assets/*

# YaPI dir
%dir /usr/share/YaST2/
%dir /usr/share/YaST2/modules/
%dir /usr/share/YaST2/modules/YaPI/
/usr/share/YaST2/modules/YaPI/ActiveDirectory.pm

%dir /usr/share/%{webyast_polkit_dir}
%attr(644,root,root) %config /usr/share/%{webyast_polkit_dir}/org.opensuse.yast.modules.yapi.activedirectory.policy
%doc COPYING

%files testsuite
%defattr(-,root,root,-)
%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/test

%changelog
