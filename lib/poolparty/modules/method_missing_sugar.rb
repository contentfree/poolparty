=begin rdoc
  Using method missing gives us the ability to set any attribute on the object into the options
  such that it can be retrieved later
=end
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
      if block_given?
        (args[0].class == self.class) ? args[0].run_in_context(&block) : super
      else
        get_from_options(m, *args, &block)
      end
    end
    
    # Get the method from the options
    # First, we check to see if any options are being sent to the method
    # of the form:
    # name "Fred"
    # or
    # name = "Fred"
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
        options.has_key?(m)?options[m]:((!respond_to?(:parent) || parent.nil? || parent == self || !parent.respond_to?(:options) || parent.options.has_key?(m) || !parent.respond_to?(m)) ? nil : parent.send(m, *args, &block))
      else
        m = m.to_s.gsub(/\=/, "").to_sym
        options[m] = args.size>1?args:args[0]
      end
    end
    
  end
end