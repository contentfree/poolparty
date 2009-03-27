=begin rdoc
  The connection to the messenger from poolparty, the client.
  
  This class will setup a socket connection to the master's client
  at the messenger_client_port
=end
module PoolParty
  module Messenger
    def with_socket(testing=false, &block)
      host = testing ? "localhost" : (master.ip)
      vputs "Pinging #{host} with the messenger"
      socket = TCPSocket.open(host, Default.messenger_client_port)
      out = yield(socket)
      socket.close
      out
    end
    # TODO: Fix cookie setting
    def self.erl_command(hostname, extra="", min_ports=7000, max_ports=7050)
      command_line_opts = "-cookie -pa #{append_dir}/ebin -kernel inet_dist_listen_min #{min_ports} inet_dist_listen_max #{max_ports} -sname #{hostname}"
      
      "erl #{command_line_opts} #{extra}"
    end
    
    def self.append_dir
      ::File.expand_path(::File.join( ::File.dirname(__FILE__), "..", "..", "erlang/messenger" ))
    end
    
    def messenger_send!(msg="get_current_load cpu", testing=false)
      with_socket(testing) do |sock|
        sock.send(msg, 0)
        @str = sock.recv(2000)
      end
      vputs "Received #{@str} from #{msg}"
      @str
    end
    
    def messenger_cast!(msg="force_reconfig")
      with_socket do |sock|
        sock.send(msg, 0)
      end
    end
    
    def self.messenger_send!(cmd="", testing=false)      
      command = Messenger.erl_command("client#{Time.now.to_i}", "-s pm_client -run pm_client #{cmd} -s erlang halt -noshell")
      testing ? command : %x[#{command}]
    end
    
    # Helper methods
    def self.startup_remote_messenger(hostname, testing=false)
      # messenger_send!("")
      # testing ? command : %x[#{command}]
    end
    
  end
end