#
# Cookbook Name:: statsd
# Recipe:: default
#
# Copyright 2011, Blank Pad Development
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#



include_recipe "nodejs"

statsd_version = node[:statsd][:sha]


if platform?(%w{ debian })

  include_recipe "build-essential"
  include_recipe "git"

  git "#{node[:statsd][:tmp_dir]}/statsd" do
    repository node[:statsd][:repo]
    reference statsd_version
    action :sync
    notifies :run, "execute[build debian package]"
  end

  package "debhelper"

  # Fix the debian changelog file of the repo
  template "#{node[:statsd][:tmp_dir]}/statsd/debian/changelog" do
    source "changelog.erb"
  end

  execute "build debian package" do
    command "dpkg-buildpackage -us -uc"
    cwd "#{node[:statsd][:tmp_dir]}/statsd"
    creates "#{node[:statsd][:tmp_dir]}/statsd_#{node[:statsd][:package_version]}_all.deb"
  end

  dpkg_package "statsd" do
    action :install
    source "#{node[:statsd][:tmp_dir]}/statsd_#{node[:statsd][:package_version]}_all.deb"
  end
end

if platform?(%w{ redhat centos fedora })

#  chef_gem 'fpm'
  gem_package "fpm" do
	  gem_binary "/opt/chef/embedded/bin/gem"
	    action :nothing
	      version "0.4.33"
  end.run_action(:install)

  Gem.clear_paths

  package "rpmdevtools" do
    action :install
  end

  directory "#{node[:statsd][:tmp_dir]}/build/usr/share/statsd/scripts" do
	  recursive true
  end

  git "#{node[:statsd][:tmp_dir]}/build/usr/share/statsd" do
     repository node[:statsd][:repo]
     reference statsd_version
     action :sync
     notifies :run, "execute[build rpm package]"
  end


   # Fix the debian changelog file of the repo
#   template "#{node[:statsd][:tmp_dir]}/statsd/debian/changelog" do
#    source "changelog.erb"
#   end

   execute "build rpm package" do
     command "fpm -s dir -t rpm -n statsd -a noarch -v #{node[:statsd][:package_version]} ."
     cwd "#{node[:statsd][:tmp_dir]}/build"
     creates "#{node[:statsd][:tmp_dir]}/statsd-#{node[:statsd][:package_version]}-1.noarch.rpm"
   end

   rpm_package "statsd" do
     action :install
     source "#{node[:statsd][:tmp_dir]}/build/statsd-#{node[:statsd][:package_version]}-1.noarch.rpm"
   end
  
   directory "/etc/statsd" do
   end
end

template "/etc/statsd/rdioConfig.js" do
  source "rdioConfig.js.erb"
  mode 0644
  variables(
    :port => node[:statsd][:port],
    :graphitePort => node[:statsd][:graphite_port],
    :graphiteHost => node[:statsd][:graphite_host]
  )

  notifies :restart, "service[statsd]"
end

cookbook_file "/usr/share/statsd/scripts/start" do
  source "upstart.start"
  mode 0755
end

cookbook_file "/etc/init/statsd.conf" do
  source "upstart.conf"
  mode 0644
end

user node[:statsd][:user] do
  comment "statsd"
  system true
  shell "/bin/false"
  home "/var/log/statsd"
end

service "statsd" do
  provider Chef::Provider::Service::Upstart
  action [ :enable, :start ]
end
