class TestEC2Class < Ec2
  include CloudResourcer
  include CloudDsl
  
  def keypair;"fake_keypair";  end
  def ami;"ami-abc123";end
  def size; "small";end
  def security_group; "default";end
  def ebs_volume_id; "ebs_volume_id";end
  def availabilty_zone; "us-east-1a";end
  def verbose; false; end
  def ec2
    @ec2 ||= EC2::Base.new( :access_key_id => "not_an_access_key", :secret_access_key => "not_a_secret_access_key")
  end
  def describe_instances
    response_list_of_instances
  end
end

# module PoolParty  
#   module Remote
    class TestEc2RemoteInstance < PoolParty::Remote::Ec2RemoteInstance
      def initialize(opts, parent=TestEC2Class.new)
        super(opts, parent)
      end
    end
#   end
# end