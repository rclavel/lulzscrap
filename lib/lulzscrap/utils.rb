class Lulzscrap::Utils
  class << self
    def watch!(sleep_delay: 2)
      loop do
        count = Lulzscrap::QueuedRequest.group(:status).count
        count['scraped_data_count'] = Lulzscrap::ScrapedData.count
        puts(count)
        sleep(sleep_delay)
      end
    end

    def reset!
      Lulzscrap::QueuedRequest.delete_all
      Lulzscrap::ScrapedData.delete_all
      init!
    end

    def init!
      Lulzscrap::Scrap.bulk_create_codes('AA'..'ZZ')
    end
  end
end
