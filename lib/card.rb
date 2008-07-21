module ISO7816
module Card
  
  # Dummy implementation of `Card` to describe the provided interface
  class Card
    attr_reader :atr
    # Set up a connection to this card and return the ATR String.
    # May be called with a block which will be passed `self`. Card
    # will call `disconnect` at the end of the block 
    def connect
      raise "not implemented, use a subclass of `Card`!"
    end

    # disconnect from the card and free all resources.
    def disconnect
      raise "not implemented, use a subclass of `Card`!"
    end
    
    # Send bytes to the card.
    def send bytes=""
      raise "not implemented, use a subclass of `Card`!"
    end

    def reconnect
      disconnect
      connect
    end
  
    # receive a response from the card, optionally pass in the
    # number of expected bytes in the response, this value will be 1024
    # by default, which should be enough to hold most responses sent by
    # a card.
    def receive le=1024
      raise "not implemented, use a subclass of `Card`!"
    end

    def t0?
      raise "not implemented, use a subclass of `Card`!"
    end
  end #class Card
  
  class PCSCCard < Card
    # not yet implemented...
  end

  class LoggingCard < Card
    def initialize card
      @card = card
      @log = []
    end

    def connect &block
      if block_given?
        @card.connect 
        @log.push [:atr, @card.atr]
        yield self
        disconnect
      else
        @card.connect
        @log.push [:atr, @card.atr]
      end
    end

    def disconnect
      @card.disconnect
      @log.push [:disco, ""]
    end

    def send bytes
      @card.send bytes
      @log.push [:send, bytes]
    end

    def receive le=1024
      recv = @card.receive(le)
      @log.push [:recv, recv]
      recv
    end

    def t0?
      @card.t0?
    end

    def comment comment
      @log.push [:comment, comment]
    end
    
    DEFAULT_DUMP = lambda {|dir, b|
      prefix = case dir
               when :atr     then "ATR"
               when :send    then "  >"
               when :recv    then "  <"
               when :disco   then "CLIENT DISCONNECT"
               else               "#"
               end
      "%s %s" % [prefix, ISO7816.b2s(b)]
    }
    def dump io=STDOUT, formater=DEFAULT_DUMP
      @log.each{ |line|
        format = DEFAULT_DUMP.call(line[0], line[1])
        io.puts(format)
      }        
      
    end


  end

  # This implementation of card relies on 
  # socket communication, it expects an atr to be
  # send on TCP connect
  class TCPCard < Card
    SLEEP_TIME = 0.1
    def initialize addr="127.0.0.1", port=1024
      @addr = addr
      @port = port
    end

    def connect
      require 'socket'
      @socket = TCPSocket.new(@addr, @port)
      @connected = true
      
      sleep SLEEP_TIME 
      @atr = @socket.recv 1024,0 
      if block_given?
        yield self
        disconnect
      end
      @atr
    end

    def disconnect
      @socket.close if @socket && @connected
      @connected = false
      true
    end

    def connected?
      return false unless @connected
      # we're still connected, check if peer is still available
      true
    end

    def send bytes, flags=0
      raise "not connected" unless @connected
      bytes1 = bytes[0,5]
      bytes2 = bytes[5,bytes.length]
      @socket.send bytes1, flags
      # TCP2 echos back the ins byte, flags
      # according to ISO 7816-3 10.3.3
      proc_byte = @socket.recv 1, Socket::MSG_PEEK 
      # recv 90 60, INS, ...
      if proc_byte == "\x60" # null byte
        #
      elsif in_range(proc_byte, "\x61", "\x6f") || in_range(proc_byte, "\x90", "\x9f")
        @expect_sw=true
      else # INS being echoed back
        @socket.recv 1, 0
        @socket.send bytes2,flags
      end
    end
    
    def in_range byte, from, to
      byte >= from && byte <= to  
    end

    def receive le=nil
      raise "not connected" unless @connected
      
      if @expect_sw 
        le=2
        @expect_sw=nil
      end

      if le && Socket.const_defined?("MSG_WAITALL")
        # if we know the num bytes to receive, set MSG_WAIT_ALL
        flags = Socket::MSG_WAITALL
      elsif le
        data = ""
        data << @socket.recv(le, flags) while data.length < le
	return data
      else
        # set le to 1024 (default) and wait a little bit
        le = 1024
        sleep SLEEP_TIME
        flags = 0
      end

      #puts "Waiting to receive: #{le}"
      @socket.recv(le, flags)
    end

    def t0?
      true
    end
     
  end # class TCPCard
end # module Card
end # module ISO7816





# VERY VERY basic tests... Actual testing is in ../test/card_test.rb
if $0 == __FILE__
  card = ISO7816::Card::TCPCard.new "172.18.4.27", 1024
  puts "connecting"
  atr = card.connect
  puts "connected"
  puts atr.unpack("H*")[0]
  puts "disconnecting"
  card.disconnect
  puts "disconnected"
end
