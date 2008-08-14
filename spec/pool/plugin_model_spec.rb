require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/test_plugins/webserver'

describe "Plugin" do
  before(:each) do
    
    @p = pool :poolpartyrb do
      cloud :app do
        apache do
          enable_php
          site("heady", {
            :document_root => "/root"
          })
        end
      end
    end        
  end
  describe "methods should include" do
    it "register_plugin(plugin)" do;WebServers.respond_to?(:register_plugin).should == true;end
  end
  describe "registered" do
    before(:each) do
      @plugin = "apache".class_constant.new
    end
    it "should store the regsitered plugins in an array" do
      @plugin.should_not be_nil
    end
    it "should have the plugin name as a method on the cloud " do
      PoolParty::Cloud::Cloud.respond_to?(:apache).should == true
    end
    describe "methods" do
      it "should call the enable_php method when in the defininition of the cloud" do
        @plugin.respond_to?(:enable_php).should == true
      end
      it "should call php = true in the enable_php" do
        @plugin.php.should_not == true
        @plugin.enable_php
        @plugin.php.should == true
      end
      it "should call the site method when in the defininition of the cloud" do
        @plugin.respond_to?(:site).should == true
      end
      it "should be able to call the plugin method site" do
        @plugin.site("hi", {:document_root => "/root"})
        @plugin.document_root.should == "/root"
      end
    end
  end
end