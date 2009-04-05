class Time
  def to_json(options = nil)
    %("#{self.dup.utc.strftime("%Y/%m/%d %H:%M:%S +0000")}")
  end
end