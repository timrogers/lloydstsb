module LloydsTSB
  class Transaction
    attr_accessor :date, :narrative, :type, :direction, :amount
    
    def initialize(hash = {})
      hash.each { |key,val| send("#{key}=", val) if respond_to?("#{key}=") }
    end
  end
end