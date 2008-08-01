require 'tlv'

module EMV
module Data
  class InitializeUpdateData < TLV
    b 6*8, "Identifier of the KMC", :kmc_id
    b 4*8, "Chip Serial Number", :csn
    b 8,   "Version Number of Master key (KMC)", :kmc_version
    b 8,   "Identifier of Secure Channel Protocol", :sec_channel_proto_id
    b 2*8, "Sequence Counter", :sequence_counter
    b 6*8, "Card challenge (r card)", :challenge
    b 8*8, "Card Cryptogram", :cryptogram
  end
end #module DATA
end #module EMV
