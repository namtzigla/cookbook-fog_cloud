# fog_cloud 

This cookbook provides resources and providers to configure and manage generic cloud resources using fog project. Currently supported resources:
* Volume (`fog_cloud_volume`)

# Requirements
It was tested with Chef 11.8.2 and against Openstack Grizzly installation 

# Dependencies
* [fog gem](http://fog.io)
* [build-essential cookbook](http://community.opscode.com/cookbooks/build-essential)

# Usage
Create volume

    fog_cloud_volume 'test' do
      action :create
      size 20 # size of the volume in GB 
      connection({
                   :provider => 'OpenStack',
                   :openstack_auth_url => node[:openstack_auth_url],
                   :openstack_username => node[:openstack_username],
                   :openstack_api_key => node[:openstack_api_key],
                   :openstack_tenant => node[:openstack_tenant]
      })
    end

Destroy volume

    fog_cloud_volume 'test' do
      action :destroy
      connection({
                   :provider => 'OpenStack',
                   :openstack_auth_url => node[:openstack_auth_url],
                   :openstack_username => node[:openstack_username],
                   :openstack_api_key => node[:openstack_api_key],
                   :openstack_tenant => node[:openstack_tenant]
      })
    end

# Attributes
None yet 

# Recipes

## default.rb
It installs the required deps (build-tools and fog gem)

## test.rb
Just for tests and examples 

# License and Author
Author:: Florin STAN (<florin.stan@gmail.com>)

Copyright 2014, Florin STAN

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.