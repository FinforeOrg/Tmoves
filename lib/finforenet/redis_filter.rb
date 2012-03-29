module Finforenet
  module RedisFilter

    def self.get_key(category)
      "#{category}_list".downcase
    end

    def self.get_array_ids(category)
      $redis.lrange get_key(category), 0, 30
    end

    def self.del_data(category)
      $redis.del get_key(category)
    end
    
    def self.push_data(category,value)
      tmp_arr = get_array_ids(category)
      $redis.lpop get_key(category) if (tmp_arr.length > 15)
      if tmp_arr.include?(value)
        return false
      else
        $redis.rpush get_key(category), value
        return true
      end
    end

  end
end
