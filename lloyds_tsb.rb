# Bring in all the files in lib/, including the scraper and the data models
Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }

# Bring in the settings file - it should contain a hash of @settings with the
# symbol keys :username, :password and :memorable_word
require File.join(File.dirname(__FILE__), 'settings')

scraper = LloydsTSB::Login.new(@settings)
puts scraper.agent.page.body
scraper.login
puts scraper.agent.page.body
puts scraper.accounts.inspect