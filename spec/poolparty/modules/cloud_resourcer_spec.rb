require File.dirname(__FILE__) + '/../spec_helper'

class ResourcerTestClass < PoolParty::Cloud::Cloud  
  default_options({
    :minimum_runtime => 50.minutes
  })
  
  # Stub keypair
  def keypair
    "rangerbob"
  end
end
class TestParentClass
  def services
    @services ||= []
  end
  def add_service(s)
    services << s
  end
end
describe "CloudResourcer" do
  before(:each) do
    @tc = ResourcerTestClass.new :bank do
      puts parent.class
    end
    puts "outside: #{@tc.parent.class}"
  end
  it "should have the method instances" do
    @tc.respond_to?(:instances).should == true
  end
  it "should be able to accept a range and set the first to the minimum instances" do
    @tc.instances 4..10
    @tc.minimum_instances.should == 4
  end
  it "should be able to accept a Fixnum and set the minimum_instances and maximum_instances" do
    @tc.instances 1
    @tc.minimum_instances.should == 1
    @tc.maximum_instances.should == 1
  end
  it "should set the max to the maximum instances to the last in a given range" do
    @tc.instances 4..10
    @tc.maximum_instances.should == 10
  end
  it "should have default minimum_runtime of 50 minutes (3000 seconds)" do
    Base.stub!(:minimum_runtime).and_return 50.minutes
    @tc.minimum_runtime.should ==  50.minutes
  end
  it "should have minimum_runtime" do
    @tc.minimum_runtime 40.minutes
    @tc.minimum_runtime.should == 40.minutes
  end
  describe "keypair_path" do
    before(:each) do
    end
    it "should look for the file in the known directories it should reside in" do
      @tc.should_receive(:keypair_paths).once.and_return []
      @tc.keypair_path
    end
    it "should see if the file exists" do
      @t = "#{File.expand_path(Base.base_keypair_path)}"
      ::File.should_receive(:exists?).with(@t+"/id_rsa-rangerbob").and_return false
      ::File.stub!(:exists?).with(@t+"/rangerbob").and_return false
      @tc.should_receive(:keypair_paths).once.and_return [@t]
      @tc.keypair_path
    end
    it "should fallback to the second one if the first doesn't exist" do
      @t = "#{File.expand_path(Base.base_keypair_path)}"
      @q = "#{File.expand_path(Base.base_config_directory)}"
      ::File.stub!(:exists?).with(@t+"/id_rsa-rangerbob").and_return false
      ::File.stub!(:exists?).with(@t+"/rangerbob").and_return false
      ::File.stub!(:exists?).with(@q+"/id_rsa-rangerbob").and_return false
      ::File.should_receive(:exists?).with(@q+"/rangerbob").and_return true
      @tc.should_receive(:keypair_paths).once.and_return [@t, @q]
      @tc.keypair_path.should == "/etc/poolparty/rangerbob"
    end
    describe "exists" do
      before(:each) do
        @t = "#{File.expand_path(Base.base_keypair_path)}"
        ::File.stub!(:exists?).with(@t+"/id_rsa-rangerbob").and_return false
        ::File.stub!(:exists?).with(@t+"/rangerbob").and_return true
      end
      it "should have the keypair_path" do
        @tc.respond_to?(:keypair_path).should == true
      end
      it "should set the keypair to the Base.keypair_path" do      
        @tc.keypair_path.should =~ /\.ec2\/rangerbob/
      end
      it "should set the keypair to have the keypair set" do
        @tc.keypair.should =~ /rangerbob/
      end
      it "should set it to the Base keypair_path and the keypair" do
        @tc.keypair_path.should == "#{File.expand_path(Base.base_keypair_path)}/#{@tc.keypair}"
      end
    end
  end
  it "should provide set_parent" do
    @tc.respond_to?(:set_parent).should == true
  end
  describe "parents" do
    before(:each) do
      @testparent = TestParentClass.new
      @testparent.options[:test_option] = "blankity blank blank"
    end
    describe "setting" do
      it "should add the child to its services" do
        @testparent.should_receive(:add_service)
      end
      it "should call merge onto parent.options with @tc options" do
        @tc.should_receive(:configure).with(@testparent.options)      
      end
      it "should have the parent's test_option on the object itself" do
        @tc.options[:test_option].should_equal "blankity blank blank"
      end
      after do
        @tc.run_setup(@testparent)
      end      
    end
    describe "parent's services" do
      before(:each) do        
        @tc.run_setup(@testparent)        
      end
      it "should set the parent" do
        @tc.parent.should == @testparent
      end
      it "should have one service set" do
        @testparent.services.size.should == 1
      end
      it "should have the child in the parent's services" do
        @testparent.services.first.should == @tc
      end
    end
    describe "storing block" do
      before(:each) do
        @new_tc = ResourcerTestClass.new do
          "hi"
        end
      end
      it "should store the block when creating a new one" do
        @new_tc.store_block.should_not == nil
      end
      it "should have a reference to the stored block" do
        @new_tc.store_block.class.should == Proc
      end
      it "should store the containing block" do
        @new_tc.store_block.call.should == "hi"
      end
    end
  end
end