## Lloyds TSB screen scraper

I bank with Lloyds TSB - I have my current account and credit card with them. Like most online banking services though, they're not to up-to-date on APIs and the like. After looking around online, I found that there were a couple of scripts that people had built, but I didn't have much luck with them myself. So I decided to build my own screen scraper.

I know the code in this is pretty messy, and as ever, it's untested. I tried to refactor it and got to the end, but then it turned out to be broken and I couldn't be bothered to fix it. So I've left it for now.

### Usage

The file `example.rb` provides a very simple example of how the code works, but here's a step by step:

1. Ensure the gem is installed, and then include it in your Ruby file, or in your Gemfile where appropriate:

```
$ gem install lloydstsb
`require 'lloydstsb'
```

2. Create a hash with three symbol keys, `:username`, `:password` and `:memorable_word`, each unsurprisingly corresponding to different authentication details used

```
@settings = {
  username: "123456789",
  password: "a secure password",
  memorable_word: "banking"
}
```

3. Instantiate a new instance of the `LloydsTSB::Customer` object, passing in the hash from the previous step - this is used to perform the authentication required.

`customer = LloydsTSB::Customer.new(@settings)`

4. Call the `accounts` method of the object you just made - it'll take a few seconds, and will return a number of `LloydsTSB::Account` objects. Play with the response as you wish.

```
puts customer.name
customer.accounts
customer.accounts.first.transactions
```

5. If you wish to read transactions further back than the most recent 25 then this will need to be collected on a per account basis. You'll need a line of the form
```customer.accounts[0].get_transactions_from(Date.today - 100)
```
There is sample usage in example.rb

### Data models

A __LloydsTSB::Customer__ is created with `LloydsTSB::Customer.new` with a hash of settings passed in. It has the following attributes:

* __agent (Mechanize::Agent)__ - the Mechanize agent used to browse around the online banking system. This will be pointing at the "Your accounts" page.
* __name (string)__ - the name of the customer
* __accounts (array)__ - an array of LloydsTSB::Account objects representing accounts held by the customer

A __LloydsTSB::Account__ instance has the following attributes:

* __name (string)__ - the name of the account
* __balance (integer)__ - the balance of the account, whether positive or negative. *(NB: The true meaning of balance is affected by whether the account is a :credit_card or a :bank_account)
* __limit (integer)__ - the credit limit for the account - this is an overdraft limit for a current account, or the spending limit on a credit card
* __transactions (array)__ - an array containing a number of `LloydsTSB::Transaction` object - this will be the 20(?) most recent transactions on the account
* __details__ (hash)__ - the identifying information for the account as a hash. For a bank account, this will have keys :account_number and :sort_code, with :card_number for credit cards
* __type (symbol)__ - the type of the account, either `:credit_card` or `:bank_account`

A __LloydsTSB::Account__ has many __LloydsTSB::Transaction__ instances in its transactions property. Each transaction has the following attributes:

* __date (Date)__ - the date of the transaction as shown on the statement
* __narrative (string)__ - a description of the transaction, most likely the name of the merchant
* __type (symbol)__ - the type of transaction, usually an acronym - a list is available on the Lloyds TSB site
* __direction (symbol)__ - either `:credit` or `:debit`, depending on what the transaction is
* __amount (integer)__ - The amount of the transaction, obviously...
* __unique_reference (string)___ - a hash to identify this transaction *(fairly)* uniquely...useful if you want to see whether a transaction is new or not

### Limitations

* It's not able to view the details of Scottish Widows investments. This is because the LTSB site does not display the data in-line.

### License

Use this for what you will, as long as it isn't evil. If you make any changes or cool improvements, please let me know at <tim+lloydstsb@tim-rogers.co.uk>.
