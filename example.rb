# encoding: utf-8
# Bring in all the files in lib/, including the scraper and the data models
Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }

# Bring in the settings file - it should contain a hash of @settings with the
# symbol keys :username, :password and :memorable_word
require File.join(File.dirname(__FILE__), 'settings')

# Create an instance of a Lloyds TSB customer - this is where we login.
customer = LloydsTSB::Customer.new(@settings)
puts "These accounts belong to #{customer.name}."

customer.accounts.each do |account|
  puts "Name: #{account.name}"
  puts "Details: #{account.details.inspect}"
  puts "Type: #{account.type.to_s}"
  puts "Balance: #{currencify(account.balance)}"
  puts "Limit: #{currencify(account.limit)}"
  puts "Transactions:"
  puts ""
  account.transactions.each do |tx|
    puts "Date: #{tx.date}"
    puts "Description: #{tx.narrative}"
    puts "Type: #{tx.type}"
    puts "Direction: #{tx.direction}"
    puts "Amount: #{currencify(tx.amount)}"
    puts "Unique reference: #{tx.unique_reference}"
    puts ""
  end
end