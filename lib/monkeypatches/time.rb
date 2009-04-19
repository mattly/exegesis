class Time
  # returns the time, in UTC, in iso8601 format; see http://en.wikipedia.org/wiki/ISO_8601 for more details on this format
  # One major advantage of this format over others is that it sorts lexigraphically, so if you want f.e. just stuff from 
  # April 2009 you may specify '2009-04'..'2009-04Z' as your key
  def to_json_format
    self.getutc.iso8601
  end
  
  def to_json(options = nil)
    %("#{to_json_format}")
  end
end