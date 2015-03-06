class Source

  def self.find_by_name(name)
    source = APP_CONFIG["sources"].find{|x| x["name"] == name}
    if source.nil?
      return nil
    else
      return Kernel.const_get("#{source["class_name"]}")
    end
  end

  def self.find_by_class_name(class_name)
    source = APP_CONFIG["sources"].find{|x| x["class_name"] == class_name}
    if source.nil?
      return nil
    else
      return Kernel.const_get(source["class_name"])
    end
  end

  def self.find_name_by_class_name(class_name)
    source = APP_CONFIG["sources"].find{|x| x["class_name"] == class_name}
    if source.nil?
      return nil
    else
      return source["name"]
    end
  end

  def self.find_label_by_name(name)
    source = APP_CONFIG["sources"].find{|x| x["name"] == name}
    if source.nil?
      return nil
    else
      return source["label"]
    end
  end
end
