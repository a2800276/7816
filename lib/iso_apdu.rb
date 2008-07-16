module ISO7816

module APDU
class GET_RESPONSE < APDU
  def initialize card=nil
    super 
    @ins = "\xc0"
  end
end
end # APDU

end #7816
