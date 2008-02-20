

module PCSC
  
  class Context
    def initialize
    end
    def release
    end
    def is_valid
    end
    def list_readers
    end
    def list_reader_groups
    end
    def card_connect
    end
  end
  
  class Card
    def self.connect
    end
    def reconnect
    end
    def disconnect
    end
    def transaction
    end
    def transmit
    end
  end



end
