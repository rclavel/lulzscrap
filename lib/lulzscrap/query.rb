class Lulzscrap::Query
  class << self
    def disable_sqlite3_standard_transactions!
      # Force the loading of AR stuff
      ActiveRecord::Base.connection.execute('SELECT 1')

      # Remove transactions
      ActiveRecord::ConnectionAdapters::SQLite3Adapter.class_eval do
        def begin_db_transaction; end
        def commit_db_transaction; end
      end
    end

    def exclusive_transaction
      ActiveRecord::Base.connection.execute('BEGIN EXCLUSIVE TRANSACTION')
      yield
    ensure
      ActiveRecord::Base.connection.execute('END')
    end
  end
end
