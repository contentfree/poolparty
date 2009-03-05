require File.join(File.dirname(__FILE__), "resource")

module PoolParty    
  module PluginModel
    
    def plugin(name=:plugin, cloud=nil, &block)
      plugins.has_key?(name) ? plugins[name] : (plugins[name] = PluginModel.new(name, &block))
    end
    alias_method :register_plugin, :plugin
    
    def plugins
      $plugins ||= {}
    end
    
    class PluginModel      
      attr_accessor :name, :klass
      include MethodMissingSugar
      include Configurable
      include PrettyPrinter
      
      def initialize(name,&block)
        @name = name
        # @parent = cld
        class_string_name = "#{name}"
        
        # Create the class to evaluate the plugin on the implemented call
        @klass = klass = class_string_name.class_constant(PoolParty::Plugin::Plugin)
        mod = class_string_name.module_constant(&block)
        
        klass.send :include, mod
        
        # Store the name of the class for pretty printing later
        # klass.name = name
        # Add the plugin definition to the cloud as an instance method
        PoolParty::Cloud::Cloud.class_eval <<-EOE
          def #{name}(parent=self, &block)
            @pa = parent
            @#{class_string_name.downcase} ||= returning #{class_string_name.class_constant}.new(parent, &block) do |pl|
              @pa.plugin_store << pl
            end
          end
        EOE
      end
      
    end
    
  end
end