#
# spec file for package rubygem-webyast-administrator
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

# norootforbuild
Name:           rubygem-webyast-administrator
Version:        0.1
Release:        0
%define mod_name webyast-administrator
%define mod_full_name %{mod_name}-%{version}
#
Group:          Development/Languages/Ruby
License:        GPL-2.0	
#
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  rubygems_with_buildroot_patch
%rubygems_requires
BuildRequires:	webyast-base, rubygem-sqlite3-ruby, rubygem-ruby-fcgi
BuildRequires:	rubygem-webyast-rake-tasks >= 0.1.13
BuildRequires:	webyast-base-testsuite
Requires:	webyast-base
Requires:	rubygem-webyast-rake-tasks >= 0.1.13

#
Url:            http://rubygems.org/gems/webyast-administrator
Source:         %{mod_full_name}.gem
Source1:	org.opensuse.yast.modules.yapi.administrator.policy
#
Summary:        Webyast module for configuring administrator settings
%description
Webyast module for configuring administrator settings


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

%prep
%build

%post
# granting all permissions for the web user
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant > /dev/null

cd %{webyast_dir}
# update manifest.yml file
# use assets.rake file directly (faster loading)
rake -f lib/tasks/assets.rake assets:join_manifests

%postun
cd %{webyast_dir}
# update manifest.yml file
# use assets.rake file directly (faster loading)
rake -f lib/tasks/assets.rake assets:join_manifests

%check
export TEST_DB_PATH=/tmp/webyast_test.sqlite3
export RAILS_PARENT=%{webyast_dir}
rm -rf $TEST_DB_PATH
cd $RPM_BUILD_ROOT/%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}
RAILS_ENV=test rake db:create
RAILS_ENV=test rake db:schema:load
cp %{webyast_dir}/Gemfile.test Gemfile.test
echo 'gem "%{mod_name}", :path => "."' >> Gemfile.test
BUNDLE_GEMFILE=Gemfile.test RAILS_ENV=test ADD_BUILD_PATH=1 rake test
rm -rf $TEST_DB_PATH

%install
%gem_install %{S:0}

# Policies
mkdir -p $RPM_BUILD_ROOT/usr/share/polkit-1/actions
install -m 0644 %SOURCE1 $RPM_BUILD_ROOT/usr/share/polkit-1/actions/

# precompile assets
export RAILS_PARENT=%{webyast_dir}
cd $RPM_BUILD_ROOT/%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}

rake assets:precompile
rm -rf tmp

# move them to webyast-base
mkdir -p $RPM_BUILD_ROOT/srv/www/webyast/public/assets
mv public/assets/* $RPM_BUILD_ROOT/srv/www/webyast/public/assets
rm -rf public/assets
mv $RPM_BUILD_ROOT/srv/www/webyast/public/assets/manifest.yml $RPM_BUILD_ROOT/srv/www/webyast/public/assets/manifest.yml.administrator

rm -rf log

# search locale files
#find_lang webyast-root-user


%clean
%{__rm} -rf %{buildroot}

%files
%defattr(-,root,root,-)
%{_libdir}/ruby/gems/%{rb_ver}/cache/%{mod_full_name}.gem
%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/
%exclude %{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/test
%{_libdir}/ruby/gems/%{rb_ver}/specifications/%{mod_full_name}.gemspec

# precompiled assets
%dir /srv/www/webyast/public/assets
/srv/www/webyast/public/assets/*

%dir /usr/share/polkit-1
%dir /usr/share/polkit-1/actions
%attr(644,root,root) %config /usr/share/polkit-1/actions/org.opensuse.yast.modules.yapi.administrator.policy

%files doc
%defattr(-,root,root,-)
%doc %{_libdir}/ruby/gems/%{rb_ver}/doc/%{mod_full_name}/

%files testsuite
%defattr(-,root,root,-)
%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/test

%changelog
