# fog_cloud

This cookbook provides resources and providers to configure and manage generic cloud resources using fog project. Currently supported resources:
* Volume (`fog_cloud_volume`)

# Requirements
It was tested with Chef 11.8.2 and against Openstack Grizzly installation

# Dependencies
You need to add `recipe[apt::default]` and `recipe[build-essential::default]`
to your run list so that `require 'fog'` does not fail.

* [fog gem](http://fog.io)
* [build-essential cookbook](http://community.opscode.com/cookbooks/build-essential)

You may want to add `default['apt']['compile_time_update'] = true` to your
attributes `default.rb`.

# Usage
Create volume

    fog_cloud_volume 'test' do
      action :create
      size 10 # size of the volume in GB
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
When resource is created it sets `node['fog_cloud']['volumes']` which is an
array of hashes.  Each hash is the information for one volume instance.  All
data for that volume can be access from there. Once a volume is created and
added to the attribute it then becomes your responsibility.  If you remove the
volume or detach it Chef will still assume it is there and will not create/attach
the volume.  You will need to delete the item in the attribute for that volume to
create a new one.

Sample `node['fog_cloud']['volumes']`:

    node['fog_cloud']['volumes'] =
      [
        {
           "status": "in-use",
           "displayDescription": "testing_2",
           "availabilityZone": "nova",
           "displayName": "testing_2",
           "attachments": [
             {
                "device": "/dev/vdd",
                "serverId": "31a2e888-367a-466a-af86-f193339c31d8",
                "id": "bb145bc2-6ddc-429e-8f0d-1ba69e7f9847",
                "volumeId": "bb145bc2-6ddc-429e-8f0d-1ba69e7f9847"
             }
           ],
           "volumeType": "None",
           "snapshotId": null,
           "metadata": {
             "readonly": "False",
             "attached_mode": "rw"
           },
           "id": "bb145bc2-6ddc-429e-8f0d-1ba69e7f9847",
           "createdAt": "2014-08-08T18:24:07.000000",
           "size": 10
        }
      ]


# Recipes

## default.rb
Does nothing.

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
