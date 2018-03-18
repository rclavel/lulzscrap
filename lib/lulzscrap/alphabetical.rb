class Lulzscrap::Alphabetical
  class << self
    def bulk_create_codes(range, prefix: '')
      Lulzscrap::QueuedRequest.import(
        %i(code status),
        range.map { |code| ["#{prefix}#{code}", Lulzscrap::QueuedRequest::Status::QUEUED] },
        validate: false
      )
    end
  end

  def initialize(scrap)
    @scrap = scrap
  end

  def find_next_queued_request
    request = nil

    Lulzscrap::Query.exclusive_transaction do
      request = Lulzscrap::QueuedRequest
        .where(status: Lulzscrap::QueuedRequest::Status::QUEUED)
        .order('length(code) ASC, code ASC')
        .first
      request&.update(status: Lulzscrap::QueuedRequest::Status::STARTED)
    end
    @scrap.log("> [#{request.code}] START") if request

    request
  end

  def post_import_actions(queued_request, max_results: nil)
    log_string = nil

    if max_results && queued_request.results >= max_results
      log_string = " | #{queued_request.results} > #{max_results} -> Go deeper"
      self.class.bulk_create_codes('A'..'Z', prefix: queued_request.code)
    end

    log_string
  end
end
