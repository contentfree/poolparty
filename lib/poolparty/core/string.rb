class String
  def hasherize(format=[])
    hash = {}
    i = 0
    self.split(%r{[\n|\t|\s| ]+}).map {|a| a.strip}.each do |f|
      next unless format[i]
      unless f == "" || f.nil?
        hash[format[i].to_sym] = f
        i+=1
      end      
    end
    hash
  end
  def ^(h={})
    self.gsub(/:([\w]+)/) {h[$1.to_sym] if h.include?($1.to_sym)}
  end
  def grab_filename_from_caller_trace
    self.gsub(/\.rb(.*)/, '.rb')
  end
  def arrayable
    self.strip.split(/\n/)
  end
  def runnable(quite=true)
    # map {|l| l << "#{" >/dev/null 2>/dev/null" if quite}" }.
    self.strip.split(/\n/).join(" && ")
  end
  def top_level_class
    self.split("::")[-1].underscore.downcase rescue self.class.to_s
  end
  def sanitize
    self.gsub(/[ \.\/\-]*/, '')
  end
  def keyerize
    signed_short = 0x7FFFFFFF
    len = self.sanitize.length
    hash = 0 
    len.times{ |i| 
      hash = self[i] + ( hash << 6 ) + ( hash << 16 ) - hash 
    } 
    hash & signed_short
  end
  def dir_safe
    self.downcase.gsub(/[ ]/, '_')
  end
  def safe_quote
    self.gsub(/['"]/, '\\\"')
    # self.gsub(/["']/, "\\\"")
  end
  def nice_runnable(quite=true)
    self.split(/ && /).join("\n")
  end

  # Refactor this guy to get the class if the class is defined, and not always create a new one
  # although, it doesn't really matter as ruby will just reopen the class
  def class_constant(superclass=nil, opts={}, &block)
    symc = ((opts && opts[:preserve]) ? ("#{self.camelcase}Classs") : "PoolParty#{self.camelcase}Classs").classify
    
    kla=<<-EOE
      class #{symc} #{"< #{superclass}" if superclass}
      end
    EOE
    
    Kernel.module_eval kla
    klass = symc.constantize
    klass.module_eval &block if block
    
    klass
  end
  
  def camel_case
    gsub(/(^|_|-)(.)/) { $2.upcase }
  end
  
  # "FooBar".snake_case #=> "foo_bar"
   def snake_case
     gsub(/\B[A-Z]+/, '_\&').downcase
   end
   
    # "FooBar".dasherize #=> "foo-bar"
    def dasherize
      gsub(/\B[A-Z]+/, '-\&').downcase
    end
    
  # Constantize tries to find a declared constant with the name specified
  # in the string. It raises a NameError when the name is not in CamelCase
  # or is not initialized.
  #
  # Examples
  #   "Module".constantize #=> Module
  #   "Class".constantize #=> Class
  def constantize
    camel_cased_word = camel_case
    begin
      Object.module_eval(camel_cased_word, __FILE__, __LINE__)
    rescue NameError
      puts "#{camel_cased_word} is not defined."
      nil
    end
  end
  
  def preserved_class_constant(append="")
    klass = "#{self}#{append}".classify
    Object.const_defined?(klass.to_sym) ? klass.to_s.constantize : nil
  end
  
  def module_constant(append="", &block)
    symc = "#{self}_Module#{append}".camelcase
    mod = Object.const_defined?(symc) ? Object.const_get(symc.to_sym) : Module.new(&block)
    Object.const_set(symc, mod) unless Object.const_defined?(symc)
    symc.to_s.constantize
  end
  def preserved_module_constant(ext="", from="PoolParty::", &block)
    symc = "#{self}#{ext}".camelcase
    mod = Kernel.const_defined?(symc) ? Kernel.const_get(symc.to_sym) : Module.new(&block)
    Kernel.const_set(symc, mod) unless Kernel.const_defined?(symc)
    symc.to_s.constantize
  end
  def collect_each_line_with_index(&block)
    returning [] do |arr|
      arr << self.split(/\n/).collect_with_index(&block)
    end.flatten
  end
end