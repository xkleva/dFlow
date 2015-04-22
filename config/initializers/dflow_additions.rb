class String
  require 'pp'
  require 'unicode'
  def is_i?
    !!(self =~ /\A[-+]?[0-9]+\z/)
  end

  def pretty_json
    JSON.parse(self).pretty_inspect
  end

  def norm
    decomposed = Unicode.nfkd(self).gsub(/[^\u0000-\u00ff]/, "")
    Unicode.downcase(decomposed)
  end
end
