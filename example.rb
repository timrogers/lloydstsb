# encoding: utf-8
# Include the library files from the Gem
require 'lloydstsb'

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
end
customer.accounts[0].get_transactions_from(Date.today - 100)
puts "Transactions from 100 days ago:"
customer.accounts[0].transactions.each do |tx|
    puts "Date: #{tx.date}, Description: #{tx.narrative}, Amount: #{currencify(tx.amount)}"
end
customer.logoff
