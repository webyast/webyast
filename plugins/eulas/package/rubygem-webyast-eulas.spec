#
# spec file for package rubygem-webyast-eulas
#
# Copyright (c) 2012 SUSE LINUX Products GmbH, Nuernberg, Germany.
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


Name:           rubygem-webyast-eulas
Version:        0.3.9
Release:        0
%define mod_name webyast-eulas
%define mod_full_name %{mod_name}-%{version}

#
#
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  rubygems_with_buildroot_patch
%rubygems_requires
BuildRequires:  webyast-base >= 0.3
BuildRequires:  webyast-base-testsuite
PreReq:         webyast-base >= 0.3

Obsoletes:	webyast-licenses-ws < %{version}
Obsoletes:	webyast-licenses-ui < %{version}
Provides:	webyast-licenses-ws = %{version}
Provides:	webyast-licenses-ui = %{version}

Summary:        WebYaST - license management service
License:        GPL-2.0
Group:          Productivity/Networking/Web/Utilities
Source:         %{mod_full_name}.gem
Source1:        eulas-sles11.yml
Source2:        org.opensuse.yast.modules.yapi.licenses.policy
Source3:        eulas-opensuse11_1.yml

#
%define plugin_name eulas
#

%package doc
Summary:        RDoc documentation for %{mod_name}
Group:          Development/Languages/Ruby
Requires:       %{name} = %{version}

%description doc
Documentation generated at gem installation time.
Usually in RDoc and RI formats.

%package testsuite
Requires:       %{name} = %{version}
Requires:       webyast-base-testsuite
Summary:        Testsuite for webyast-eulas package
Group:          Development/Languages/Ruby

%description
WebYaST - Plugin providing REST based interface to handle user acceptation of EULAs.

Authors:
--------
    Martin Kudlvasr <mkudlvasr@suse.cz>
    Josef Reidinger <jreidinger@suse.cz>

%description testsuite
This package contains complete testsuite for webyast-eulas package.
It's only needed for verifying the functionality of the module and it's not
needed at runtime.

%prep

%build

%check
# run the testsuite
%webyast_run_plugin_tests

%post
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant > /dev/null

%webyast_update_assets

%postun
%webyast_remove_assets

%install

#
# Install all web and frontend parts.
#
%gem_install %{S:0}
mkdir -p $RPM_BUILD_ROOT/usr/share/%{webyast_user}/%{plugin_name}

#sles_version does not exist any more (bnc#689901)
#to use openSUSE license, the OBS project must be named accordingly
case "%{_project}" in 
 *openSUSE:*)
  # use an openSUSE license by default
  SOURCE_CONFIG=%SOURCE3
  rm -r $RPM_BUILD_ROOT/%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/config/resources/licenses/SLES-11
  ;;
 *)
  # use a sles11 license by default
  SOURCE_CONFIG=%SOURCE1
  rm -r $RPM_BUILD_ROOT/%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/config/resources/licenses/openSUSE-11.1
  ;;
esac
mv $RPM_BUILD_ROOT/%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/config/resources/licenses $RPM_BUILD_ROOT/usr/share/%{webyast_user}/%{plugin_name}/
mkdir -p $RPM_BUILD_ROOT%{webyast_vardir}/%{plugin_name}/accepted-licenses

mkdir -p $RPM_BUILD_ROOT/etc/webyast/
cp $SOURCE_CONFIG $RPM_BUILD_ROOT/etc/webyast/eulas.yml

# Policies
mkdir -p $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}
cp %{SOURCE2} $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}

# remove empty public
rm -rf $RPM_BUILD_ROOT/%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/public

%webyast_build_plugin_assets

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%files 
%defattr(-,root,root)
%{_libdir}/ruby/gems/%{rb_ver}/cache/%{mod_full_name}.gem
%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/
%exclude %{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/test
%{_libdir}/ruby/gems/%{rb_ver}/specifications/%{mod_full_name}.gemspec
# precompiled assets
%dir %{webyast_dir}/public/assets
%{webyast_dir}/public/assets/*
%dir /usr/share/%{webyast_user}
%dir /usr/share/%{webyast_user}/%{plugin_name}
%dir %{webyast_vardir}
%dir %{webyast_vardir}/%{plugin_name}
/usr/share/%{webyast_user}/%{plugin_name}/licenses
%dir /etc/webyast/
%config /etc/webyast/eulas.yml
%attr(-,%{webyast_user},%{webyast_user}) %dir %{webyast_vardir}/%{plugin_name}/accepted-licenses
%dir /usr/share/%{webyast_polkit_dir}
%attr(644,root,root) %config /usr/share/%{webyast_polkit_dir}/org.opensuse.yast.modules.yapi.licenses.policy

%files doc
%defattr(-,root,root,-)
%doc %{_libdir}/ruby/gems/%{rb_ver}/doc/%{mod_full_name}/

%files testsuite
%defattr(-,root,root,-)
%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/test

%changelog
