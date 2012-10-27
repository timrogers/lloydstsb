# Bring in all the files in lib/, including the scraper and the data models
Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }

# Bring in the settings file - it should contain a hash of @settings with the
# symbol keys :username, :password and :memorable_word
require File.join(File.dirname(__FILE__), 'settings')

# Create an instance of a Lloyds TSB customer - this is where we login.
customer = LloydsTSB::Customer.new(@settings)

customer.accounts.each do |account|
  
end