require_relative './lib/sales_engine'
require_relative './lib/sales_analyst'
require 'time'

se = SalesEngine.from_csv({
  :customers => './data/customers.csv',
  :invoice_items => './data/invoice_items.csv',
  :invoices => './data/invoices.csv',
  :items => './data/items.csv',
  :merchants => './data/merchants.csv',
  :transactions => './data/transactions.csv'
  })

sa = SalesAnalyst.new(se)
num_merchants = se.all_merchants.count
num_merchants_with_returns = sa.merchants_with_returned_invoices.count
percent_merchants_with_returns = 100 * (num_merchants_with_returns / num_merchants.to_f)
lost_revenue_percentages = sa.lost_revenue_percentages
worst_revenue_ratio = lost_revenue_percentages.values.max
num_merchants_with_actual_returns = lost_revenue_percentages.reduce(0) do |result, revenue|
  result += 1 if revenue[1] != 0
  result
end
puts lost_revenue_percentages
puts "Out of #{num_merchants} merchants, #{num_merchants_with_returns}"\
    " merchants had returns. These merchants accounted for "\
    "#{percent_merchants_with_returns.round(2)}%"\
    "\nHowever, only #{num_merchants_with_actual_returns} had returns "\
    "on succesful transactions"
puts "\nThe worst merchant for customer satisfaction is: \n"\
    "Merchant ID - #{lost_revenue_percentages.key(worst_revenue_ratio)} "\
    "with a ratio of #{worst_revenue_ratio}% returns"
