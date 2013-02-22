#
# spec file for package rubygem-webyast-status
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


Name:           rubygem-webyast-status
Version:        0.3.16
Release:        0
%define mod_name webyast-status
%define mod_full_name %{mod_name}-%{version}
#
#
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  rubygems_with_buildroot_patch
%rubygems_requires
BuildRequires:  rubygem-restility
BuildRequires:  webyast-base >= 0.3.31
BuildRequires:  webyast-base-testsuite

PreReq:         webyast-base >= 0.3.31

# /usr/bin/pgrep
Requires:	procps

Obsoletes:	webyast-status-ws < %{version}
Obsoletes:	webyast-status-ui < %{version}
Provides:	webyast-status-ws = %{version}
Provides:	webyast-status-ui = %{version}

Url:            http://en.opensuse.org/Portal:WebYaST
Summary:        WebYaST - system status 
License:        GPL-2.0
Group:          Productivity/Networking/Web/Utilities
Source:         %{mod_full_name}.gem
Source1:        org.opensuse.yast.modules.yapi.metrics.policy
Source2:        org.opensuse.yast.modules.logfile.policy
Source3:        LogFile.rb
PreReq:         collectd, %insserv_prereq
Requires:       rrdtool
# for calling ruby module via YastService:
Requires:       yast2-ruby-bindings >= 0.3.2.1

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

%description
WebYaST - Plugin providing REST based interface to provide information about system status.

Authors:
--------
    Björn Geuken <bgeuken@suse.de>
    Duncan Mac-Vicar Prett <dmacvicar@suse.de>
    Stefan Schubert <schubi@suse.de>

%description testsuite
This package contains complete testsuite for webyast-status package.
It's only needed for verifying the functionality of the module and it's not
needed at runtime.

%prep

%build
%create_restart_script

%check
# run the testsuite
%webyast_run_plugin_tests

%install
%gem_install %{S:0}

# Policies
mkdir -p $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}
install -m 0644 %SOURCE1 $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}
install -m 0644 %SOURCE2 $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}

#metrics configuration
mkdir -p $RPM_BUILD_ROOT%{webyast_vardir}/status

# LogFile.rb
mkdir -p $RPM_BUILD_ROOT/usr/share/YaST2/modules/
cp %{SOURCE3} $RPM_BUILD_ROOT/usr/share/YaST2/modules/

mkdir -p $RPM_BUILD_ROOT/etc/webyast/vendor
cp $RPM_BUILD_ROOT/%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/doc/logs.yml $RPM_BUILD_ROOT/etc/webyast

%webyast_build_restdoc

%webyast_build_plugin_assets

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%post
#
# granting all permissions for root
#
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant > /dev/null

#
# nslookup of static hostnames can result to an error. Due this error collectd
# will not be started. So FQDN (fully qualified domain name) is disabled.
#
sed -i "s/^FQDNLookup.*/FQDNLookup false/" "/etc/collectd.conf"

#
# enable "df" plugin of collectd
#
sed -i "s/^#LoadPlugin df.*/LoadPlugin df/" "/etc/collectd.conf"

#
# check status_configuration.yaml bnc#636616
#
ruby %{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/lib/configcheck.rb
ruby %{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/lib/update_config.rb

#
# set "Hostname" to WebYaST
#
grep -q "^Hostname[ \t]*\"WebYaST\"" /etc/collectd.conf
if [ $? = 1 ] ; then
  WARNING="# If you change hostname please delete /var/lib/collectd/WebYaST"
  sed -i "s@^#Hostname[[:space:]].*@$WARNING\nHostname \"WebYaST\"@" /etc/collectd.conf

  # We need to remove old logs because Webyast displays the first found log
  # which could be accidentally the old (no longer) updated log.
  #
  # FIXME: find the latest database in webyast instead of complete removal here
  #
  # The removal might accidentaly fail if collectd is running and writes a log during removal,
  # it would be a good idea to stop it first but unfortunately also stopping sometimes fails
  # and that would cause build failure during RPM build :-(
  rm -rf /var/lib/collectd/*
fi

#
# enable and restart collectd
#
# FIXME: move collectd handling to webyast initscript or to WebUI
%{fillup_and_insserv -Y collectd}
rccollectd restart

%restart_webyast

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

%dir /usr/share/YaST2/
%dir /usr/share/YaST2/modules/
/usr/share/YaST2/modules/LogFile.rb

%dir /usr/share/%{webyast_polkit_dir}
%attr(0700,%{webyast_user},%{webyast_user}) %dir %{webyast_vardir}/status
%attr(644,root,root) %config /usr/share/%{webyast_polkit_dir}/org.opensuse.yast.modules.yapi.metrics.policy
%attr(644,root,root) %config /usr/share/%{webyast_polkit_dir}/org.opensuse.yast.modules.logfile.policy
%dir /etc/webyast/vendor
%config /etc/webyast/logs.yml
# File is created in %post script, but doesn't exist in build or install, so cannot be ghost
# %ghost %config %{webyast_vardir}/status/status_configuration.yaml

%restart_script_name

%files doc
%defattr(-,root,root,-)
%doc %{_libdir}/ruby/gems/%{rb_ver}/doc/%{mod_full_name}/

%files testsuite
%defattr(-,root,root,-)
%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/test

%changelog
