=begin rdoc
  The base for Remote Bases
  
  By extending this class, you can easily add remoters to 
  PoolParty. There are 4 methods that the remote base needs to implement
  in order to be compatible.
  
  The four methods are:
    launch_new_instance!
    terminate_instance(id)
    describe_instance(id)
    describe_instances
  
  After your remote base is written, make sure to register the base outside the context
  of the remote base, like so:
    register_remote_base :remote_base_name
  
=end

module PoolParty

  module Remote    
    # This class is the base class for all remote types, such as ec2
    # Everything remoting-wise is derived from this class
    class RemoterBase
      include  ::PoolParty::Remote
      
      def initialize(prnt = nil)
        @parent = prnt
      end
      
      def method_missing(meth, *args, &block)
        if @parent
          @parent.send meth, *args, &block rescue super
        else
          super
        end
      end
      
      # Required methods
      # The next methods are required on all RemoteInstance types
      # If your RemoteInstance type does not overwrite the following methods
      # An exception will be raised and poolparty will explode into tiny little 
      # pieces. Don't forget to overwrite these methods
      # Launch a new instance
      def self.launch_new_instance!(o={})
        raise RemoteException.new(:method_not_defined, "launch_new_instance!")
      end
      def self.expand(o={});launch_new_instance!(o);end
      def launch_new_instance!(o={})
        self.class.launch_new_instance!( options.merge(o) )
      end
      
      # Terminate an instance by id
      def self.terminate_instance!(o={})
        raise RemoteException.new(:method_not_defined, "terminate_instance!")
      end
      def self.contract(o={});terminate_instance!(o);end      
      def terminate_instance!(o={})
        self.class.terminate_instance!(o ? options.merge(o) : options)
      end
      
      # Describe an instance's status
      def self.describe_instance(o={})
        raise RemoteException.new(:method_not_defined, "describe_instance")
      end
      def describe_instance(o={})
        self.class.describe_instance(o ? options.merge(o) : options)
      end
      
      # Get instances
      # The instances must have a status associated with them on the hash
      def self.describe_instances(o={})
        raise RemoteException.new(:method_not_defined, "describe_instances")
      end
      def describe_instances(o={})
        self.class.describe_instances(o ? options.merge(o) : options)
      end
      
      # TODO: Rename and modularize the @inst.status =~ /pending/ so that it works on all 
      # remoter_bases
      def self.launch_instance!(o={}, &block)
        @inst = launch_new_instance!( o )
        sleep(2)
        500.times do |i|
          if @inst.status =~ /pending/
            sleep(2)
            @inst = describe_instance(@inst)          
          end
        end
        when_instance_is_responding @inst do
          block.call(@inst) if block
          after_launch_instance(@inst)
        end
        @inst
      end
      def launch_instance!(o={}, &block); self.class.launch_instance!(self.options.merge(o), &block);end

      # Called after an instance is launched
      def self.after_launch_instance(instance=nil);end

      def self.when_instance_is_responding(inst, &block)
        if ping_port(inst.ip, 22)
          block.call if block
        else
          raise "Instance not responding at #{inst.ip}"
        end
      end
      def when_instance_is_responding(inst, &block);self.class.when_instance_is_responding;end
      
      # TODO: BAD FORM, already defined in connections.rb. Fix this, ASAP
      def self.ping_port(host, port=22, retry_times=400)
        connected = false
        retry_times.times do |i|
          begin
            break if connected = TCPSocket.new(host, port).is_a?(TCPSocket)
          rescue Exception => e
            sleep(2)
          end
        end
        connected
      end
      
      # After launch callback
      # This is called after a new instance is launched
      def after_launched(force=false)        
      end
      
      # Before shutdown callback
      # This is called before the cloud is contracted
      def before_shutdown
      end
      
    end
    
  end
end

Dir["#{File.dirname(__FILE__)}/remoter/*.rb"].each do |remoter_module| 
  require remoter_module
end