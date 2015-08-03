# coding: utf-8
module AnnLatHotkey
  def self.available_keys
    [:lparen, :rparen, :exponent, :multiply,
     :divide, :add, :subtract, :pi, :sqrt]
  end

  def self.annlat_to_latex_and_input(al)
    al.options.map do |h|
      key = h[:sentence_options][:key].to_sym
      [:lparen, :rparen, :exponent, :multiply,
       :divide, :add, :subtract, :pi, :sqrt]
      case key
      when :lparen
        ['(']*2
      when :rparen
        [')']*2
      when :exponent
        ['^']*2
      when :multiply
        ['×', '\cdot']
      when :divide
        [LatexDiv.new('','').latex, '/']
      when :add
        ['+']*2
      when :subtract
        ['-']*2
      when :pi
        [LatexPi.new.latex, '\pi']
      when :sqrt
        [LatexSqrt.new('').latex, '\sqrt']
      end
    end
  end
end
