## Lloyds TSB screen scraper

I bank with Lloyds TSB - I have my current account and credit card with them. Like most online banking services though, they're not to up-to-date on APIs and the like. After looking around online, I found that there were a couple of scripts that people had built, but I didn't have much luck with them myself. So I decided to build my own screen scraper.

I know the code in this is pretty messy, and as ever, it's untested. I tried to refactor it and got to the end, but then it turned out to be broken and I couldn't be bothered to fix it. So I've left it for now.

### Usage

The file `example.rb` provides a very simple example of how the code works, but here's a step by step:

1. Include all the files in the /lib directory - this includes the actual code for the parser, and a couple of different data models ('transaction' and 'account')

`Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }`

2. Create a hash with three symbol keys, `:username`, `:password` and `:memorable_word`, each unsurprisingly corresponding to different authentication details used

3. Instantiate a new instance of the `LloydsTSB::Customer` object, passing in the hash from the previous step - this is used to perform the authentication required.

`customer = LloydsTSB::Customer.new(@settings)`

4. Call the `accounts` method of the object you just made - it'll take a few seconds, and will return a number of `LloydsTSB::Account` objects. Play with the response as you wish.

`customer.accounts`

### Data models

A __LloydsTSB::Account__ instance has the following attributes:

* __name (string)__ - the name of the account
* __balance (integer)__ - the balance of the account, whether positive or negative. *(NB: The true meaning of balance is affected by whether the account is a :credit_card or a :bank_account)
* __limit (integer)__ - the credit limit for the account - this is an overdraft limit for a current account, or the spending limit on a credit card
* __transactions (array)__ - an array containing a number of `LloydsTSB::Transaction` object - this will be the 20(?) most recent transactions on the account
* __identifier (string)__ - some text, including the account number and sort code, or credit card number. This is basically unstructured at the moment.
* __type (symbol)__ - the type of the account, either `:credit_card` or `:bank_account`

A __LloydsTSB::Account__ has many __LloydsTSB::Transaction__ instances in its transactions property. Each transaction has the following attributes:

* __date (Date)__ - the date of the transaction as shown on the statement
* __narrative (string)__ - a description of the transaction, most likely the name of the merchant
* __type (symbol)__ - the type of transaction, usually an acronym - a list is available on the Lloyds TSB site
* __direction (symbol)__ - either `:credit` or `:debit`, depending on what the transaction is
* __amount (integer)__ - The amount of the transaction, obviously...
* __unique_reference (string)___ - a hash to identify this transaction *(fairly)* uniquely...useful if you want to see whether a transaction is new or not

### Limitations

* I haven't tested this with savings account, so it may well mess the script up and cause exceptions. I'll need to open a savings account to test this.
* The `identifier` of an account is unstructured, ie. you don't know what type of data it is, it's just a string ripped out from the page

### License

Use this for what you will, as long as it isn't evil. If you make any changes or cool improvements, please let me know at <tim+lloydstsb@tim-rogers.co.uk>.