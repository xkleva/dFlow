class String
  require 'pp'
    def is_i?
       !!(self =~ /\A[-+]?[0-9]+\z/)
    end

    def pretty_json
      JSON.parse(self).pretty_inspect
    end
end