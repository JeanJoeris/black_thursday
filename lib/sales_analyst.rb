require_relative './analysis_math'

class SalesAnalyst
  include AnalysisMath
  attr_reader :sales_engine

  DAY_NUM_TO_WORD = {
    0 => "Monday",
    1 => "Tuesday",
    2 => "Wednesday",
    3 => "Thursday",
    4 => "Friday",
    5 => "Saturday",
    6 => "Sunday"
  }

  def initialize(sales_engine)
    @sales_engine = sales_engine
  end

  def average_item_price_for_merchant(id)
    merchant_items = @sales_engine.find_all_items_by_merchant_id(id)
    prices = get_item_prices(merchant_items)
    mean(prices).round(2)
  end

  def average_average_price_per_merchant
    all_merchants = @sales_engine.all_merchants
    total_average_price = all_merchants.reduce(0) do |result, merchant|
      result += average_item_price_for_merchant(merchant.id)
      result
    end
    average_price = (total_average_price / all_merchants.count).floor(2)
  end

  def price_standard_deviation_for_merchant(id)
    merchant_items = @sales_engine.find_all_items_by_merchant_id(id)
    prices = get_item_prices(merchant_items)
    standard_deviation(prices)
  end

  def price_standard_deviation
    all_prices = get_item_prices(@sales_engine.all_items)
    standard_deviation(all_prices).round(2)
  end

  def golden_items(num_of_std = 2)
    cutoff =
      average_average_price_per_merchant + num_of_std*price_standard_deviation
    @sales_engine.all_items.find_all do |item|
      item.unit_price > cutoff
    end
  end

  def average_items_per_merchant
    merchant_item_counts = get_merchant_item_counts(@sales_engine.all_merchants)
    mean(merchant_item_counts).round(2).to_f
  end

  def average_items_per_merchant_standard_deviation
    merchant_item_counts = get_merchant_item_counts(@sales_engine.all_merchants)
    standard_deviation(merchant_item_counts)
  end

  def merchants_with_high_item_count
    cutoff =
      average_items_per_merchant + average_items_per_merchant_standard_deviation
    @sales_engine.all_merchants.find_all do |merchant|
      merchant.items.count > cutoff
    end
  end

  def average_invoices_per_merchant
    invoice_counts = get_merchant_invoice_counts(@sales_engine.all_merchants)
    mean(invoice_counts).to_f.round(2)
  end

  def average_invoices_per_merchant_standard_deviation
    invoice_counts = get_merchant_invoice_counts(@sales_engine.all_merchants)
    standard_deviation(invoice_counts).round(2)
  end

  def top_merchants_by_invoice_count(num_of_std = 2)
    cutoff = average_invoices_per_merchant +
     num_of_std * average_invoices_per_merchant_standard_deviation
    @sales_engine.all_merchants.find_all do |merchant|
      merchant.invoices.count > cutoff
    end
  end

  def bottom_merchants_by_invoice_count(num_of_std = 2)
    cutoff = average_invoices_per_merchant -
     num_of_std * average_invoices_per_merchant_standard_deviation
    @sales_engine.all_merchants.find_all do |merchant|
      merchant.invoices.count < cutoff
    end
  end

  def invoice_status(status)
    sought_invoices = @sales_engine.invoice_repo.find_all_by_status(status)
    fraction = sought_invoices.count.to_f / @sales_engine.all_invoices.count
    (fraction * 100).round(2)
  end

  def average_invoices_per_day
    invoices_per_day = get_day_invoice_counts(@sales_engine.all_invoices)
    mean(invoices_per_day).round(2)
  end

  def average_invoices_per_day_std
    invoices_per_day = get_day_invoice_counts(@sales_engine.all_invoices)
    standard_deviation(invoices_per_day)
  end

  def top_days_by_invoice_count
    cutoff = average_invoices_per_day + average_invoices_per_day_std
    all_invoices = @sales_engine.all_invoices
    top_days = get_day_invoice_counts(all_invoices).map.with_index do |day_count, day|
      DAY_NUM_TO_WORD[day] if day_count > cutoff
    end
    top_days.delete(nil)
    top_days
  end

  def merchants_with_pending_invoices
    @sales_engine.all_merchants.find_all do |merchant|
      merchant.invoices.any? do |invoice|
        !invoice.is_paid_in_full?
      end
    end
  end

  def merchants_with_only_one_item(merchants = @sales_engine.all_merchants)
    merchants.find_all do |merchant|
      merchant.items.count == 1
    end
  end

  def merchants_with_only_one_item_registered_in_month(month)
    merchants_by_month = @sales_engine.all_merchants.find_all do |merchant|
      merchant.created_at.strftime("%B") == month.capitalize
    end
    merchants_with_only_one_item(merchants_by_month)
  end

  def total_revenue_by_date(date)
    invoices_to_be_consider = @sales_engine.all_invoices.find_all do |invoice|
      invoice.created_at.strftime("%F") == date.strftime("%F")
    end
    invoices_to_be_consider.reduce(0) do |result, invoice|
      result += invoice.total
      result
    end
  end

  def get_item_prices(items)
    items.map do |item|
      item.unit_price_to_dollars
    end
  end

  def get_merchant_item_counts(merchants)
    merchants.map do |merchant|
      merchant.items.count
    end
  end

  def get_merchant_invoice_counts(merchants)
    merchants.map do |merchant|
      merchant.invoices.count
    end
  end

  def get_day_invoice_counts(invoices)
    group_invoices_by_day(invoices).map do |day_invoice_data|
      day_invoice_data[1].count
    end
  end

  def group_invoices_by_day(invoices)
    invoices.group_by do |invoice|
      invoice.created_at.wday
    end
  end

  def revenue_by_merchant(merchant_id)
    invoices = @sales_engine.find_invoices_by_merchant_id(merchant_id)
    invoices.reduce(0) do |result, invoice|
      result += invoice.total
      result
    end
  end

  def merchant_revenues
    merchants = @sales_engine.all_merchants
    revenues = merchants.map do |merchant|
      revenue_by_merchant(merchant.id)
    end
  end

  def top_revenue_earners(merchant_number = 20)
    merchants_and_revenues = @sales_engine.all_merchants.zip(merchant_revenues)
    sorted_merchants_and_revenues = merchants_and_revenues.sort_by do |merchant_and_revenue|
      merchant_and_revenue.last
    end.reverse
    merchant_number.times.map do |num|
      sorted_merchants_and_revenues[num].first
    end
  end

  def merchants_ranked_by_revenue
    top_revenue_earners(@sales_engine.all_merchants.count)
  end
  
  def best_item_for_merchant(merchant_id)
    merchant = @sales_engine.find_merchant_by_merchant_id(merchant_id)
    paid_invoices = merchant.invoices.find_all do |invoice|
      invoice.is_paid_in_full?
    end
    top_invoice_items = paid_invoices.map do |paid_invoice|
      paid_invoice.invoice_items.max_by do |invoice_item|
        invoice_item.quantity * invoice_item.unit_price
      end
    end
    quantity_grouped_items = top_invoice_items.group_by do |top_invoice_item|
      top_invoice_item.quantity * top_invoice_item.unit_price
    end 
    max_quantity = quantity_grouped_items.keys.max
    quantity_grouped_items[max_quantity].map do |invoice_item|
      @sales_engine.find_item_by_item_id(invoice_item.id)
    end
    # [@sales_engine.find_item_by_item_id(top_invoice_item.item_id)]
  end
  
  def find_item_quantity_across_invoice_items(item_id, invoice_items)
    quantity = 0
    invoice_items.each do |invoice_item|
      quantity += invoice_item.quantity if invoice_item.item_id == item_id
    end
    quantity
  end
  
  def most_sold_item_for_merchant(merchant_id)
    merchant = @sales_engine.find_merchant_by_merchant_id(merchant_id)
    paid_invoices = merchant.invoices.find_all do |invoice|
      invoice.is_paid_in_full?
    end
    paid_invoice_items = paid_invoices.map do |invoice|
      invoice.invoice_items
    end.flatten
    paid_invoice_items.map do |invoice_item|
      find_item_quantity_across_invoice_items(invoice_item.item_id, paid_invoice_items)
    end
    # for each item, find its quantity across ALL paid invoices
    top_invoice_items = paid_invoices.map do |paid_invoice|
      paid_invoice.invoice_items.max_by do |invoice_item|
        invoice_item.quantity
      end
    end
    quantity_grouped_items = top_invoice_items.group_by do |top_invoice_item|
      top_invoice_item.quantity 
    end 
    max_quantity = quantity_grouped_items.keys.max
    # binding.pry
    quantity_grouped_items[max_quantity].map do |invoice_item|
      # binding.pry
      @sales_engine.find_item_by_item_id(invoice_item.item_id)
    end
    # [@sales_engine.find_item_by_item_id(top_invoice_item.item_id)]
  end
end
