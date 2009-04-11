class Time
  def to_json_format
    self.getutc.strftime("%Y/%m/%d %H:%M:%S +0000")
  end
  
  def to_json(options = nil)
    %("#{to_json_format}")
  end
end