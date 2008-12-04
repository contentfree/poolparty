module PoolParty
  module CloudDsl
        
    def mount_ebs_volume_at(id="", loc="/data")
      ebs_volume_id id
      ebs_volume_mount_point loc
      ebs_volume_device "/dev/#{id.sanitize}"
      
      has_mount(:name => loc, :device => ebs_volume_device, :requires => get_directory(loc))
      has_directory(:name => loc)
    end
    
  end
end