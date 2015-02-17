class Source

  def self.find_by_name(name)
    classname = Rails.application.config.sources.find{|x| x[:name] == name}
    if classname.nil?
      return nil
    else
      return Kernel.const_get(classname[:class_name])
    end
  end

  def self.find_by_class_name(name)
    classname = Rails.application.config.sources.find{|x| x[:class_name] == name}
    if classname.nil?
      return nil
    else
      return Kernel.const_get(classname[:class_name])
    end
  end

  def self.find_label_by_name(name)
    classname = Rails.application.config.sources.find{|x| x[:name] == name}
    if classname.nil?
      return nil
    else
      return classname[:label]
    end
  end
end
