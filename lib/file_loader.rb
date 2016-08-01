require 'forwardable'
class FileLoader

  extend Forwardable
  def_delegators :@sales_engine,
                 :item_repo,
                 :merchant_repo,
                 :invoice_repo,
                 :invoice_item_repo,
                 :customer_repo,
                 :transaction_repo

  def initialize(sales_engine)
    @sales_engine = sales_engine
  end

  def load_repos_from_csv(file_path_details)
    file_path_details.keys.each do |key|
      add(file_path_details[key], repo_name(key))
    end
  end

  def repo_name(key)
    eval("#{key.to_s.chop}_repo")
  end

  def add(path, repo)
    CSV.foreach(path, headers:true, header_converters: :symbol) do |row|
      repo.add(row)
    end
  end


end