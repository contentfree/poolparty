module PoolParty
  class Schema
    attr_accessor :hsh
    def initialize(h={})
      @hsh = {}
      case h
      when Hash
        h.each {|k,v| self[k] = v}
      when String        
        JSON.parse(h).each {|k,v| self[k.to_sym] = v}
      end
    end

    def [](k)
      hsh[k]
    end
    
    def []=(k,v)
      if v.is_a?(Hash)
        hsh[k.to_sym] = self.class.new(v)
      else
        hsh[k.to_sym] = v
      end      
    end

    def to_hash
      @hsh
    end
    
    def save!
      ::File.open("#{Default.base_config_directory}/#{Default.properties_hash_filename}", "w") {|f| f << self.to_json }
    end
    
    def method_missing(sym, *args, &block)
      if @hsh.has_key?(sym.to_sym)
        @hsh.fetch(sym)
      elsif @hsh.has_key?(sym.to_s)
        @hsh.fetch(sym.to_s)
      else
        @hsh.send(sym, *args, &block)
      end
    end
  end
end
# class Hash
#   def [](k=nil)
#     if self.has_key?(k.to_sym)
#       fetch(k.to_sym)
#     elsif self.has_key?(k.to_s)
#       fetch(k.to_s)
#     else
#       nil
#     end
#   end
#   def method_missing(sym, *args, &block)
#     if has_key?(sym.to_sym)
#       fetch(sym)
#     elsif has_key?(sym.to_s)
#       fetch(sym.to_s)
#     else
#       super
#     end
#   end  
# end