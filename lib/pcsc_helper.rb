require 'smartcard'
module ISO7816
module PCSC

# adds default params to Smartcard to make them easier to work with.

class Context < Smartcard::PCSC::Context
    def initialize scope=Smartcard::PCSC::SCOPE_SYSTEM
      super
    end

    def list_readers reader_groups=nil
      super
    end
end

class Card < Smartcard::PCSC::Card
  include Smartcard::PCSC
  attr_accessor :ctx  
  def initialize( context             = nil, 
                  reader_name         = nil, 
                  share_mode          = SHARE_EXCLUSIVE,
                  preferred_protocol  = PROTOCOL_ANY)

    @ctx                  = context     || ISO7816::PCSC::Context.new
    @r_name               = reader_name || @ctx.list_readers()[0]
    @share_mode           = share_mode
    @preferred_protocol   = preferred_protocol

    super(@ctx, @r_name, @share_mode, @preferred_protocol)
  end

  def disconnect disposition=DISPOSITION_UNPOWER, release_context=true
    super(disposition)
    @ctx.release if release_context
  end

  def reconnect share=nil, preferred_protocol=nil, ini= INITIALIZATION_UNPOWER
    # use and remember passed params if set, else reuse last remembered params.
    share ||= @share_mode
    preferred_protocol ||= @preferred_protocol
    
    @share_mode = share
    @preferred_protocol = preferred_protocol
        
    @status = nil
    puts @share_mode.class
    puts @preferred_protocol.class
    puts ini.class
    super(@share_mode, @preferred_protocol, ini)
  end

  def _status
    @status ||= self.status
  end

  def transmit send_data, send_io_request=nil, recv_io_request=nil
    unless send_io_request
      protocol = _status[:protocol]
      send_io_request = case protocol
                        when PROTOCOL_T0:
                          IOREQUEST_T0
                        when PROTOCOL_T1:
                                puts "T1"
                          IOREQUEST_T1
                        when Smartcard::PCSC::PROTOCOL_RAW:
                          IOREQUEST_RAW
                        else
                          raise "weird protocol: #{protocol}"
                        end        
    end # send_io_request

    recv_io_request ||= Smartcard::PCSC::IoRequest.new
    super(send_data, send_io_request, recv_io_request)
  end

  def atr
    _status[:atr]
  end
  def protocol?
    case _status[:protocol]
    when PROTOCOL_T0
            "T0"
    when PROTOCOL_T1
            "T1"
    when PROTOCOL_RAW
            "RAW"
    when PROTOCOL_T15
            "T15"
    when PROTOCOL_UNKNOWN
            "UNKNOWN"
    else 
            "UNKNOWN_UNKNOWN"
    end
  end
end #card

end # pcsc
end # iso7816



