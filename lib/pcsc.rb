

module PCSC
  
  

  class Context
    def initialize
      @ctx = Lib.sCardEstablishContext 
    end
    def release
      Lib.sCardReleaseContext @ctx
    end
    # compare to Lib::Errors
    def is_valid
      Lib.sCardIsValidContext @ctx
    end

    def list_readers
      Lib.sCardListReaders @ctx
    end
#    TODO
#    def list_reader_groups
#      Lib.sCardListReaderGroups @ctx
#    end
    def card_connect reader=nil, shared=Lib::ShareMode::SCARD_SHARE_SHARED, proto=Lib::Protocol::SCARD_PROTOCOL_ANY
      reader ||= list_readers[0]
      card, proto = Lib.sCardConnect @ctx, reader, shared, proto
      Card.new(card, proto)
    end

  end
  
  class Card
  
    attr_writer :ctx
    
    def self.connect
      ctx = Context.new
      ctx.initialize
      card, proto = ctx.card_connect
      c = Card.new card, proto
      c.ctx = ctx
    end

    def initialize card, proto
      @card=card
      @proto=proto
    end

    def reconnect shared=Lib::ShareMode::SCARD_SHARE_SHARED, proto=nil, init=Lib::Disposition::SCARD_LEAVE_CARD
      proto ||= @proto
      @proto = Lib.sCardReconnect @card, shared, proto, init 
    end

    def disconnect disposition=Lib::Disposition::SCARD_UNPOWER_CARD
      Lib.sCardDisconnect(@card, disposition)
      @card = -1
      @ctx && @ctx.release
    end

    def transaction disposition=Lib::Disposition::SCARD_LEAVE_CARD
      Lib.sCardBeginTransaction @card
      yield self
      Lib.sCardEndTransaction @card, disposition
    end

    def transmit
    end

    def status 
      @state, @proto, @atr = Lib.sCardStatus(@card)
      [@state, @proto, @atr]
    end
  end

  module Lib
    require 'dl'
    require 'dl/import'

    module Scope
      # from pcsclite.h
      SCARD_SCOPE_USER = 0
      SCARD_SCOPE_TERMINAL = 1
      SCARD_SCOPE_SYSTEM = 2
      SCARD_SCOPE_GLOBAL = 3
    end

    module Disposition
      SCARD_LEAVE_CARD = 0x0000 #	/**< Do nothing on close */
      SCARD_RESET_CARD = 0x0001 #	/**< Reset on close */
      SCARD_UNPOWER_CARD = 0x0002 #	/**< Power down on close */
      SCARD_EJECT_CARD = 0x0003 #	/**< Eject on close */
    end

    module Protocol
      SCARD_PROTOCOL_UNSET  = 0x0000 #	/**< protocol not set */
      SCARD_PROTOCOL_T0     = 0x0001 #	/**< T=0 active protocol. */
      SCARD_PROTOCOL_T1     = 0x0002 #	/**< T=1 active protocol. */
      SCARD_PROTOCOL_RAW    = 0x0004 #	/**< Raw active protocol. */
      SCARD_PROTOCOL_T15    = 0x0008 #	/**< T=15 protocol. */
      SCARD_PROTOCOL_ANY    = (SCARD_PROTOCOL_T0|SCARD_PROTOCOL_T1) #	/**< IFD determines prot. */

    end
    
    module ShareMode
      SCARD_SHARE_EXCLUSIVE = 0x0001 #  /**< Exclusive mode only */
      SCARD_SHARE_SHARED    = 0x0002 #  /**< Shared mode only */
      SCARD_SHARE_DIRECT    = 0x0003 #  /**< Raw mode only */
    end

    module Errors
      SCARD_S_SUCCESS = 0x00000000
      SCARD_E_CANCELLED = 0x80100002
      SCARD_E_CANT_DISPOSE = 0x8010000E
      SCARD_E_INSUFFICIENT_BUFFER = 0x80100008
      SCARD_E_INVALID_ATR = 0x80100015
      SCARD_E_INVALID_HANDLE = 0x80100003
      SCARD_E_INVALID_PARAMETER = 0x80100004
      SCARD_E_INVALID_TARGET = 0x80100005
      SCARD_E_INVALID_VALUE = 0x80100011
      SCARD_E_NO_MEMORY = 0x80100006
      SCARD_F_COMM_ERROR = 0x80100013
      SCARD_F_INTERNAL_ERROR = 0x80100001
      SCARD_F_UNKNOWN_ERROR = 0x80100014
      SCARD_F_WAITED_TOO_LONG = 0x80100007
      SCARD_E_UNKNOWN_READER = 0x80100009
      SCARD_E_TIMEOUT = 0x8010000A
      SCARD_E_SHARING_VIOLATION = 0x8010000B
      SCARD_E_NO_SMARTCARD = 0x8010000C
      SCARD_E_UNKNOWN_CARD = 0x8010000D
      SCARD_E_PROTO_MISMATCH = 0x8010000F
      SCARD_E_NOT_READY = 0x80100010
      SCARD_E_SYSTEM_CANCELLED = 0x80100012
      SCARD_E_NOT_TRANSACTED = 0x80100016
      SCARD_E_READER_UNAVAILABLE = 0x80100017
      
      SCARD_W_UNSUPPORTED_CARD = 0x80100065 #
      SCARD_W_UNRESPONSIVE_CARD = 0x80100066 #
      SCARD_W_UNPOWERED_CARD = 0x80100067 #
      SCARD_W_RESET_CARD = 0x80100068 #
      SCARD_W_REMOVED_CARD = 0x80100069 #

      SCARD_E_PCI_TOO_SMALL = 0x80100019 #
      SCARD_E_READER_UNSUPPORTED = 0x8010001A #
      SCARD_E_DUPLICATE_READER = 0x8010001B #
      SCARD_E_CARD_UNSUPPORTED = 0x8010001C #
      SCARD_E_NO_SERVICE = 0x8010001D #
      SCARD_E_SERVICE_STOPPED = 0x8010001E #

      ERRS = {SCARD_S_SUCCESS => "SCARD_S_SUCCESS",
      SCARD_E_CANCELLED => "SCARD_E_CANCELLED",
      SCARD_E_CANT_DISPOSE => "SCARD_E_CANT_DISPOSE",
      SCARD_E_INSUFFICIENT_BUFFER => "SCARD_E_INSUFFICIENT_BUFFER",
      SCARD_E_INVALID_ATR => "SCARD_E_INVALID_ATR",
      SCARD_E_INVALID_HANDLE => "SCARD_E_INVALID_HANDLE",
      SCARD_E_INVALID_PARAMETER => "SCARD_E_INVALID_PARAMETER",
      SCARD_E_INVALID_TARGET => "SCARD_E_INVALID_TARGET",
      SCARD_E_INVALID_VALUE => "SCARD_E_INVALID_VALUE",
      SCARD_E_NO_MEMORY => "SCARD_E_NO_MEMORY",
      SCARD_F_COMM_ERROR => "SCARD_F_COMM_ERROR",
      SCARD_F_INTERNAL_ERROR => "SCARD_F_INTERNAL_ERROR",
      SCARD_F_UNKNOWN_ERROR => "SCARD_F_UNKNOWN_ERROR",
      SCARD_F_WAITED_TOO_LONG => "SCARD_F_WAITED_TOO_LONG",
      SCARD_E_UNKNOWN_READER => "SCARD_E_UNKNOWN_READER",
      SCARD_E_TIMEOUT => "SCARD_E_TIMEOUT",
      SCARD_E_SHARING_VIOLATION => "SCARD_E_SHARING_VIOLATION",
      SCARD_E_NO_SMARTCARD => "SCARD_E_NO_SMARTCARD",
      SCARD_E_UNKNOWN_CARD => "SCARD_E_UNKNOWN_CARD",
      SCARD_E_PROTO_MISMATCH => "SCARD_E_PROTO_MISMATCH",
      SCARD_E_NOT_READY => "SCARD_E_NOT_READY",
      SCARD_E_SYSTEM_CANCELLED => "SCARD_E_SYSTEM_CANCELLED",
      SCARD_E_NOT_TRANSACTED => "SCARD_E_NOT_TRANSACTED",
      SCARD_E_READER_UNAVAILABLE => "SCARD_E_READER_UNAVAILABLE",

      SCARD_W_UNSUPPORTED_CARD => "SCARD_W_UNSUPPORTED_CARD",
      SCARD_W_UNRESPONSIVE_CARD => "SCARD_W_UNRESPONSIVE_CARD",
      SCARD_W_UNPOWERED_CARD => "SCARD_W_UNPOWERED_CARD",
      SCARD_W_RESET_CARD => "SCARD_W_RESET_CARD",
      SCARD_W_REMOVED_CARD => "SCARD_W_REMOVED_CARD",

      SCARD_E_PCI_TOO_SMALL => "SCARD_E_PCI_TOO_SMALL",
      SCARD_E_READER_UNSUPPORTED => "SCARD_E_READER_UNSUPPORTED",
      SCARD_E_DUPLICATE_READER => "SCARD_E_DUPLICATE_READER",
      SCARD_E_CARD_UNSUPPORTED => "SCARD_E_CARD_UNSUPPORTED",
      SCARD_E_NO_SERVICE => "SCARD_E_NO_SERVICE",
      SCARD_E_SERVICE_STOPPED => "SCARD_E_SERVICE_STOPPED"
      
      }
    end
    
#    module SCards extend DL::Importable
#      dlload '/System/Library/Frameworks/PCSC.framework/Versions/A/PCSC'
#    end
      
      
    LIB = DL.dlopen('/System/Library/Frameworks/PCSC.framework/Versions/A/PCSC')

    def Lib.sCardEstablishContext
      @scec ||= LIB['SCardEstablishContext', 'LLPPP']

      ptr = DL.malloc(DL.sizeof('L'))
      r,rs = @scec.call(Scope::SCARD_SCOPE_SYSTEM, nil, nil, ptr)

      r &= 0xffffffff 
      raise Errors::ERRS[r] unless r == Errors::SCARD_S_SUCCESS # TODO error mappings
#      puts "%x" % ptr.to_i
#      puts "%d" % ptr.to_i
#      puts ptr.ptr.to_i
#      obj = Object.new
#      puts ptr.methods - obj.methods
      ret = ptr.ptr.to_i
      ptr.free
      return ret
    end

    def Lib.sCardReleaseContext ctx
#      puts ctx
      @scrc ||= LIB['SCardReleaseContext', 'LL']
      r,rs = @scrc.call(ctx)
      r &= 0xffffffff
      raise Errors::ERRS[r] unless r == Errors::SCARD_S_SUCCESS # TODO error mappings
    end

    def Lib.sCardIsValidContext ctx
      puts ctx
      @scivc ||= LIB['SCardIsValidContext', 'LL']
      r, rs = @scivc.call(ctx)
      r &= 0xffffffff
      return 0
    end

    def Lib.sCardListReaders ctx
      @sclr ||= LIB['SCardListReaders', 'LLPPP']
      
      longp = DL.malloc(DL.sizeof('L'))
      r, rs = @sclr.call(ctx, nil, nil, longp)
      len = longp.ptr.to_i
      strp = DL.malloc(DL.sizeof('C')*len)
      r, rs = @sclr.call(ctx, nil, strp, longp)
      str =  strp.to_s(len-2) unless len <=2
      str && str.split("\0") 
    end

    def Lib.sCardConnect ctx, reader, shared, proto
      @sccc ||= LIB['SCardConnect', 'LLSLLPP']
      cardp = DL.malloc(DL.sizeof('L'))
      protop = DL.malloc(DL.sizeof('L'))

      r,rs = @sccc.call(ctx, reader, shared, proto, cardp, protop)
      r &= 0xffffffff 
      #puts "%x" % r
      
      card = cardp.ptr.to_i
      proto = protop.ptr.to_i
  puts card
  puts proto
      #raise Errors::ERRS[r] unless r == Errors::SCARD_S_SUCCESS # TODO error mappings
      return card, proto
    end

  def Lib.sCardReconnect card, shared, proto, init 
      @scrc ||= LIB['SCardReconnect', 'LLLLLP']
      protop = DL.malloc(DL.sizeof('L'))

      r,rs = @scrc.call(card, shared, proto, init, protop)
      r &= 0xffffffff 
#      puts "%x" % r
      
      proto = protop.ptr.to_i
#  puts card
#  puts proto
      raise Errors::ERRS[r] unless r == Errors::SCARD_S_SUCCESS # TODO error mappings
      return proto
    end

    def Lib.sCardDisconnect card, disposition
      puts "Disconnect for #{card}"
      @scdc ||= LIB['SCardDisconnect', 'LLL']
      r, rs = @scdc.call(card, disposition)
      r &= 0xffffffff
      raise Errors::ERRS[r] unless r == Errors::SCARD_S_SUCCESS # TODO error mappings

    end

    def Lib.sCardBeginTransaction card
      @scbt ||= LIB['SCardBeginTransaction','LL']
      r, rs = @scbt.call(card)
      r &=0xffffffff
      raise Errors::ERRS[r] unless r == Errors::SCARD_S_SUCCESS # TODO error mappings
    end
  
    def Lib.sCardEndTransaction card, disposition
      @scet ||= LIB['SCardEndTransaction', 'LLL']
      r, rs = @scet.call(card, disposition)
    end

    def Lib.sCardStatus card
      puts "sCardStatus for #{card}"
      @scst ||= LIB['SCardStatus','Llslllsl']

      # card, readerName, readerNameLen
      stateP = DL.malloc(DL.sizeof('L'))
      protoP = DL.malloc(DL.sizeof('L'))
      atrLenP = DL.malloc(DL.sizeof('L'))
      nameLen = DL.malloc(DL.sizeof('L'))
      #MAX_ATR_SIZE=33
      atrP = DL.malloc(DL.sizeof('C')*330)
      nameP = DL.malloc(DL.sizeof('C')*330)
      r,rs = @scst.call(card, nameP, 330, 0, 0, atrP, 330)
      r&=0xffffffff
      raise Errors::ERRS[r] unless r == Errors::SCARD_S_SUCCESS # TODO error mappings

      
      state=stateP.ptr.to_i
      proto=protoP.ptr.to_i
      atr=atrP.to_s(atrLenP.ptr.to_i)
puts "state #{state}, #{stateP.to_i}"
puts proto
puts atrLenP.ptr.to_i
      [state, proto, atr]
    end


  end #module lib 


end # module PCSC

if $0 == __FILE__
  ctx = PCSC::Context.new
  puts ctx.is_valid == 0
  puts ctx.list_readers
  card = ctx.card_connect 
  puts card
  puts card.status[2].size
  card.disconnect PCSC::Lib::Disposition::SCARD_EJECT_CARD
  ctx.release
end
