class Array
  def to_ruby
    return self unless self.size == 3
    return nil if self[0]
    type = self[1]
    value = self[2]
    case type
    when "list"
      return value.collect { |v| v.to_ruby }
    when "map"
      return value.merge(value) { |k,v1,v2| v1.to_ruby }
    when "string"
      return value
    when "integer"
      return value
    else
      raise "Can't handle #{type}"
    end
  end
end
