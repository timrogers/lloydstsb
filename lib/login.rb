# encoding: utf-8
require 'rubygems'
require 'mechanize'
require 'nokogiri'
require 'open-uri'
require 'date'
require File.join(File.dirname(__FILE__), 'utils')
require File.join(File.dirname(__FILE__), 'bank_account')

module LloydsTSB
  class Login
    
    attr_reader :agent
    
    def initialize(settings = {})
      @agent = Mechanize.new
      @settings = settings
      
      if @settings[:username].blank? || @settings[:password].blank? || @settings[:memorable_word].blank?
        raise "You must provide a username, password and memorable word."
      end
      
      @agent.get "https://online.lloydstsb.co.uk/personal/logon/login.jsp?WT.ac=hpIBlogon"
    end
    
    def accounts
      @agent.page.forms[0]["frmLogin:strCustomerLogin_userID"] = @settings[:username]
      @agent.page.forms[0]["frmLogin:strCustomerLogin_pwd"] = @settings[:password]
      @agent.page.forms[0].submit
      
      if @agent.page.search('.formSubmitError').any?
        raise "There was a problem when submitting your username and password. (#{@agent.page.search('.formSubmitError').text})"
      end
      
      mc1 = @agent.page
        .at('//*[@id="frmentermemorableinformation1"]/fieldset/div/div/div[1]/label').text.split(" ")[1].to_i
      mc2 = @agent.page
        .at('//*[@id="frmentermemorableinformation1"]/fieldset/div/div/div[2]/label').text.split(" ")[1].to_i
      mc3 = @agent.page.
        at('//*[@id="frmentermemorableinformation1"]/fieldset/div/div/div[3]/label')
          .text.split(" ")[1].to_i
          
      @agent.page.forms[0]["frmentermemorableinformation1:strEnterMemorableInformation_memInfo1"] = "&nbsp;" + @settings[:memorable_word][mc1-1]
      @agent.page.forms[0]["frmentermemorableinformation1:strEnterMemorableInformation_memInfo2"] = "&nbsp;" + @settings[:memorable_word][mc2-1]
      @agent.page.forms[0]["frmentermemorableinformation1:strEnterMemorableInformation_memInfo3"] = "&nbsp;" + @settings[:memorable_word][mc3-1]
      @agent.page.forms[0].click_button
      
      if @agent.page.search('.formSubmitError').any?
        raise "There was a problem when submitting your memorable word. (#{@agent.page.search('.formSubmitError').text})"
      end
      
      accounts = []
      doc = Nokogiri::HTML(@agent.page.body, 'UTF-8')
       doc.css('li.clearfix').each do |account|
        acct = {
          name: account.css('a')[0].text,
          identifier: account.css('.numbers').text,
          balance: account.css('p.balance').text.split(" ")[1].gsub("£", "").gsub(",", "").to_f,
          limit: account.css('p.accountMsg').text.split(" ")[2].gsub("£", "").gsub(",", "").to_f,
          transactions: []
          }
         
         
        account_agent = @agent.dup
        account_agent.get(account.css('a')[0]['href'])
        if account_agent.page.body.include?("Minimum payment")
          # This is a credit card account
          acct[:type] = :credit_card
          Nokogiri::HTML(account_agent.page.body, 'UTF-8').css('tbody tr').each do |transaction|
            next if transaction.css('td')[1].text == "Balance from Previous Statement"
            data = {
              date: Date.parse(transaction.css('td')[0].text),
              narrative: transaction.css('td')[1].text,
            }
            data[:amount] = transaction.css('td')[4].text.split(" ")[0]
            if transaction.css('td')[4].text.split(" ").length > 0
              data[:type] = :credit
            else
              data[:type] = :debit
            end
            acct[:transactions] << LloydsTSB::Transaction.new(data)
          end
        else
          # This is a bank account of some description
          acct[:type] = :bank_account
          Nokogiri::HTML(account_agent.page.body, 'UTF-8').css('tbody tr').each do |transaction|
            next if transaction.css('td')[1].text == "Balance from Previous Statement"
            data = {
              date: Date.parse(transaction.css('th.first').text),
              narrative: transaction.css('td')[0].text,
              type: transaction.css('td')[1].text.to_sym,
            }
            incoming = transaction.css('td')[2].text
            out = transaction.css('td')[3].text
          
            if incoming == ""
              data[:direction] = :debit
              data[:amount] = out
            else
              data[:direction] = :credit
              data[:amount] = incoming
            end
            acct[:transactions] << LloydsTSB::Transaction.new(data)
          end
        end
        
          
        #acct[:transactions] << LloydsTSB::Transaction.new(data)
          
        
        accounts << LloydsTSB::BankAccount.new(acct)
      end
      accounts
    end   
  end
end