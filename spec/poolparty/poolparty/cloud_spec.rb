require File.dirname(__FILE__) + '/../spec_helper'

class TestService
  plugin :test_service do
    def initialize(o={}, e=nil, &block)
      super(&block)
    end
    def enable(o={})
      has_file(:name => "/etc/poolparty/lobos")
    end                  
  end
end

describe "Cloud" do
  before(:each) do
    setup
    # 
  end
  describe "wrapped" do
    before(:each) do
      @obj = Object.new
      @pool = pool :just_pool do; end
    end
    it "should respond to the pool method outside the block" do
      @obj.respond_to?(:cloud).should == true
    end
    describe "global" do
      before(:each) do
        @cloud1 = cloud :pop do;end
      end
      it "should store the cloud in the global list of clouds" do    
        @obj.clouds.has_key?(:pop).should == true
      end
      it "should store the cloud" do
        @obj.cloud(:pop).should == @cloud1
      end
      it "should have set the using base on intantiation to ec2" do
        @cloud1.using_remoter?.should_not == nil
      end
      it "should say the remoter_base is ec2 (by default)" do
        @cloud1.remote_base.class.should == Kernel::Ec2
      end
    end
    it "should return the cloud if the cloud key is already in the clouds list" do
      @cld = cloud :pop do;end
      @pool.cloud(:pop).should == @cld
    end
    describe "options" do
      before(:each) do
        reset!
        setup
        pool :options do
          user "bob"
          pop_stick true
          minimum_instances 100
          access_key "pool_access_key"
          cloud :apple do
            access_key "cloud_access_key"
          end
        end
      end
      it "should be able to grab the cloud from the pool" do
        clouds[:apple].should == pools[:options].cloud(:apple)
      end
      it "should take the options set on the pool" do
        pools[:options].minimum_instances.should == 100
      end
      it "should take the access_key option set from the cloud" do
        clouds[:apple].access_key.should == "cloud_access_key"
      end
      it "should take the option pop_stick from the superclass" do
        clouds[:apple].pop_stick.should == true
      end
      it "should take the option testing true from the superclass" do
        pools[:options].user.should == "bob"
        clouds[:apple].user.should == "bob"
      end
    end
    describe "block" do
      before(:each) do
        reset!
        pool :test do
          Cloud.new(:test) do
            # Inside cloud block
            testing true
            keypair "fake_keypair"
          end
        end
        @cloud = cloud :test
        @cloud.stub!(:plugin_store).and_return []
      end

      it "should be able to pull the pool from the cloud" do
        @cloud.parent == @pool
      end
      it "should have the outer pool listed as the parent of the inner cloud" do
        @pool = pool :knick_knack do
          cloud :paddy_wack do            
          end
        end
        cloud(:paddy_wack).parent.should == pool(:knick_knack)
      end
      it "should have services in an hash" do
        @cloud.services.class.should == Hash
      end
      it "should have no services in the array when there are no services defined" do
        @cloud.services.size.should == 0
      end
      it "should respond to a options method (from Dslify)" do
        @cloud.respond_to?(:options).should == true
      end
      describe "configuration" do
        before(:each) do
          reset!
          @cloud2 = Cloud.new(:test) do
            minimum_instances 1
            maximum_instances 2
          end
        end
        it "should be able to se the minimum_instances without the var" do
          @cloud2.minimum_instances.should == 1
        end
        it "should be able to se the maximum_instances with the =" do
          @cloud2.maximum_instances.should == 2
        end
      end
      describe "options" do
        it "should set the minimum_instances to 2" do
          @cloud.minimum_instances.should == 2
        end
        it "should set the maximum_instances to 5" do
          @cloud.maximum_instances.should == 5
        end
        it "should be able to set the minimum instances" do
          @cloud.minimum_instances 3
          @cloud.minimum_instances.should == 3
        end
        it "should be able to take a hash from configure and convert it to the options" do
          @cloud.set_vars_from_options( {:minimum_instances => 1, :maximum_instances => 10, :keypair => "friend"} )
          @cloud.minimum_instances.should == 1
        end
        describe "minimum_instances/maximum_instances as a range" do
          before(:each) do
            reset!
            @pool = pool :just_pool do
              cloud :app do
                instances 8..15
              end
            end
            @cloud = @pool.cloud(:app)
          end
          it "should set the minimum based on the range" do
            @cloud.minimum_instances.should == 8
          end
          it "should set the maximum based on the range set by instances" do
            @cloud.maximum_instances.should == 15
          end
        end
        describe "keypair" do
          before(:each) do
            reset!
          end
          it "should be able to define a keypair in the cloud" do
            @c = cloud :app do
              keypair "hotdog"
            end
            @c.keypairs.first.filepath.should == "hotdog"
          end
          it "should take the pool parent's keypair if it's defined on the pool" do
            pool :pool do
              keypair "ney"
              cloud :app do
              end
            end
            clouds[:app]._keypairs.first.stub!(:exists?).and_return true
            clouds[:app]._keypairs.first.stub!(:full_filepath).and_return "ney"
            clouds[:app].keypair.full_filepath.should == "ney"
          end
          it "should default to ~/.ssh/id_rsa if none are defined" do
            File.stub!(:exists?).with("#{ENV["HOME"]}/.ssh/id_rsa").and_return(true)
            pool :pool do
              cloud :app do
              end
            end
            clouds[:app].keypair.full_filepath.should match(/\.ssh\/id_rsa/)
          end
        end
        describe "Manifest" do
          before(:each) do
            reset!
            stub_list_from_remote_for(@cloud)
            @cloud = TestClass.new :test_more_manifest do
              has_file(:name => "/etc/httpd/http.conf") do
                content <<-EOE
                  hello my lady
                EOE
              end
              has_gempackage(:name => "poolparty")
              has_package(:name => "dummy")            
            end
            context_stack.push @cloud
          end
          it "should it should have the method build_manifest" do
            @cloud.respond_to?(:build_manifest).should == true
          end
          it "should make a new 'haproxy' class" do
            PoolpartyBaseHaproxyClass.should_receive(:new).once
            @cloud.add_poolparty_base_requirements
          end
          it "should have 3 resources" do            
            @cloud.add_poolparty_base_requirements
            @cloud.services.size.should > 2
          end
          it "should receive add_poolparty_base_requirements before building the manifest" do
            @cloud.should_receive(:add_poolparty_base_requirements).once
            @cloud.build_manifest
          end
          after(:each) do
            context_stack.pop
          end
          describe "add_poolparty_base_requirements" do
            before(:each) do
              reset!            
              @cloud.instance_eval do
                @heartbeat = nil
              end
              @hb = PoolpartyBaseHeartbeatClass.new
            end
            it "should call initialize on heartbeat (in add_poolparty_base_requirements)" do
              @hb.class.should_receive(:new).and_return true
              @cloud.add_poolparty_base_requirements
            end
            it "should call heartbeat on the cloud" do
              @cloud.should_receive(:poolparty_base_heartbeat).and_return true
              @cloud.add_poolparty_base_requirements
            end
            it "should call Hearbeat.new" do
              PoolpartyBaseHeartbeatClass.should_receive(:new).and_return @hb
              @cloud.add_poolparty_base_requirements            
            end
            it "should call enable on the plugin call" do
              @hb = PoolpartyBaseHeartbeatClass.new
              PoolpartyBaseHeartbeatClass.stub!(:new).and_return @hb
              
              @cloud.add_poolparty_base_requirements
              @cloud.poolparty_base_heartbeat.should == @hb
            end
            describe "after adding" do
              before(:each) do
                stub_list_from_remote_for(@cloud)
                @cloud.add_poolparty_base_requirements
              end
              it "should add resources onto the heartbeat class inside the cloud" do
                @cloud.services.size.should > 0
              end
              it "should store the class heartbeat" do
                @cloud.services.map {|k,v| k}.include?(:poolparty_base_heartbeat_class).should == true
              end
              it "should have an array of resources on the heartbeat" do
                @cloud.services.class.should == Hash
              end
              describe "resources" do
                before(:each) do
                  @cloud8 = cloud :tester do
                    test_service
                  end
                  @service = clouds[:tester].services.test_service_class
                  @files = @service.resource(:file)
                end
                it "should have a file resource" do
                  @files.first.nil?.should == false
                end
                it "should have an array of lines" do
                  @files.class.should == Array
                end
                it "should not be empty" do
                  @files.should_not be_empty
                end
              end
            end
          end
          describe "building" do
            before(:each) do            
              str = "master 192.168.0.1
              node1 192.168.0.2"
              @sample_instances_list = [{:ip => "192.168.0.1", :name => "master"}, {:ip => "192.168.0.2", :name => "node1"}]
              @ris = @sample_instances_list.map {|h| PoolParty::Remote::RemoteInstance.new(h, @cloud) }
              
              stub_remoter_for(@cloud)
              
              @manifest = @cloud.build_manifest
            end
            it "should return a string when calling build_manifest" do
              @manifest.class.should == String
            end
            it "should have a comment of # file in the manifest as described by the has_file" do
              @manifest.should =~ /file \{/
            end
            it "should have the comment of a package in the manifest" do
              @manifest.should =~ /package \{/
            end
            it "should have the comment for haproxy in the manifest" do
              @manifest.should =~ /haproxy/            
            end
            it "should include the poolparty gem" do
              @manifest.should =~ /package \{/
            end
          end
          describe "prepare_for_configuration" do
            before(:each) do
              @cloud.stub!(:copy_ssh_key).and_return true
              @cloud.stub!(:before_configuration_tasks).and_return []
            end
            it "should make_base_directory" do
              @cloud.should_receive(:make_base_directory).at_least(1)
            end
            it "should copy_misc_templates" do
              @cloud.should_receive(:copy_misc_templates).once
            end
            describe "copy_custom_templates" do
              it "should receive copy_custom_templates" do
                @cloud.should_receive(:copy_custom_templates).once
              end
              it "test to see if the directory Dir.pwd/templates exists" do
                ::File.should_receive(:directory?).with("#{Dir.pwd}/templates").and_return false
                ::File.stub!(:directory?).and_return true
                @cloud.copy_custom_templates
              end
              it "copy each file to the template directory" do
                Dir.stub!(:[]).with("#{Dir.pwd}/templates/*").and_return ["pop"]
                ::File.stub!(:directory?).with("#{Dir.pwd}/templates").and_return true
                ::File.stub!(:directory?).and_return true
                @cloud.should_receive(:copy_template_to_storage_directory).with("pop", true).once
                @cloud.stub!(:copy_template_to_storage_directory).and_return true
                @cloud.copy_custom_templates
              end
            end
            it "should copy_custom_monitors" do
              @cloud.should_receive(:copy_custom_monitors).once
            end
            it "should call before_configuration_tasks callback" do
              @cloud.should_receive(:before_configuration_tasks).once
            end
            it "should call call write_unique_cookie" do
              @cloud.should_receive(:write_unique_cookie).once
            end
            describe "copy_custom_monitors" do
              before(:each) do                
                Default.stub!(:custom_monitor_directories).and_return ["/tmp/monitors/custom_monitor.rb"]
                Dir.stub!(:[]).with("#{Default.custom_monitor_directories}/*.rb").and_return ["/tmp/monitors/custom_monitor.rb"]
                @cloud.stub!(:copy_misc_templates).and_return true
                @cloud.stub!(:copy_file_to_storage_directory).and_return true
              end
              it "should call make_directory_in_storage_directory with monitors" do                
                @cloud.should_receive(:make_directory_in_storage_directory).with("monitors").once
                @cloud.stub!(:make_directory_in_storage_directory)
              end
              it "should copy the monitors into the monitor directory" do
                @cloud.should_receive(:copy_file_to_storage_directory).with("/tmp/monitors/custom_monitor.rb", "monitors").at_least(1)
                @cloud.stub!(:copy_file_to_storage_directory).and_return true
              end
              after(:each) do
                @cloud.copy_custom_monitors
              end
            end
            it "should store_keys_in_file" do
              @cloud.should_receive(:store_keys_in_file).once
            end
            it "should call save! on Script" do
              pending
            end
            it "should copy_ssh_key" do
              @cloud.should_receive(:copy_ssh_key).once
            end
            after(:each) do
              @cloud.prepare_for_configuration
            end
          end
          describe "building with an existing manifest" do
            before(:each) do
              @file = "/etc/puppet/manifests/nodes/nodes.pp"
              @file.stub!(:read).and_return "nodes generate"
              ::FileTest.stub!(:file?).with("/etc/puppet/manifests/classes/poolparty.pp").and_return true
              @cloud.stub!(:open).with("/etc/puppet/manifests/classes/poolparty.pp").and_return @file
            end
            it "should not call resources_string_from_resources if the file /etc/puppet/manifests/nodes/nodes.pp exists" do
              @cloud.should_not_receive(:add_poolparty_base_requirements)
              @cloud.build_manifest
            end
            it "should build from the existing file" do
              @cloud.build_manifest.should == "nodes generate"
            end
          end
        end
        describe "minimum_runnable_options" do
          it "should be an array on the cloud" do
            @cloud.minimum_runnable_options.class.should == Array
          end
          ["keypair","minimum_instances","maximum_instances",
            "expand_when","contract_when","set_master_ip_to"].each do |k|
            eval <<-EOE
              it "should have #{k} in the minimum_runnable_options" do
                @cloud.minimum_runnable_options.include?(:#{k}).should == true
              end
            EOE
          end
          it "should include the custom_minimum_runnable_options" do
            @cloud.stub!(:custom_minimum_runnable_options).and_return [:blank]
            @cloud.minimum_runnable_options.include?(:blank).should == true
          end
        end
        describe "unique_cookie" do
          it "should have the method generate generate_unique_cookie_string" do
            @cloud.respond_to?(:generate_unique_cookie_string).should == true
          end
          it "should call hexdigest to digest/sha" do
            Digest::SHA256.should_receive(:hexdigest).with("#{@cloud.keypair.basename}#{@cloud.name}").and_return "blaaaaah"
            @cloud.generate_unique_cookie_string
          end
          it "should generate the same cookie string every time" do
            older = @cloud.generate_unique_cookie_string
            old = @cloud.generate_unique_cookie_string
            new_one = @cloud.generate_unique_cookie_string
            older.should == old
            old.should == new_one
            new_one.should == older
          end
        end
      end

      # describe "instances" do
      #   before(:each) do
      #     @cloud3 = cloud :pop do;keypair "fake_keypair";end
      #     stub_list_from_remote_for(@cloud3)
      #   end
      #   it "should respond to the method master" do
      #     @cloud3.master.should_not be_nil
      #     @cloud3.respond_to?(:master).should == true
      #   end
      #   it "should return a master that is not nil" do
      #     @cloud3.master.should_not be_nil
      #   end
      # end
    end
  end
end