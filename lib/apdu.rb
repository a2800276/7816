module ISO7816
        def ISO7816.b2s bytestr
          r = bytestr.unpack("H*")[0]
          r.length > 1 ? r : "  "
        end
        def ISO7816.make_binary value
          value = [value].pack("C") if value.is_a? Numeric
        end

        def b2s bytestr
          ISO7816.b2s bytestr
        end

       
module APDU

#
# Models an ISO 7816 APDU (Application Protocol Data Unit) the basic
# "packet"/unit of communication sent from terminal/cardreader to the
# card attributes are: CLASS (.cla) INS (.ins), PARAM1 (p1), PARAM2
# (.p2) DATA (.data) and LE (.le), the length of the data expected in
# the response from the card.  
         
class APDU
  include ISO7816
  attr_accessor :data, :le, :card, :name
  attr_reader :clas, :ins, :p1, :p2

  def initialize card=nil
    @cla="\x00"
    @ins="\x00"
    @p1= "\x00"
    @p2= "\x00"
    @data = ""
    @le = ""
    @card=card
  end
  def cla= cla
    @cla = "" << cla
  end
  def ins= ins
    @ins = "" << ins
  end
  def p1= p1
    @p1 = "" << p1
  end
  def p2= p2
    @p2 = "" << p2
  end
  def lc
    unless @lc
      return "" if @data == "" || @data==nil 
      return [@data.length].pack("C")
    end
    @lc   
  end 

  # normally don't need to set lc, because it's calculated from the
  # data's length, but for testing it may be necessary to set an 
  # correct value ...
  def lc= val
    if val.is_a? Numeric
      @lc = [val].pack("C")
    else
      @lc=val
    end
  end

  def le= val
    if val.is_a? Numeric
      @le = [val].pack("C")
    else
      @le=val
    end
  end

  def to_b
    bytes = @cla.dup
    bytes << @ins
    bytes << @p1
    bytes << @p2
    if @data != "" || @lc != nil
      bytes << self.lc
      bytes << @data
    end
    if @le != "" && @le != nil
      bytes << @le
    end
    bytes
  end

  def send handle_more_data=true, card=nil
    card = card || @card
    raise "no card to send data to" unless card
    
    card.send self.to_b
    
    to_receive = 2 
    to_receive += @le.unpack("C")[0] if @le && @le != ""

    r = card.receive(to_receive)
    resp = Response.new(r, self)
    
    if (how_much_more = resp.more_data?)
      gr = GET_RESPONSE.new
      gr.le = how_much_more
      resp = Response.new(gr.send(false, card), gr) # avoid infinite get_response loop... how to handle? 
    end

    resp
  end

  def to_s

    line1 = "#{@name}\n|CLA|INS| P1| P2|"
    line2 = [@cla, @ins, @p1, @p2].map { |b|
      "| "+ ( b.unpack("H*")[0] )
    }.join+"|"
    
    if @data != "" || @le != ""
      field_size = @data.length*2>"Data".length ? @data.length*2 : "Data".length 
      if @data.length >=2
        pad0 = " "*((@data.length*2 - 4)/2) 
        pad1 = ""
      else
        pad0 = ""
        pad1 = " "   
      end
      #line1 += "| LC|#{pad0}Data#{pad0}| LE|"      
      line1 += ("| LC|% #{field_size}s| LE|" % "Data")     
      #line2 += "| #{b2s(self.lc)}|#{pad1}#{b2s(@data)}#{pad1}| #{@le?b2s(@le):"  "}|"
      line2 += "| #{b2s(self.lc)}|% #{field_size}s| #{@le?b2s(@le):"  "}|" % b2s(@data)
    end
    "#{line1}\n#{line2}"
  end
end # class APDU 

class Response
  include ISO7816
  attr_accessor :data, :sw1, :sw2

  def initialize data, le=0
    if le.is_a? ISO7816::APDU::APDU
      le = le.le.unpack("C")[0]
      le = le ? le : 0
    end
    @data = data[0,le]
    @sw1 = data[-2,1]
    @sw2 = data[-1,1]

  end

  def normal?
    (@sw1 == "\x90" && @sw2 == "\x00") || @sw1 == "\x61"
  end

  def warning?
    ["\x62","\x63"].include? @sw1
  end

  def execution_err?
    ["\x64", "\x65", "\x66"].include? @sw1
  end

  def checking_err?
    ["\x67", "\x68", "\x69", "\x6a", "\x6b", "\x6c", "\x6d", "\x6e", "\x6f"].include? @sw1
  end

  def more_data?
    return @sw1 == "\x61" ? @sw2 : false 
  end

  def to_s
    str = ""      
    str << "APDU Response\n"
    str << "  Data(#{@data.length}): #{b2s(@data)}\n" unless @data == ""
    str << "  SW1: #{b2s(@sw1)} (#{sw1_explanation})\n" 
    str << "  SW2: #{b2s(@sw2)} (#{sw2_explanation})\n" 
    str
  end

  def sw1_explanation
    case @sw1
      when "\x90" 
        return "OK: No further qualification"
      when "\x61" 
        return "OK: SW2 indicates the number of response bytes still available"
	# Warning processings
      when "\x62"
        return "WARN: State of non-volatile memory unchanged"
      when "\x63" : return "WARN: State of non-volatile memory changed"
	# Execution errors
      when "\x64"
        return "EXE ERR: State of non-volatile memory unchanged" 
      when "\x65"
        return "EXE ERR: State of non-volatile memory changed"
      when "\x66"
        return "EXE ERR: Reserved for security-related issues"
	# Checking errors
      when "\x67"
        return "CHK ERR: Wrong length"
      when "\x68"
        return "CHK ERR: Functions in CLA not supported"
      when "\x69"
        return "CHK ERR: Command not allowed"
      when "\x6A"
        return "CHK ERR: Wrong parameter(s) P1-P2"
      when "\x6B"
        return "CHK ERR: Wrong parameter(s) P1-P2"
      when "\x6C"
        return "CHK ERR: Wrong length Le: SW2 indicates the exact length"
      when "\x6D"
        return "CHK ERR: Instruction code not supported or invalid"
      when "\x6E"
        return "CHK ERR: Class not supported"
      when "\x6F"
        return "CHK ERR: No precise diagnosis"
      else 
        return "UNKNOWN : #{b2s(@sw1)}"
    end
  end

  def sw2_explanation
    case @sw1
      when "\x90", "\x64", "\x67", "\x6b", "\x6d", "\x6e", "\x6f"
        sw2_check00
      when "\x61"
        "#{b2s(@sw2)} bytes remaining."
      when "\x62"
        sw2_62
      when "\x63"
        sw2_63
      when "\x65"
        sw2_65
      when "\x66"
        "security (undefined)"
      when "\x68"
        sw2_68
      when "\x69"
        sw2_69
      when "\x6a"
        sw2_6a
      when "\x6c"
        "wrong lenght. Exact len: #{b2s(@sw2)}"
      else
        "UNKNOWN : #{b2s(@sw2)}"
    end
  end

  private

  def sw2_check00
    @sw2 == "\x00" ? "" : "sw2 should be 0x00, is #{b2s(@sw2)}"
  end
  def sw2_62
    case @sw2
      when "\x00": "No information given"
      when "\x81": "Part of returned data may be corrupted"
      when "\x82": "End of file/record reached before reading Le bytes"
      when "\x83": "Selected file invalidated"
      when "\x84": "FCI not formatted according to spec"
      else "unknown sw2 for sw1=#{b2s(@sw1)}: #{b2s(@sw2)}"
    end
  end

  def sw2_63
    case @sw2
      when "\x00": "No information given"
      when "\x81": "File filled up by the last write"
      when "\xC0","\xC1","\xC2","\xC3","\xC4","\xC5","\xC6","\xC7","\xC8","\xC9","\xCA","\xCB","\xCC","\xCD","\xCE","\xCF"
        "Counter provided by '#{@sw2[0] & 0x0f}'"
      else "unknown sw2 for sw1=#{b2s(@sw1)}: #{b2s(@sw2)}"
    end
  end

  def sw2_65
    case @sw2
      when "\x00": "No information given"
      when "\x81": "Memory failure"
      else "unknown sw2 for sw1=#{b2s(@sw1)}: #{b2s(@sw2)}"
    end
  end

  def sw2_68
    case @sw2
      when "\x00": "No information given"
      when "\x81": "Logical channel not supported"
      when "\x82": "Secure messaging not supported"
      else "unknown sw2 for sw1=#{b2s(@sw1)}: #{b2s(@sw2)}"
    end
  end

  def sw2_69
    case @sw2
      when "\x00": "No information given"
      when "\x81": "Command incompatible with file structure"
      when "\x82": "Security status not satisfied"
      when "\x83": "Authentication method blocked"
      when "\x84": "Referenced data invalidated"
      when "\x85": "Conditions of use not satisfied"
      when "\x86": "Command not allowed (no current EF)"
      when "\x87": "Expected SM data objects missing"
      when "\x88": "SM data objects incorrect"
      else "unknown sw2 for sw1=#{b2s(@sw1)}: #{b2s(@sw2)}"
    end
  end

  def sw2_6a
    case @sw2
      when "\x00": "No information given"
      when "\x80": "Incorrect parameters in the data field"
      when "\x81": "Function not supported"
      when "\x82": "File not found"
      when "\x83": "Record not found"
      when "\x84": "Not enough memory space in the file"
      when "\x85": "Lc inconsistent with TLV structure"
      when "\x86": "Incorrect parameters P1-P2"
      when "\x87": "Lc inconsistent with P1-P2"
      when "\x88": "Referenced data not found"
      else "unknown sw2 for sw1=#{b2s(@sw1)}: #{b2s(@sw2)}"
    end
  end

end


end # module APDU

end # ISO7816

if __FILE__ == $0
        puts 0x04.class
  puts "here"
  a = ISO7816::APDU::APDU.new
  puts a
  a.data = "\xde\xad\xbe\xef"
  puts a
  a = ISO7816::APDU::APDU.new
  a.data = "\xde"
  a.le = "\x01"
  puts a
  a = ISO7816::APDU::SELECT.new
  puts a
end
