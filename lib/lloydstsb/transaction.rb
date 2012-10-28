require 'digest'

module LloydsTSB
  class Transaction
    attr_accessor :date, :narrative, :type, :direction, :amount, :unique_reference
    
    def initialize(hash = {})
      hash.each { |key,val| send("#{key}=", val) if respond_to?("#{key}=") }
      @unique_reference = Digest::MD5.hexdigest("#{@date.to_s}:#{@narrative}:#{@amount}")
    end
  end
end