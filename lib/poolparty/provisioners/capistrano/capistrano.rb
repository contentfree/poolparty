require "poolparty/capistrano"

module PoolParty
  module Provisioner
    class Capistrano < ProvisionerBase
      
      include ::Capistrano::Configuration::Actions::Invocation
      
      def loaded
        dputs "Capistrano provisioner loaded..."
        create_config
      end
      def process_install!(testing=false)
        unless testing
          @cloud.rsync_storage_files_to(@instance)
          run_capistrano(roles_to_provision, :install)
        end
      end
      def process_configure!(testing=false)
        unless testing
          @cloud.rsync_storage_files_to(@instance)
          run_capistrano(roles_to_provision, :configure)
        end
      end
      
      def install_tasks
        provision_master? ? master_install_tasks : slave_install_tasks
      end
      def configure_tasks
        provision_master? ? master_configure_tasks : slave_configure_tasks
      end
      def master_install_tasks
        [
          "custom_install_tasks",
          "master_provision_master_task",
          "after_install_tasks",
          "custom_configure_tasks",
          "before_configuration_tasks",
          "master_configure_master_task",
          "run_provisioner_twice"
        ]#.map {|a| a.to_sym }
      end
      def master_configure_tasks
        [
          "before_configuration_tasks",
          "master_configure_master_task"
        ]#.map {|a| a.to_sym }
      end
      
      def slave_install_tasks
        [
          "custom_install_tasks",
          "slave_provision_slave_task",
          "after_install_tasks",
          "custom_configure_tasks",
          "slave_configure_slave_task"
        ]
      end
      def slave_configure_tasks
        [
          "custom_configure_tasks",
          "slave_configure_slave_task"
        ]#.flatten.map {|a| a.to_sym }
      end
            
      def set_poolparty_roles
        return "" if testing
        returning Array.new do |arr|
          arr << "role 'master.#{cloud.name}'.to_sym, '#{cloud.ip}'"
          arr << "role :master, '#{cloud.ip}'"
          arr << "role :slaves, '#{cloud.nonmaster_nonterminated_instances.map{|a| a.ip}.join('", "')}'" if cloud.nonmaster_nonterminated_instances.size > 0
          arr << "role :single, '#{@instance.ip}'" if @instance && @instance.ip
        end.join("\n")
      end
      
      def parent
        @cloud
      end
      
      # Create the config for capistrano
      # This is a dynamic capistrano configuration file
      def create_config
        @config = ::Capistrano::Configuration.new
        if @cloud.debug || @cloud.verbose 
          @config.logger.level = @cloud.debug ? ::Capistrano::Logger::MAX_LEVEL : ::Capistrano::Logger::INFO
        else
          @config.logger.level = ::Capistrano::Logger::IMPORTANT
        end
        
        capfile = returning Array.new do |arr|
          Dir["#{::File.dirname(__FILE__)}/recipes/*.rb"].each {|a| arr << "require '#{a}'" }
          arr << "ssh_options[:keys] = '#{parent.keypair}'"
          
          arr << set_poolparty_roles
        end.join("\n")
        
        @config.provisioner = self
        @config.cloud = @cloud
        
        @config.load(:string => capfile)
        
        @cloud.deploy_file? ? @config.load(@cloud.deploy_file) : @config.set(:user, @cloud.user)
      end
      
      # Prerun
      def prerun_setup
      end
      
      # In run_capistrano, we are going to run the entire capistrano process
      # First, 
      def run_capistrano(roles = [:master], meth = :install)
        prerun_setup
        commands = (meth == :install ? install_tasks : configure_tasks)
        name = "#{roles.first}_provisioner_#{meth}"

        __define_task(name, roles) do
          commands.map do |command|
            puts "executing task #{command}"
            task = find_task(command.to_sym)
            if task
              task.options.merge!(:roles => roles)
              execute_task task
            else
              if provisioner.respond_to?(command.to_sym)
                cmd = provisioner.send(command.to_sym)
                cmd = cmd.join(" && ") if cmd.is_a?(Array)
                run(cmd)
              else
                self.send(command.to_sym)
              end
            end
          end
        end
                
        begin
          __run(name)
          return true
        rescue ::Capistrano::CommandError => e
          return false unless verbose
          puts "Error: #{e} " and raise ProvisionerException.new("Error: #{e}")
        end
      end
                  
      def __define_task(name, roles, &block)
        @config.task __task_sym(name), :roles => roles, &block
      end

      def __run(task)
        @config.send __task_sym(task)
      end

      def __task_sym(name)
        "#{name.to_s.downcase.underscore}".to_sym
      end
      
    end
  end
end