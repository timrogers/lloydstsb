# encoding: utf-8
require 'mechanize'
require 'nokogiri'
require 'open-uri'
require 'date'

module LloydsTSB
  class Customer

    attr_reader :agent, :name

    def initialize(settings = {})
      # Creates a new Customer object - expects a hash with keys :username,
      # :password and :memorable_word
      @agent = Mechanize.new
      @settings = settings

      if @settings[:username].blank? ||
        @settings[:password].blank? ||
        @settings[:memorable_word].blank?
          raise "You must provide a username, password and memorable word."
      end

      @agent.get "https://online.lloydstsb.co.uk/personal/logon/login.jsp?WT.ac=hpIBlogon"
      
      # Fill in the first authentication form then submits
      @agent.page.forms[0]["frmLogin:strCustomerLogin_userID"] = @settings[:username]
      @agent.page.forms[0]["frmLogin:strCustomerLogin_pwd"] = @settings[:password]
      @agent.page.forms[0].submit
      
      # Checks for any errors on the page indicating a failure to login
      if @agent.page.search('.formSubmitError').any?
        raise "There was a problem when submitting your username and password.
          (#{@agent.page.search('.formSubmitError').text})"
      end
      
      # Works out from the text on the page what characters from the memorable
      # word are required
      mc1 = @agent.page
        .at('//*[@id="frmentermemorableinformation1"]/fieldset/div/div/div[1]/label').text.split(" ")[1].to_i
      mc2 = @agent.page
        .at('//*[@id="frmentermemorableinformation1"]/fieldset/div/div/div[2]/label').text.split(" ")[1].to_i
      mc3 = @agent.page.
        at('//*[@id="frmentermemorableinformation1"]/fieldset/div/div/div[3]/label')
          .text.split(" ")[1].to_i
        
      # Files in the memorable word fields and logs in
      @agent.page.forms[0]["frmentermemorableinformation1:strEnterMemorableInformation_memInfo1"] = "&nbsp;" + @settings[:memorable_word][mc1-1]
      @agent.page.forms[0]["frmentermemorableinformation1:strEnterMemorableInformation_memInfo2"] = "&nbsp;" + @settings[:memorable_word][mc2-1]
      @agent.page.forms[0]["frmentermemorableinformation1:strEnterMemorableInformation_memInfo3"] = "&nbsp;" + @settings[:memorable_word][mc3-1]
      @agent.page.forms[0].click_button

      # Checks for any errors indicating a failure to login - the final hurdle
      if @agent.page.search('.formSubmitError').any?
        raise "There was a problem when submitting your memorable word.
          (#{@agent.page.search('.formSubmitError').text})"
      end
      
      @name = @agent.page.at('span.name').text
      
    end

    def accounts
      # Fills in the relevant forms to login, gets account details and then
      # provides a response of accounts and transactions
      
      return @accounts if @accounts

      # We're in, now to find the accounts...
      accounts = []
      doc = Nokogiri::HTML(@agent.page.body, 'UTF-8')
       doc.css('li.clearfix').each do |account|
        # This is an account in the table - let's read out the details...

        acct = {
          name: account.css('a')[0].text,
          balance: account.css('p.balance').text.split(" ")[1]
            .gsub("£", "").gsub(",", "").gsub('Nil','0').to_f,
          limit: account.css('p.accountMsg').text.empty? ? 0.00 : account.css('p.accountMsg').text.split(" ")[2]
            .gsub("£", "").gsub(",", "").to_f,
          transactions: []
          }

        # Now we need to find the recent transactions for the account...We'll
        # go to the account's transactions page and read the table
        account_agent = @agent.dup
        account_agent.get(account.css('a')[0]['href'])
        
        # If there's a mention of "minimum payment" on the transactions page,
        # this is a credit card rather than a bank account
        if account_agent.page.body.include?("Minimum payment")
          acct[:type] = :credit_card
          acct[:details] = {
            card_number: account.css('.numbers').text.gsub(" Card Number ", "")
          }
          Nokogiri::HTML(account_agent.page.body, 'UTF-8').css('tbody tr').each do |transaction|
            
            # Credit card statements start with the previous statement's
            # balance. We don't want to record this as a transaction.
            next if transaction.css('td')[1].text == "Balance from Previous Statement"
            
            # Let's get the data for the transaction...
            data = {
              date: Date.parse(transaction.css('td')[0].text),
              narrative: transaction.css('td')[1].text,
            }
            data[:amount] = transaction.css('td')[4].text.split(" ")[0].to_f
            
            # And now we work out whether the transaction was a credit or
            # debit by checking, in a round-about way, whether the
            # transaction amount contained "CR" (credit)
            if transaction.css('td')[4].text.split(" ").length > 1
              data[:type] = :credit
              data[:direction] = :credit
            else
              data[:type] = :debit
              data[:direction] = :debit
            end
            
            # And finally, we add the transaction object to the array
            acct[:transactions] << LloydsTSB::Transaction.new(data)
          end
        else
          # This is a bank account of some description
          acct[:type] = :bank_account
          details = account.css('.numbers').text.gsub(" Sort Code", "").gsub("Account Number ", "").split(", ")
          acct[:details] = {
            sort_code: details[0],
            account_number: details[1]
          }
          Nokogiri::HTML(account_agent.page.body, 'UTF-8').css('tbody tr').each do |transaction|
            # Let's read the details from the table...
            data = {
              date: Date.parse(transaction.css('th.first').text),
              narrative: transaction.css('td')[0].text,
              type: transaction.css('td')[1].text.to_sym,
            }
            
            # Regardless of what the transaction is, there's an incoming
            # and an outgoing column. Let's work out which this is...
            incoming = transaction.css('td')[2].text
            out = transaction.css('td')[3].text
            if incoming == ""
              data[:direction] = :debit
              data[:amount] = out.to_f
            else
              data[:direction] = :credit
              data[:amount] = incoming.to_f
            end
            
            # To finish, we add the newly built transaction to the array
            acct[:transactions] << LloydsTSB::Transaction.new(data)
          end
        end

        accounts << LloydsTSB::Account.new(acct)
      end
      @accounts = accounts
      accounts
    end
  end
end
