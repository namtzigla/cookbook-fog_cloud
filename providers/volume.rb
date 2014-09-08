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

def whyrun_supported?
  true
end

action :create do
  Chef::Resource::ChefGem.new('fog', @run_context).run_action(:install)
  require 'fog'

  converge_by("Create Volume '#{new_resource.name}'") do
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
        v = volu.volumes.find {|item| item.id == vol_id }

        Chef::Log.info "Volume ID #{vol_id}"
        until v.status == "available" do
          Chef::Log.info"Volume status #{v.status}"
          v.reload
        end

        resp = attach(comp, vol_id, id)
        Chef::Log.info "We attached volume '#{new_resource.name}' to '#{resp.data[:body]["volumeAttachment"]["device"]}' on '#{node['hostname']}'"
        update_attributes(comp, id, vol_id)
        Chef::Log.warn(node['fog_cloud']['volumes'])
      end
    end
  end
end

action :destroy do
  Chef::Resource::ChefGem.new('fog', @run_context).run_action(:install)
  require 'fog'

  converge_by("Destroy Volume '#{new_resource.name}'") do
    id = find_instance_id(new_resource.connection[:provider])
    Chef::Log.info "Instance id: #{id}"
    unless id == nil
      comp = compute_connection(new_resource.connection)
      volu = volume_connection(new_resource.connection)

      volumes = volu.volumes.find_all do |v|
        v.attachments.find do |a|
          a['server_id'] == id
        end != nil and v.display_name == new_resource.name
      end

      Chef::Log.info "We have #{volumes.length} volumes to destroy"
      volumes.each do |v|
        Chef::Log.info "Detaching volume #{v.id}"
        comp.detach_volume(id, v.id)
        until v.status == 'available' do
          sleep 1
          v.reload
        end
        Chef::Log.info "Destroying volume #{v.id}"
        v.destroy
      end
    end
  end
end

def attach(cur_connection, vol_id, sys_id)
  volu = volume_connection(cur_connection)
  v = volu.volumes.find do |item|
    item.id == vol_id
  end

  resp = cur_connection.attach_volume(vol_id, sys_id, nil)

  until v.status == 'in-use' do
    sleep 1
    v.reload
  end
  resp
end

#
# name - volume name
# size - volume size in GB
# wait_for - wait for volume to become available
def create_volume(name, size, wait_for = true)
  volu = volume_connection(new_resource.connection)
  v = volu.create_volume(new_resource.name, new_resource.name, new_resource.size.to_s)
  vol_id = v.body['volume']['id']
  v = volu.volumes.find {|item| item.id == vol_id }

  Chef::Log.info "Volume ID #{vol_id}"
  until v.status == "available" do
    Chef::Log.info"Volume status #{v.status}"
    v.reload
  end
end


def existing(cur_connection, server_id, vol_name)
  vols = cur_connection.list_volumes(server_id)
  ret = false

  node['fog_cloud']['volumes'].each do |v|
    begin
      if v['displayName'] == vol_name
        Chef::Log.info("Volume '#{v['displayName']}' already exists in node['volumes'] attribute.")
        live = vols.data[:body]['volumes'].select { |s| s['displayName'] == vol_name }
        if live.length > 0
          Chef::Log.info("There are #{live.length} volumes called '#{v['displayName']}'")
          live.each_with_index do |item, index|
            Chef::Log.info("Status of \##{index + 1} is '#{live[index]['status']}'")
            Chef::Log.info("Volume id #{live[index]['id']}")
            if live[index]['status'] == 'in-use' and item['attachments'][0]['serverId'] == server_id
              Chef::Log.info("Volume is attached to '#{live[index]['attachments'][0]["device"]}' on '#{node['hostname']}'")
            end
          end
        else
          Chef::Log.warn("Status is 'unknown'. Volume might have been removed!")
        end
        ret = true
        break
      end
    rescue => e
      Chef::Log.error(e.message)
    end
  end
  return ret
end

def update_attributes(cur_connection, server_id, vol_id)
  vols = cur_connection.list_volumes(server_id).data[:body]['volumes']

  vols.each do |v|
    if v['id'] == vol_id
      node.set['fog_cloud']['volumes'] = Array.new(node['fog_cloud']['volumes']) << v
      break
    end
  end
  # require 'json'
  # Chef::Log.warn(jj @resp.data)
  # node.set['fog_cloud']['volumes'] = Array.new(node['fog_cloud']['volumes']) << @resp.data[:body]['volumes']
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
      retries = 0
      begin
        # JSON.parse(open('http://169.254.169.254/openstack/latest/meta_data.json').read)["uuid"]
        JSON.parse(get_metadata('openstack'))['uuid']
      rescue
        if retries == 3
          raise
        else
          retries += 1
          Chef::Log.warn("Retrying connection to OpenStack... #{retries}/3")
          sleep retries
          retry
        end
      end
    else
      nil
    end
end

def get_metadata(provider='openstack')
  @meta_data ||= case provider
  when 'openstack'
    OpenURI.open_uri('http://169.254.169.254/openstack/latest/meta_data.json',options = {:read_timeout => 5, :proxy => false}).read
    # open('http://169.254.169.254/openstack/latest/meta_data.json',options = {:proxy => false}).read
  else
    '{}'
  end
end


def initialize(*args)
  super
  @action = :create
  if node['fog_cloud'].nil? || node['fog_cloud']['volumes'].nil?
    node.set['fog_cloud']['volumes'] = []
  end
end
