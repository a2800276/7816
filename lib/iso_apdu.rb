module ISO7816

module APDU

def APDU.create_class name, ins
cl=
%Q(
class #{name} < APDU
  def initialize card= nil
    super
    @cla= \"\\x00\"
    @ins= \"\\x#{ins}\"
  end
end
)
      eval(cl)
end

[
["ACTIVATE_FILE",                     "44"],
["APPEND_RECORD",                     "E2"],
["CHANGE_REFERENCE_DATA",             "24"],
["CREATE_FILE",                       "E0"],
["DEACTIVATE_FILE",                   "04"],
["DELETE_FILE",                       "E4"],
["DISABLE_VERIFICATION_REQUIREMENT",  "26"],
["ENABLE_VERIFICATION_REQUIREMENT",   "28"],
["ENVELOPE",                          "C2"],
["ERASE_BINARY",                      "0E"],
["ERASE_RECORD",                      "0C"],
["EXTERNAL_AUTHENTICATE",             "82"],
["GENERAL_AUTHENTICATE",              "86"],
["GENERATE_ASYMMETRIC_KEY_PAIR",      "46"],
["GET_CHALLENGE",                     "84"],
["GET_DATA",                          "CA"],
["GET_RESPONSE",                      "C0"],
["INTERNAL_AUTHENTICATE",             "88"],
["MANAGE_CHANNEL",                    "70"],
["MANAGE_SECURITY_ENVIRONMENT",       "22"],
["PERFORM_SCQL_OPERATION",            "10"],
["PERFORM_SECURITY_OPERATION",        "2A"],
["PERFORM_TRANSACTION_OPERATION",     "12"],
["PERFORM_USER_OPERATION",            "14"],
["PUT_DATA",                          "DA"],
["READ_BINARY",                       "B0"],
["READ_RECORD",                       "B2"],
["RESET_RETRY_COUNTER",               "2C"],
["SEARCH_BINARY",                     "A0"],
["SEARCH_RECORD",                     "A2"],
["SELECT",                            "A4"],
["TERMINATE_CARD_USAGE",              "FE"],
["TERMINATE_DF",                      "E6"],
["TERMINATE_EF",                      "E8"],
["UPDATE_BINARY",                     "D6"],
["UPDATE_RECORD",                     "DC"],
["VERIFY",                            "20"],
["WRITE_BINARY",                      "D0"],
["WRITE_RECORD",                      "D2"]
].each{|entry|
  APDU.create_class *entry
}


class GET_RESPONSE < APDU
  def initialize card=nil
    super 
    @ins = "\xc0"
  end
end


end # APDU

end #7816
