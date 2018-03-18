module Lulzscrap
  require 'activerecord-import'

  if defined?(Rails)
    require 'lulzscrap/engine'
  else
    require 'lulzscrap/scrap'
    require 'lulzscrap/query'
    require 'lulzscrap/request'
    require 'lulzscrap/utils'
    require 'lulzscrap/queued_request'
    require 'lulzscrap/scraped_data'
  end
end
