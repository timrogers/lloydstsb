require 'mechanize'
require 'nokogiri'

module LloydsTSB
  class Account
    attr_accessor :name, :balance, :limit, :transactions, :details, :type, :viewpage_url
    attr_accessor :agent
    
    def initialize(hash = {})
      hash.each { |key,val| send("#{key}=", val) if respond_to?("#{key}=") }
    end
    
    def get_transactions_from(start_date)
      return if start_date >= transactions.last.date
      end_date = transactions.last.date

      # At the weekends, some transcations appear early but forward-dated for the next banking day.
      # This block of code will cope with such transactions
      while end_date > Date.today do
        end_date -= 1
      end

      subrange_start = end_date << 3
      subrange_start += 1
      subrange_end = end_date
      while subrange_start > start_date
        _get_transactions_for_range(subrange_start, subrange_end)
        subrange_end = subrange_start
        subrange_start <<= 3 # we have to do this in 3 month chunks
        subrange_start += 1
      end
      _get_transactions_for_range(subrange_start, subrange_end)
    end

  private
    def _get_transactions_for_range(start_date, end_date)
      # get the main page for this account
      @agent.get(viewpage_url)
      # fill in the date search fields
      @agent.page.forms[4]["pnlgrpStatement:conS5:frmSearchTransaction:dtSearchFromDate.month"] = start_date.month.to_s.rjust(2,'0')
      @agent.page.forms[4]["pnlgrpStatement:conS5:frmSearchTransaction:dtSearchFromDate"] = start_date.day.to_s.rjust(2,'0')
      @agent.page.forms[4]["pnlgrpStatement:conS5:frmSearchTransaction:dtSearchFromDate.year"] = start_date.year.to_s

      @agent.page.forms[4]["pnlgrpStatement:conS5:frmSearchTransaction:dtSearchToDate.month"] = end_date.month.to_s.rjust(2,'0')
      @agent.page.forms[4]["pnlgrpStatement:conS5:frmSearchTransaction:dtSearchToDate"] = end_date.day.to_s.rjust(2,'0')
      @agent.page.forms[4]["pnlgrpStatement:conS5:frmSearchTransaction:dtSearchToDate.year"] = end_date.year.to_s

      # click the search button
      @agent.page.forms[4].click_button
      raise "Could not understand search results response; page title was #{@agent.page.title}" if (@agent.page.body =~ /Search results/i).nil?
      # we are given 25 transactions at a time, so read each page and then click 'previous' until that link is disabled§
      loop do
        more_transactions = _parse_transactions(@agent)
        if more_transactions.empty?
          break
        end
        more_transactions.each do |x|
          transactions<<x
        end

        pagination_links = Nokogiri::HTML(@agent.page.body, 'UTF-8').css('fieldset ul.paginationSudoButtons')
        break if pagination_links.empty?
        previous_link  = pagination_links.css('li')[0].css('input')[0]
        break if previous_link.attribute('disabled')

        form = @agent.page.form_with(:name => "pnlgrpStatement:conS3:frmSearchResults")
        button = form.buttons.first
        @agent.submit(form, button)

        sleep(5) # It's only polite...
      end
      return transactions
    end

    def _parse_transactions(account_agent)
      these_transactions = []
        # If there's a mention of "minimum payment" on the transactions page,
        # this is a credit card rather than a bank account
        if account_agent.page.body.include?("Minimum payment")
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
#puts "DBG: read a transaction: #{data}"
            these_transactions << LloydsTSB::Transaction.new(data)
          end
        else
          # This is a bank account of some description
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
            
#puts "DBG: read a transaction: #{data}"
            # To finish, we add the newly built transaction to the array
             these_transactions << LloydsTSB::Transaction.new(data)
          end
        end

      return these_transactions
    end
    
  end
end
