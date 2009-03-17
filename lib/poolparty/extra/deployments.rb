module PoolParty
  module Extra
    class Deployments

      class << self
        
        def include_deployment(filename)
          return nil unless ::File.file? filename
          name = ::File.basename(filename, ::File.extname(filename))
          contents = open(filename).read

          plugin_klass = PoolParty::PluginModel::PluginModel.new(name)
          plugin_klass.klass.class_eval <<-EOE
            def enable
              #{contents}
            end
          EOE
          puts contents
          plugin_klass
        end
        
        def include_deployments(dir)
          return nil unless ::File.directory? dir
          Dir["#{dir}/*"].each do |fi|
            include_deployment fi
          end
          dir
        end
      end
    end    
  end
end