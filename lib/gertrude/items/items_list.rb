class ItemsList
  include TestHelpers::Wait

  attr_accessor :items
  RESERVE_KEY = "reserved_#{SecureRandom.hex(4)}".to_sym

  def load_items!(yml)
    config = YAML.load_file(yml)
    config.each_key do |type|
      config[type].each_key do |item|
        config[type][item] = {} if config[type][item].nil?
        config[type][item][RESERVE_KEY] = false
      end
    end
    raise ItemError::ItemsNotUnique.new unless unique_keys_across_items?(config)
    @items = config
  end

  def unique_keys_across_items?(config)
    item_keys = []
    config.each_value { |v| item_keys.push(v.keys) }
    item_keys.flatten!
    item_keys.count == item_keys.uniq.count
  end

  def get_item(type, timeout)
    raise ItemError::ItemTypeNotDefined.new(type) unless @items.has_key? type
    loop_for_item(type, timeout)
  end

  def release_item(item)
    raise ItemError::InvalidItem.new(item) unless @items.has_deep_key?(item)
    @items.deep_find(item)[RESERVE_KEY] = false
  end

  def get_reserved_items
    reserved_items.join(", ")
  end

  def release_all_items
    raise ItemError::NoReservedItems if reserved_items.empty?
    @items.each_key do |type|
      @items[type].each_key do |item|
        @items[type][item][RESERVE_KEY] = false if @items[type][item][RESERVE_KEY]
      end
    end
    "All Items Released."
  end

  def reserved_items
    taken_items = []
    @items.each_key do |type|
      @items[type].each_key do |item|
        taken_items << item if @items[type][item][RESERVE_KEY]
      end
    end
    taken_items
  end

  def loop_for_item(type, timeout)
    item = wait_until(timeout: timeout) do
      item = get_available_item(type)
      raise ItemError::NoAvailableItems if item.empty?
      item
    end
    reserve_item(type, item.keys.first)
    sanitize_response(item)
  end

  def sanitize_response(item)
    x = Marshal.load(Marshal.dump(item))
    x.first.last.delete(RESERVE_KEY)
    x
  end

  def reserve_item(type, item_key)
    @items[type][item_key][RESERVE_KEY] = true
  end

  def get_available_item(type)
    Hash[*@items[type].select { |item| !@items[type][item][RESERVE_KEY] }.first]
  end
end