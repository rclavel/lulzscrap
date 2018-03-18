class Lulzscrap::QueuedRequest < ApplicationRecord
  serialize :errors_by_ip

  module Status
    QUEUED = 'queued'
    STARTED = 'started'
    FAILED = 'failed'
    SKIPPED = 'skipped'
    DONE = 'done'
  end

  def enqueue!
    update(status: Status::QUEUED)
  end

  def skip!
    update(status: Status::SKIPPED)
  end

  def ended?
    [Status::FAILED, Status::DONE, Status::SKIPPED].exclude?(status)
  end

  def set_results(results)
    self.results = results
  end
end
