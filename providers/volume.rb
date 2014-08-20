#
# Cookbook Name:: fog_cloud
# Attributes:: default
#
# Copyright 2014, Florin STAN
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

action :create do
  id = find_instance_id(new_resource.connection[:provider])
  #check if the founded instance id is correct

  unless id == nil
    Chef::Log.info "Instance id #{id}"
    comp = compute_connection(new_resource.connection)
    exists = existing(comp, id, new_resource.name)

    if exists == false
      volu = volume_connection(new_resource.connection)
      v = volu.create_volume(new_resource.name, new_resource.name, new_resource.size.to_s)
      vol_id = v.body['volume']['id']
      v = volu.volumes.find {|v| v.id == vol_id }

      Chef::Log.info "Volume ID #{vol_id}"
      until v.status == "available" do
          Chef::Log.info"Volume status #{v.status}"
          v.reload
      end

      resp = attach(comp, vol_id, id)
      Chef::Log.info "We attached volume to '#{resp.data[:body]["volumeAttachment"]["device"]}' on #{node.hostname}"

      update_attributes(comp, id, 'add')
    end
  end
end

action :destroy do
  id = find_instance_id(new_resource.connection[:provider])
  Chef::Log.info "Instance id: #{id}"
  unless id == nil
    comp = compute_connection(new_resource.connection)
    volu = volume_connection(new_resource.connection)

    volumes = volu.volumes.find_all { |v|
      v.attachments.find { |a|
        a['server_id'] == id
      } != nil and v.display_name == new_resource.name
    }
    Chef::Log.info "We have #{volumes.length} volumes to destroy"
    volumes.each { |v|
      Chef::Log.info "Detaching volume #{v.id}"
      comp.detach_volume(id, v.id)
      until v.status == 'available' do
          sleep 1
          v.reload
      end
      Chef::Log.info "Destroying volume #{v.id}"
        v.destroy
    }

    update_attributes(comp, id, 'delete')
  end
end

def attach(cur_connection, vol_id, sys_id)
    volu = volume_connection(cur_connection)
    v = volu.volumes.find {|v| v.id == vol_id }
    resp = cur_connection.attach_volume(vol_id, sys_id, nil)

    until v.status == 'in-use' do
      sleep 1
      v.reload
    end
    resp
end

def existing(cur_connection, server_id, vol_name)
    vols = cur_connection.list_volumes(server_id)
    ret = false
    exist = node['fog_cloud']['volumes'].collect {|n| n['attachments'][0]['device']}

    for v in vols.data[:body]['volumes']
      if v['displayName'] == vol_name and exist.include?(v['attachments'][0]['device']) then
        Chef::Log.info("Volume id #{v['id']}")
        Chef::Log.warn("Volume '#{v['displayName']}' already exists and is #{v['status']}.")
        if v['status'] == 'in-use'
          Chef::Log.info("Volume is attached to '#{v['attachments'][0]["device"]}'")
        end
        ret = true
        break
      end
    end
    return ret
end

def update_attributes(cur_connection, server_id, action)
  vols = cur_connection.list_volumes(server_id)
  vols.data[:body]['volumes'].each do |vol|
    if vol['displayName'] == new_resource.name
      @item = vol
      break
    end
  end

  unless @item.nil?
    case action
    when 'add'
      node.set['fog_cloud']['volumes'] << @item
    when 'delete'
      node.set['fog_cloud']['volumes'].delete_if {|v| v['displayName'] == @item['displayName']}
    end
  end
end


def compute_connection(connection)
    @compute_connection ||= Fog::Compute.new(connection)
end

def volume_connection(connection)
    @volume_connection ||= Fog::Volume.new(connection)
end

def find_instance_id(provider)
    # for right now this supports only openstack
    # TODO: add the rest of the providers
    Chef::Log.info "==== PROVIDER #{provider}"
    case provider.to_s.downcase
    when /openstack|rackspace/
      delay = [1, 2]
      begin
        # JSON.parse(open('http://169.254.169.254/openstack/latest/meta_data.json').read)["uuid"]
        JSON.parse(OpenURI.open_uri('http://169.254.169.254/openstack/latest/meta_data.json', {:read_timeout => 5}).read)["uuid"]
      rescue
        if delay = retries.shift
          sleep delay
          retry
        else
          raise
        end
      end
    else
      nil
    end
end


def initialize(*args)
  super
  @action = :create
  if node['fog_cloud'].nil? || node['fog_cloud']['volumes'].nil?
    node.set['fog_cloud']['volumes'] = []
  end

  # Try to load 'fog' before forcing the dependancies to run.
  begin
    require 'fog'
  rescue LoadError => e
    Chef::Log.error("#{e.message}")
    Chef::Log.error(e.backtrace.join("\n"))
    Chef::Log.info("'FOG' failed to load. We will attempt to install dependancies.")

    Chef::Resource::Execute.new('apt-get update', @run_context).run_action(:run)

    node.set['build-essential']['compile_time'] = 1
    @run_context.include_recipe "build-essential"

    Chef::Resource::ChefGem.new('fog', @run_context).run_action(:install)
    require 'fog'
  end
end
