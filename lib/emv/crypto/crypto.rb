module EMV
module Crypto
  
  # Generate Session keys according to CPS 5.3 
  def self.generate_session_key ic_card_key, seq, type
    seq         = check_and_convert("seq", seq, 2)
    ic_card_key = check_and_convert("ic_card_key", ic_card_key, 16)
    
    derivation_data = case type
            when :enc
              "\x01\x82"
            when :mac
              "\x01\x01"
            when :dek
              "\x01\x81"
            else
              raise "invalid type of key: #{type}"
            end

    derivation_data += seq + ISO7816.s2b("000000000000000000000000")

    cipher = OpenSSL::Cipher::Cipher.new("des-ede-cbc").encrypt
    cipher.key = ic_card_key
    cipher.update derivation_data
  end
  
  # Mac calculation according to CPS 5.4.1. 
  def self.mac_for_personalization key, input
    key = check_and_convert "key", key, 16
    input = pad(input)
    cipher = OpenSSL::Cipher::Cipher.new("des-ede-cbc").encrypt
    cipher.key = key
    mac = ""
    input.scan(/.{8}/) {|block|
      mac = cipher.update block
    }
    mac
  end
  
  # calculate ISO 9797-1 "Retail Mac"
  # (MAC Algorithm 3 with output transformation 3,
  # without truncation) : 
  # DES with final TDES.
  #
  # Padding is added if data is not a multiple of 8
  def self.retail_mac key, data
    cipher      = OpenSSL::Cipher::Cipher.new("des-cbc").encrypt
    cipher.key  = key[0,8]

    data = pad(data) unless (data % 8) == 0

    single_data = data[0,data.length-8]
    # Single DES with XOR til the last block
    if single_data && single_data.length > 0
      mac_ = cipher.update(single_data)
      mac_ = mac_[mac_.length-8, 8]
    else # length of data was <= 8
      mac_ = "\x00"*8
    end

    triple_data = data[data.length-8, 8]
    mac = ""
    0.upto(7) { |i|
      mac << (mac_[i] ^ triple_data[i])
    }
    # Final Round of TDES
    cipher      = OpenSSL::Cipher::Cipher.new("des-ede").encrypt
    cipher.key  = key
    cipher.update(mac)
  end

  def self.pad input

    input += "\x80"
    while (input.length % 8) != 0
      input << 0x00
    end
    input
  end

  def self.check_and_convert mes, data, length_in_bytes
    raise "`#{mes}` may not be nil" unless data
    unless data.length == length_in_bytes || data.length == length_in_bytes*2
      raise "invalid length for '#{mes}'. Should be #{length_in_bytes}" 
    end
    data = ISO7816.s2b(data) if data.length == length_in_bytes*2
    data
  end

end #module Crypto
end #module EMV
