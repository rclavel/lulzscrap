class Lulzscrap::Scrap
  PROCESSOR_LIST = %w(Alphabetical)

  def initialize(run_id:, processor:, check_blacklist_on: nil)
    @run_id = run_id
    camelized_processor = processor.to_s.camelize
    if PROCESSOR_LIST.exclude?(camelized_processor)
      raise "Unknown processor: #{processor}"
    end
    @processor = "Lulzscrap::#{camelized_processor}".constantize.new(self)
    @check_blacklist_on = check_blacklist_on
  end

  def request
    @_request ||= Lulzscrap::Request.new(self)
  end

  def run
    log("Current IP address: #{TorManager::Tor.fetch_ip_address(real_ip: true)}")
    log("Torify IP address: #{TorManager::Tor.fetch_ip_address}")
    loop do
      break unless yield
    end
  end

  def find_next_queued_request
    queued_request = @processor.find_next_queued_request
    yield(queued_request)
  rescue SignalException
    puts 'Receive SignalException. Exiting!'
    log('Receive SignalException. Exiting!')
    false

  rescue SOCKSError::ConnectionRefused,
         SOCKSError::HostUnreachable,
         Net::OpenTimeout,
         SOCKSError::ServerFailure,
         Net::ReadTimeout,
         Lulzscrap::Scrap::Exception => exception
    handle_connection_error(queued_request, exception)
    true

  rescue => exception
    handle_unknown_exception(queued_request, exception)
    false

  ensure
    if queued_request&.ended?
      Lulzscrap::Query.exclusive_transaction do
        queued_request.enqueue!
      end
    end
  end

  def handle_connection_error(queued_request, exception)
    log("#{exception.class}: #{exception}")

    if @check_blacklist_on
      check_response = TorManager::Tor.get(@check_blacklist_on) rescue nil
      if check_response && check_response.code == '200' && check_response.body.empty?
        if @run_id == 1
          log('This IP seems to be banned.')
          ip = TorManager::Tor.fetch_ip_address
          switch_tor_endpoint(queued_request, ip, 60)
        else
          log('This IP seems to be banned. Wait 60s.')
          sleep(60)
        end
        return true
      end
    end

    log('Connection refused.')

    ip = TorManager::Tor.fetch_ip_address
    queued_request.errors_by_ip = {} if queued_request.errors_by_ip.is_a?(String)
    queued_request.errors_by_ip[ip] ||= 0
    queued_request.errors_by_ip[ip] += 1

    if queued_request.errors_by_ip.keys.many?
      log("Code [#{queued_request.code}] doesn't seems to work. SKIP!")
      Lulzscrap::Query.exclusive_transaction { queued_request.skip! }
      sleep(5)
      return true
    end

    switch_tor_endpoint(queued_request, ip, 30) if @run_id == 1
    true
  end

  def switch_tor_endpoint(queued_request, ip, wait_time)
    log('Switch Tor endpoint.')
    TorManager::Tor.switch_tor_endpoint!
    log("Current IP address: #{TorManager::Tor.fetch_ip_address(real_ip: true)}")
    log("Torify IP address: #{ip}")
    log('Re-enqueue request and sleep 30s.')
    Lulzscrap::Query.exclusive_transaction { queued_request.enqueue! }
    sleep(wait_time)
  end

  def handle_unknown_exception(queued_request, exception)
    log("#{exception.class}: #{exception}")
    log(exception.backtrace.join("\n"))
    if queued_request
      Lulzscrap::Query.exclusive_transaction do
        queued_request.update(status: Lulzscrap::QueuedRequest::Status::FAILED)
      end
      log("-> [#{queued_request.code}] FAILED!")
      puts "-> [#{queued_request.code}] FAILED!"
    else
      puts 'Unknown exception, FAILED!'
    end

    false
  end

  def import_data(queued_request, data, **opts)
    Lulzscrap::Query.exclusive_transaction do
      Lulzscrap::ScrapedData.import(data, validate: false)
    end

    log_string = "> [#{queued_request.code}] Saved #{data.size} results"

    post_import_output = @processor.post_import_actions(queued_request, opts)
    log_string += post_import_output if post_import_output

    queued_request.status = Lulzscrap::QueuedRequest::Status::DONE
    Lulzscrap::Query.exclusive_transaction do
      queued_request.save!
    end

    log("#{log_string} | DONE")
    true
  end

  def log(string)
    @_log_file ||= File.open(File.join(Dir.pwd, 'lulzscrap.log'), 'a+')
    Rails.logger.info "| #{@run_id} | #{string}"
    @_log_file << "| #{@run_id} | #{string}\n"
    @_log_file.flush
  end

  class Exception < StandardError; end
end
