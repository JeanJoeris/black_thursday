require_relative './item_repo'
require_relative './merchant_repo'
require_relative './invoice_repo'
require_relative './invoice_item_repo'
require_relative './customer_repo'
require_relative './transaction_repo'
require_relative './file_loader'
require 'CSV'
require 'pry'
require 'forwardable'

class SalesEngine
  attr_reader :merchant_repo,
              :item_repo,
              :invoice_repo,
              :invoice_item_repo,
              :customer_repo,
              :transaction_repo

  alias_method :merchants, :merchant_repo
  alias_method :items, :item_repo
  alias_method :invoices, :invoice_repo
  alias_method :invoice_items, :invoice_item_repo
  alias_method :customers, :customer_repo
  alias_method :transactions, :transaction_repo

  extend Forwardable
  def_delegator :merchant_repo, :all, :all_merchants
  def_delegator :item_repo, :all, :all_items
  def_delegator :invoice_repo, :all, :all_invoices
  def_delegator :invoice_item_repo, :all, :all_invoice_items
  def_delegator :customer_repo, :all, :all_customers
  def_delegator :transaction_repo, :all, :all_transactions

  def initialize(csv_path_info)
    @merchant_repo     = MerchantRepo.new(self)
    @item_repo         = ItemRepo.new(self)
    @invoice_repo      = InvoiceRepo.new(self)
    @invoice_item_repo = InvoiceItemRepo.new(self)
    @customer_repo     = CustomerRepo.new(self)
    @transaction_repo  = TransactionRepo.new(self)
    file_loader        = FileLoader.new(self)
    if csv_path_info.class == Hash
      file_loader.load_repos_from_csv(csv_path_info)
    end
  end

  def self.from_csv(csv_path_info)
    self.new(csv_path_info)
  end

  def find_merchant_by_merchant_id(merchant_id)
    @merchant_repo.find_by_id(merchant_id)
  end

  def find_item_by_item_id(item_id)
    @item_repo.find_by_id(item_id)
  end

  def find_items_by_merchant_id(merchant_id)
    @item_repo.find_all_by_merchant_id(merchant_id)
  end

  def find_invoice_by_invoice_id(invoice_id)
    @invoice_repo.find_by_id(invoice_id)
  end

  def find_invoices_by_merchant_id(merchant_id)
    @invoice_repo.find_all_by_merchant_id(merchant_id)
  end

  def find_invoices_by_customer_id(customer_id)
    @invoice_repo.find_all_by_customer_id(customer_id)
  end

  def find_invoice_items_by_invoice_id(invoice_id)
    @invoice_item_repo.find_all_by_invoice_id(invoice_id)
  end

  def find_customer_by_customer_id(customer_id)
    @customer_repo.find_by_id(customer_id)
  end

  def find_transactions_by_invoice_id(invoice_id)
    @transaction_repo.find_all_by_invoice_id(invoice_id)
  end
end
