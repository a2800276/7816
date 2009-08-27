
require 'hexy'

module ISO7816
  class ATR
#   require 'atr_generated'
    attr_reader :atr_bytes
    # provide a string of bytes to init this object.
    def initialize atr
      @atr_bytes = atr
      @string_rep = ATR.stringify atr
      @desc = ATR.get_description atr
      @ta=Hash.new
      @tb=Hash.new
      @tc=Hash.new
      @td=Hash.new
      decode  
    end
    
    # ATR spec:
    # TS : initial 
    #   3F = inverse logic
    #   3B = direct logic
    # T0 : format
    #   |7|6|5|4||3|2|1|0|
    #   bits 4 through 7 indicate presence of TA1, TB1, TC1, TD1 respectively 
    #   bits 0-3 are the length of the "historical data"
    #
    #   TA1...TD1, if present follow T0
    #
    #   TAi, TBi, and TCi have codified sematics, a possible TDi field signals the
    #   existance of further TAi+1... fields.
    #
    #   |7|6|5|4||3|2|1|0|
    #   
    #   where 4, 5 and 6 signal he presesence of TAx, TBx, TCx, TDx.
    #
    #   finally the last bytes are "historical data" followed by a single byte checksum.
    def decode
      pos = 0
      @ts = @atr_bytes[pos]
      case @ts
      when 0x3F: @ts_d="inverse"
      when 0x3B: @ts_d="direct"
      else  @ts_d = "invalid"
      end

      @t0 = @atr_bytes[pos+=1]
      
      ta, tb, tc,td, @hist_data_len = decode_TD 0, pos
      
      i=1
      @max_i = 0
      while ta || tb || tc || td
        @max_i = i
        decodeTA i, pos+=1 if ta 
        decodeTB i, pos+=1 if tb 
        decodeTC i, pos+=1 if tc 
        if td
          ta, tb, tc, td = decode_TD i, pos+=1
        else
          break   
        end
        i+=1
      end
      
      @historical_data = @atr_bytes[pos+=1, @hist_data_len]
      #puts @historical_data.size

      #puts ATR.stringify(@historical_data)
    end
  
    def decodeTA i, pos
      @ta ||= Hash.new
      @ta[i]=@atr_bytes[pos] 
    end
    def decodeTB i, pos
      @tb ||= Hash.new
      @tb[i]=@atr_bytes[pos] 
    end

    def decodeTC i, pos
      @tc ||= Hash.new
      @tc[i]=@atr_bytes[pos] 
    end

    # decodes a byte in the form:
    #   |7|6|5|4||3|2|1|0|
    # and returns
    # [TA?, B?, TC?, TD?, num]
    def decode_TD i, pos
            byte = @atr_bytes[pos]
            @td ||= Hash.new
            @td[i]=byte

            [
              (byte & 0x10)!=0,
              (byte & 0x20)!=0,
              (byte & 0x40)!=0,
              (byte & 0x80)!=0,
              byte & 0x0F
            ]
    end

    def to_s
      str = <<HELLO
ATR #{@string_rep}  
  TS (#{"%X"%@ts}) : #{@ts_d}
  T0 (#{"%X"%@t0}) : #{"%08b"%@t0}

  histdatalen: #{@hist_data_len}

HELLO
    
      1.upto(@max_i) {|i|
        str << "i=#{i}\n"
        str << label_i_hex_bin("TA", i, @ta[i])  
        str << label_i_hex_bin("TB", i, @tb[i]) 
        str << label_i_hex_bin("TC", i, @tc[i]) 
        str << label_i_hex_bin("TD", i, @td[i]) 

      }
      
      if @historical_data 
        str << "Historical Data:\n" 
        str << Hexy.new(@historical_data).to_s
      end

      str
    end


    def label_i_hex_bin label, i, byte 
      byte == nil ? "" : "  %s%d(%02x) = %08b\n" % [label, i, byte, byte]
    end

    def self.stringify atr
      atr.unpack("H*")[0].upcase
    end
    def self.get_description atr, bytes=false
      atr = stringify atr if bytes
      #desc = ATR_HASH[atr]
      #desc ? desc : "unknown"
      "unknown"
    end
  end
end

if $0 == __FILE__
  puts ISO7816::ATR.get_description("3B660000314B01010080")
  puts ISO7816::ATR.get_description("3B66000;ldskjfalsdkj")
  bytes = ["3B660000314B01010080"].pack("H*")
  puts ISO7816::ATR.get_description(bytes , true)
  atr = ISO7816::ATR.new bytes
  puts atr


  bytes = ["3BFF9500FFC00A1F438031E073F62113574A334861324147D6"].pack("H*")
  atr = ISO7816::ATR.new bytes
  puts atr


  ISO7816::ATR::ATR_HASH.keys.each{|key|
          puts key
    bytes= [key].pack("H*")
    puts ISO7816::ATR.new(bytes).to_s
    puts "--------------------------------------"

  } 


end

