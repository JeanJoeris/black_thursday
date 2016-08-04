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

  class LostRevenueLogic

    def initialize(sales_analyst, sales_engine)
      @sa = sales_analyst
      @se = sales_engine
      @lost_revenue_percentages = @sa.lost_revenue_percentages
      @worst_revenue_ratio = @lost_revenue_percentages.values.max
    end

    def num_merchants
      num_merchants = @se.all_merchants.count
    end

    def num_merchants_with_returns
      num_merchants_with_returns = @sa.merchants_with_returned_invoices.count
    end

    def worst_merchants
      @lost_revenue_percentages.collect do |merchant_id, revenue_ratio|
        @se.find_merchant_by_merchant_id(merchant_id) if revenue_ratio == @worst_revenue_ratio
      end.compact
    end

    def num_merchants_with_actual_returns
      @lost_revenue_percentages.reduce(0) do |result, revenue|
        result += 1 if revenue[1] != 0
        result
      end
    end

    def percent_merchants_with_returns
      100 * (num_merchants_with_returns / num_merchants.to_f)
    end

    def percent_merchants_with_actual_returns
      100 * (num_merchants_with_actual_returns / num_merchants.to_f)
    end


    def shaming_string(merchant)
      "#{merchant.name} lost #{@worst_revenue_ratio}% of "\
      "their #{merchant.paid_invoices.count} succesful invoices"
    end

    def returned_metrics_string
      "\nOut of #{num_merchants} merchants, #{num_merchants_with_returns}"\
      " merchants had returns. These merchants accounted for "\
      "#{percent_merchants_with_returns.round(2)}%"\
      "\nHowever, only #{num_merchants_with_actual_returns} had returns "\
      "on succesful transactions. These merchants accounted for "\
      "#{percent_merchants_with_actual_returns.round(2)}%"
    end
  end
  lrl = LostRevenueLogic.new(sa, se)

  puts lrl.returned_metrics_string
  puts "\nThe worst merchants for customer returns are: \n"
  lrl.worst_merchants.each do |merchant|
    puts lrl.shaming_string(merchant)
  end
