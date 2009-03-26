desc "Run the specs"
task :slow_spec do
  Dir["#{::File.dirname(__FILE__)}/../spec/poolparty/**/*_spec.rb"].each do |sp|
    puts `spec #{sp}`
  end
end
namespace(:poolparty) do
  namespace(:setup) do
    desc "Generate a manifest for quicker loading times"
    task :manifest do
      $GENERATING_MANIFEST = true
      out = capture_stdout do
        $_poolparty_load_directories.each do |dir|
          PoolParty.require_directory ::File.join(::File.dirname(__FILE__), '../lib/poolparty', dir)
        end
      end
      ::File.open(::File.join(::File.dirname(__FILE__), '../config', "manifest.pp"), "w+") {|f| f << out.map {|f| "#{f}"} }
      puts "Manifest created"
    end
  end
  namespace :vendor do
    desc "Initialize the submodules"
    task :setup do
      `git submodule init`
    end
    desc "Update the submodules"
    task :update do
      `git submodule update`
    end
  end
  namespace :deps do
    task :clean_gem_cache do
      gem_location = "#{::File.dirname(__FILE__)}/../vendor/dependencies"
      cache_dir = "#{gem_location}/cache"
      Dir["#{cache_dir}/*.gem"].each {|file| ::File.unlink file }
    end
    desc "Update dependencies gem"
    task :update => [:clean_gem_cache] do
      gem_location = "#{::File.dirname(__FILE__)}/../vendor/dependencies"
      PoolParty::Dependencies.gems open("#{gem_location}/gems_list").read.split("\n"), gem_location
      PoolParty::Dependencies.packages ['http://rubyforge.org/frs/download.php/45905/rubygems-1.3.1.tgz'], gem_location
    end
  end
end