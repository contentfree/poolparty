=begin rdoc
  Using method missing gives us the ability to set any attribute on the object into the options
  such that it can be retrieved later
=end
require "dslify"
module PoolParty
  module MethodMissingSugar
    # Method_Missing
    # When a method cannot be found on the current object
    # it is sent to method_missing
    # First, we check if there is a block given and if the block
    # is given with a class of the same type, then it is a block to be evaluated on 
    # itself, so we instantiate it here, otherwise, don't handle it here and let
    # the super class worry about it.
    # If the block is not given, then we are going to look for it on the 
    # options of itself or its parent.
    # See get_from_options for more information
    def method_missing(m, *args, &block)
      puts "MM: #{this.to_s}.#{m}(#{args.join(', ')}) #{this.name if self.respond_to? :name}"
      if block_given?
        (args[0].class == self.class) ? args[0].run_in_context(&block) : super
      else
        super
        # get_from_options(m, *args, &block)
      end
    end
    
    # Get the method from the options
    # First, we check to see if any options are being sent to the method
    # of the form:
    # name "Fred"
    # If there are args sent to it, check to see if it is an array
    # If it is, we want to send it an array only if the array is contains more than one element.
    # This becomes important when we are building the manifest
    # If it is not an array of more than one element, then we just send it the first of the args
    # If there are no args sent to it, then we check to see if the method is already in the options
    # which means we are retrieving the property
    # of the form
    # @cloud.name => @cloud.options[:name]
    # Finally, if the method name is not in the options, then we check to make sure it's not set on the 
    # parent, we don't want the parent's set option and that the parent isnot itself and send it
    # to the parent to handle. Otherwise, we'll say it's nil instead
    def get_from_options(m, *args, &block)
      if args.empty?
        if options.has_key?(m)
          puts " -> got #{m} from options of #{this}"
          this.options[m]
        elsif ret = get_option_from_parent(m)
           ret
        end
      else
        # require 'rubygems'; require 'ruby-debug'; debugger
        this.options[m] = 
        if (args.is_a?(Array) && args.size > 1)
          args
        else
          args[0]
        end
      end
    end
    
    def get_option_from_parent(m)
      if (!parent.nil? and parent.class != self.class and parent.respond_to?(:options) and parent.options.has_key?(m) and !parent.respond_to?(m))
        parent.send(m, *args, &block)
      end
    end
  
  end
end