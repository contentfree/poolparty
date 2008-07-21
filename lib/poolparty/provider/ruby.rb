package :ruby do
  description 'Ruby Virtual Machine'
  apt %w( ruby ruby1.8-dev )
  requires :ruby_dependencies
  
  verify do
    has_executable 'ruby'
  end
end

package :ruby_dependencies do
  description 'Ruby Virtual Machine Build Dependencies'
  apt %w( bison zlib1g-dev libssl-dev libreadline5-dev libncurses5-dev file )
end

package :rubygems do
  description 'Ruby Gems Package Management System'
  version '1.2.0'
  source "http://rubyforge.org/frs/download.php/38646/rubygems-#{version}.tgz" do
    custom_install 'ruby setup.rb'
  end
  
  post :install, "sed -i s/require\ 'rubygems'/require\ 'rubygems'\nrequire\ 'rubygems\/gem_runner'/g", "gem update --system", "gem sources -a http://gems.github.com"
  
  requires :ruby
  
  verify do
    has_executable 'gem'
  end
end

package :required_gems do
  description "Poolparty required gem"
  gem 'auser-poolparty'
  requires :s3
  requires :ec2
  requires :aska
  
  has_gem 'auser-poolparty'
end

package :s3 do
  description "Amazon s3"
  gem 'aws-s3'
  
  has_gem 'aws-s3'
end
package :ec2 do
  description "Amazon EC2"
  gem 'amazon-ec2'
  
  has_gem 'amazon-ec2'
end
package :aska do
  description "Aska - Expert System"
  gem 'auser-aska'
  
  has_gem 'auser-aska'
end
package :rake do
  description "Rake"
  gem 'rake'
  
  has_gem 'rake'
end