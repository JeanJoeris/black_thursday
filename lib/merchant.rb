require_relative '../lib/item_repo'
class Merchant
  attr_reader :id,
              :name,
              :created_at,
              :updated_at,
              :parent

  def initialize(merchant_details, merchant_repo = nil)
    @id   = merchant_details[:id].to_i
    @name = merchant_details[:name]
    @created_at = format_time(merchant_details[:created_at].to_s)
    @updated_at = format_time(merchant_details[:updated_at].to_s)
    @parent = merchant_repo
  end

  def format_time(time_string)
    unless time_string == ""
      Time.parse(time_string)
    end
  end

  def items
    @parent.find_all_items_by_merchant_id(self.id)
  end

  def invoices
    @parent.find_invoices_by_merchant_id(self.id)
  end

  def paid_invoices
    invoices.find_all do |invoice|
      invoice.is_paid_in_full?
    end
  end

  def customers
    invoices = @parent.find_invoices_by_merchant_id(id)
    invoices.map do |invoice|
      @parent.find_customer_by_customer_id(invoice.customer_id)
    end.uniq
  end
end
