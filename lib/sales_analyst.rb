require_relative './analysis_math'

class SalesAnalyst
  include AnalysisMath
  attr_reader :sales_engine

  def initialize(sales_engine)
    @sales_engine = sales_engine
  end

  def average_item_price_for_merchant(id)
    merchant_items = @sales_engine.find_items_by_merchant_id(id)
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
    merchant_items = @sales_engine.find_items_by_merchant_id(id)
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
    all_invoices = @sales_engine.all_invoices
    day_grouped_invoices = all_invoices.group_by do |invoice|
      invoice.created_at.strftime("%A")
    end
    cutoff = average_invoices_per_day + average_invoices_per_day_std
    day_grouped_invoices.collect do |day, invoices_for_the_day|
      day if invoices_for_the_day.count > cutoff
    end.compact
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
    revenue_data = @sales_engine.all_merchants.zip(merchant_revenues)
    sorted_revenue_data = revenue_data.sort_by do |revenue_data|
      revenue_data.last
    end.reverse
    merchant_number.times.map do |num|
      sorted_revenue_data[num].first
    end
  end

  def merchants_ranked_by_revenue
    top_revenue_earners(@sales_engine.all_merchants.count)
  end

  def find_item_quantity(item_id, invoice_items)
    invoice_items.reduce(0) do |result, invoice_item|
      if invoice_item.item_id == item_id
        result += invoice_item.quantity
      end
      result
    end
  end

  def get_quantity_grouped_invoice_items(invoice_items)
    invoice_items.group_by do |invoice_item|
      find_item_quantity(invoice_item.item_id, invoice_items)
    end
  end

  def get_revenue_grouped_invoice_items(invoice_items)
    invoice_items.group_by do |invoice_item|
      price = invoice_item.unit_price
      find_item_quantity(invoice_item.item_id, invoice_items) * price
    end
  end

  def get_most_sold_items(quantity_grouped_invoice_items)
    max_quantity = quantity_grouped_invoice_items.keys.max
    quantity_grouped_invoice_items[max_quantity].map do |invoice_item|
      @sales_engine.find_item_by_item_id(invoice_item.item_id)
    end
  end

  def get_best_items(revenue_grouped_invoice_items)
    max_revenue = revenue_grouped_invoice_items.keys.max
    revenue_grouped_invoice_items[max_revenue].map do |invoice_item|
      @sales_engine.find_item_by_item_id(invoice_item.item_id)
    end
  end

  def most_sold_item_for_merchant(merchant_id)
    merchant = @sales_engine.find_merchant_by_merchant_id(merchant_id)
    paid_invoice_items = merchant.paid_invoices.collect do |invoice|
      invoice.invoice_items
    end.flatten

    quantity_grouped_invoice_items =
     get_quantity_grouped_invoice_items(paid_invoice_items)

    get_most_sold_items(quantity_grouped_invoice_items)
  end

  def best_item_for_merchant(merchant_id)
    merchant = @sales_engine.find_merchant_by_merchant_id(merchant_id)
    paid_invoice_items = merchant.paid_invoices.collect do |invoice|
      invoice.invoice_items
    end.flatten

    revenue_grouped_invoice_items =
      get_revenue_grouped_invoice_items(paid_invoice_items)

    get_best_items(revenue_grouped_invoice_items).first
  end
end
