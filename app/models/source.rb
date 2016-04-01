class Source

  def self.find_by_name(name)
    source = SYSTEM_DATA["sources"].find{|x| x["name"] == name}
    if source.nil?
      return nil
    else
      return Kernel.const_get("#{source["class_name"]}")
    end
  end

  def self.find_by_class_name(class_name)
    source = SYSTEM_DATA["sources"].find{|x| x["class_name"] == class_name}
    if source.nil?
      return nil
    else
      return Kernel.const_get(source["class_name"])
    end
  end

  def self.find_name_by_class_name(class_name)
    source = SYSTEM_DATA["sources"].find{|x| x["class_name"] == class_name}
    if source.nil?
      return nil
    else
      return source["name"]
    end
  end

  def self.find_label_by_name(name)
    source = SYSTEM_DATA["sources"].find{|x| x["name"] == name}
    if source.nil?
      return nil
    else
      return source["label"]
    end
  end

  def self.validate_required_fields(name, params)
    source = find_by_name(name)
    if source.nil?
      return false
    end
    params_keys = params.keys.map(&:to_s)
    remaining_required_fields = source.required_source_fields - params_keys
    if remaining_required_fields.empty?
      return true
    end
    false
  end
end
