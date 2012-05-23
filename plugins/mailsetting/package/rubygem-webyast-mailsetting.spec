#
# spec file for package webyast-mail
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


# norootforbuild
Name:           rubygem-webyast-mailsetting
Version:        0.3.1
Release:        0
%define mod_name webyast-mailsetting
%define mod_full_name %{mod_name}-%{version}
#
Group:          Productivity/Networking/Web/Utilities
License:        GPL-2.0	
#
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  rubygems_with_buildroot_patch
%rubygems_requires
BuildRequires:	webyast-base >= 0.3
BuildRequires:	webyast-base-testsuite
BuildRequires:	rubygem-restility
PreReq:	        webyast-base >= 0.3


URL:            http://en.opensuse.org/Portal:WebYaST
Summary:        WebYaST - system mail settings
Source:         %{mod_full_name}.gem
Source1:        MailSettings.pm
Source2:	org.opensuse.yast.modules.yapi.mailsettings.policy
Source3:        postfix-update-hostname
BuildRoot:      %{_tmppath}/%{name}-%{version}-build

# install these packages into Hudson chroot environment
# the exact versions are checked in checks.rake task
%if 0
BuildRequires:  yast2 yast2-mail
%endif
Requires:	postfix mailx

# Mail.ycp
%if 0%{?suse_version} == 0 || 0%{?suse_version} >= 1120
# openSUSE11.2, Factory
Requires:       yast2-mail >= 2.18.3
%else
# SLE11SP1
Requires:       yast2-mail >= 2.17.5
%endif

%package doc
Summary:        RDoc documentation for %{mod_name}
Group:          Development/Languages/Ruby
Requires:       %{name} = %{version}
%description doc
Documentation generated at gem installation time.
Usually in RDoc and RI formats.

%package testsuite
Summary:        Test suite for %{mod_name}
Group:          Development/Languages/Ruby
Requires:       %{name} = %{version}
%description testsuite
Test::Unit or RSpec files, useful for developers.

%description
WebYaST - Plugin provides REST based interface to system mail settings.
It does not provide mail server configuration, just redirecting of system mails.

Authors:
--------
    Jiri Suchomel <jsuchome@novell.com>

%description testsuite
This package contains complete testsuite for webyast-mail package.
It's only needed for verifying the functionality of the module and it's not
needed at runtime.

%prep


%build

%check
# run the testsuite
%webyast_run_plugin_tests

%install
%gem_install %{S:0}

mkdir -p $RPM_BUILD_ROOT%{webyast_vardir}/mailsetting

# Policies
mkdir -p $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}
install -m 0644 %SOURCE2 $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}

#YaPI
mkdir -p $RPM_BUILD_ROOT/usr/share/YaST2/modules/YaPI/
cp %{SOURCE1} $RPM_BUILD_ROOT/usr/share/YaST2/modules/YaPI/

#hook script
mkdir -p $RPM_BUILD_ROOT/etc/sysconfig/network/scripts/
install -m 0755 %SOURCE3 $RPM_BUILD_ROOT/etc/sysconfig/network/scripts/

%webyast_build_restdoc public/mailsetting/restdoc

# remove empty public
rm -rf $RPM_BUILD_ROOT/%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/public

%webyast_build_plugin_assets

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%post
# granting all permissions for the web user
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null ||:
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant > /dev/null ||:

%webyast_update_assets

%postun
%webyast_remove_assets

%files
%defattr(-,root,root,-)
%{_libdir}/ruby/gems/%{rb_ver}/cache/%{mod_full_name}.gem
%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/
%exclude %{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/test
%{_libdir}/ruby/gems/%{rb_ver}/specifications/%{mod_full_name}.gemspec

# precompiled assets
%dir %{webyast_dir}/public/assets
%{webyast_dir}/public/assets/*

# restdoc documentation
%dir %{webyast_dir}/public/mailsetting
%{webyast_dir}/public/mailsetting/restdoc

# YaPI dir
%dir /usr/share/YaST2/
%dir /usr/share/YaST2/modules/
%dir /usr/share/YaST2/modules/YaPI/
#var dir to store mail test status
%dir %attr (-,%{webyast_user},root) %{webyast_vardir}
%dir %attr (-,%{webyast_user},root) %{webyast_vardir}/mailsetting

/usr/share/YaST2/modules/YaPI/MailSettings.pm
/etc/sysconfig/network/scripts/postfix-update-hostname

%dir /usr/share/%{webyast_polkit_dir}
%attr(644,root,root) %config /usr/share/%{webyast_polkit_dir}/org.opensuse.yast.modules.yapi.mailsettings.policy

%files doc
%defattr(-,root,root,-)
%doc %{_libdir}/ruby/gems/%{rb_ver}/doc/%{mod_full_name}/

%files testsuite
%defattr(-,root,root,-)
%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/test

%changelog
