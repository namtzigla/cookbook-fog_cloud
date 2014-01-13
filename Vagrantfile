# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.network :public_network
  # config.vm.synced_folder "../data", "/vagrant_data"
  config.berkshelf.enabled = true
  config.omnibus.chef_version = :latest



  config.vm.provider :aws do |aws, override|
    config.vm.box = "dummy"
    config.vm.box_url = "https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box"
    aws.access_key_id = "#{ENV['AWS_ACCESS_KEY_ID']}"
    aws.secret_access_key = "#{ENV['AWS_SECRET_ACCESS_KEY']}"
    aws.keypair_name = "#{ENV['AWS_KEY_NAME']}"
    aws.ami = "#{ENV['AWS_AMI']}"
    aws.region = "#{ENV['AWS_REGION']}"

    override.ssh.username = "ubuntu"
    override.ssh.private_key_path = "#{ENV['AWS_KEY_FILE']}"
  end

  config.vm.provider :openstack do |o, override|
    config.vm.box = "dummy"
    config.vm.box_url = "https://github.com/cloudbau/vagrant-openstack-plugin/raw/master/dummy.box"

    o.username ="#{ENV['OS_USERNAME']}"
    o.api_key = "#{ENV['OS_PASSWORD']}"
    o.endpoint = "#{ENV['OS_AUTH_URL']}"

  end

  config.vm.provision :chef_solo do |chef|
    chef.arguments = '-l debug'
    chef.verbose_logging = true
    chef.log_level = :debug
    chef.json = {
      :build_essential => {
        :compiletime => true
      },
      :aws_access_key_id => "#{ENV['AWS_ACCESS_KEY_ID']}",
      :aws_secret_access_key => "#{ENV['AWS_SECRET_ACCESS_KEY']}",
      :aws_region => "#{ENV['AWS_REGION']}"

    }

    chef.run_list = [
      "recipe[build-essential::default]",
      "recipe[fog_cloud::default]",
      "recipe[fog_cloud::test_aws]"
    ]
  end


  # config.vm.provision :chef_solo do |chef|
  #   chef.cookbooks_path = "../my-recipes/cookbooks"
  #   chef.roles_path = "../my-recipes/roles"
  #   chef.data_bags_path = "../my-recipes/data_bags"
  #   chef.add_recipe "mysql"
  #   chef.add_role "web"
  #
  #   # You may also specify custom JSON attributes:
  #   chef.json = { :mysql_password => "foo" }
  # end

  # Enable provisioning with chef server, specifying the chef server URL,
  # and the path to the validation key (relative to this Vagrantfile).
  #
  # The Opscode Platform uses HTTPS. Substitute your organization for
  # ORGNAME in the URL and validation key.
  #
  # If you have your own Chef Server, use the appropriate URL, which may be
  # HTTP instead of HTTPS depending on your configuration. Also change the
  # validation key to validation.pem.
  #
  # config.vm.provision :chef_client do |chef|
  #   chef.chef_server_url = "https://api.opscode.com/organizations/ORGNAME"
  #   chef.validation_key_path = "ORGNAME-validator.pem"
  # end
  #
  # If you're using the Opscode platform, your validator client is
  # ORGNAME-validator, replacing ORGNAME with your organization name.
  #
  # If you have your own Chef Server, the default validation client name is
  # chef-validator, unless you changed the configuration.
  #
  #   chef.validation_client_name = "ORGNAME-validator"
end
