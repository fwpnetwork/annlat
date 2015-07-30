# this file was named LaRuby some time ago
class Latex

  def wrap
    Wrapped.new(self)
  end

  def latex
    ""
  end

  def to_s
    latex
  end

  def to_ltx
    self
  end

  alias_method :l, :to_ltx

  def is(y)
    LatexConsec.new(self, '=', y)
  end

  def ne(y)
    LatexConsec.new(self, '\ne ', y)
  end

  def of(*args)
    Func.new(self, *args)
  end

  def +(y)
    Sum.new(self, y)
  end

  def -@
    (kind_of? Negative) ? expr : Negative.new(self)
  end

  def -(y)
    Sum.new(self, -y)
  end

  def *(y)
    Product.new(self, y)
  end

  def /(y)
    Frac.new(self, y)
  end

  def **(y)
    Expon.new(self, y)
  end

  def glue(some_expr)
    LatexConsec.new(self, some_expr)
  end

end

class Func < Latex # represents @name(@args)
  def initialize(some_name, *some_args)
    @name = some_name.to_ltx
    @args = some_args.map{|a| a.to_ltx}  
  end

  def latex
    return (@name.latex + '()') if @args.length == 0
    str = @args[0].latex
    @args[1..-1].each {|a| str += (',' + a.latex)}
    @name.latex + '(' + str + ')'
  end
end

class Wrapped < Latex   # should add support for custom wrappings
  def initialize(some_expr) 
    @wrapee = some_expr.to_ltx 
  end

  def unwrap
    @wrapee
  end

  def latex
    '(' + @wrapee.latex + ')'
  end
end

class Negative < Latex     # represents -@expr

  def initialize(some_expr) 
    @expr = some_expr.to_ltx 
    (@expr = @expr.wrap) if (@expr.kind_of?(Sum))
  end

  def latex
    '-' + @expr.latex
  end
end

class Atom < Latex

  attr_reader :expr

  def initialize(some_expr)
    @expr = some_expr.to_s
  end

  def latex
    @expr
  end

end

class LatexConsec < Latex

  def initialize(*some_parts)
    @parts = some_parts.map{|i| i.to_ltx}
  end

  def latex
    @parts.map{|i| i.latex}.join
  end

end

class BinOpe < Latex

  attr_reader :args
  attr_reader :oper

  def initialize(some_oper, *some_args)
    @oper = some_oper.to_ltx
    some_args.map!(&:to_ltx)
    first = some_args[0]
    rest = some_args[1..-1].map {|a| (a.kind_of?(BinOpe) and a.args[0].kind_of?(Negative)) ? a.wrap : a }
    @args = [first] + rest
  end

  def latex
    @args.map{|a| a.latex}.join(@oper.latex)
  end

end

class AssocBinOpe < BinOpe

  def initialize(some_oper, *some_args) 
    super(some_oper, *(some_args.map{|a| (a.kind_of?(AssocBinOpe) and (a.oper == @oper))? a.args : a}.flatten))
  end

  def latex() 
    @args.map{|i| i.latex}.join(@oper.latex)
  end

end

class Product < AssocBinOpe
  def initialize(*some_factors)
    super(Times, *some_factors)
    @args.map!{|a| (a.kind_of?(Negative) or a.kind_of?(Sum))? a.wrap : a}
  end

  def first
    @args[0]
  end

  def second
    @args[1]
  end
end

class Sum < Latex
  def initialize(*some_summands)
    @summands = some_summands.map(&:to_ltx)
  end

  def latex 
    str = @summands[0].latex
    @summands[1..-1].each{|a| a.kind_of?(Negative) ? str += (a.latex) : str += ('+' + a.latex)}
    str
  end
end

class Frac < Latex
  def initialize(some_numer, some_denom)
    @numer = some_numer.to_ltx
    @denom = some_denom.to_ltx
  end

  def latex
    '\frac{' + @numer.latex + '}{' + @denom.latex + '}'
  end
end

class Expon < Latex

  def initialize(some_base, some_exp)
    @base = some_base.to_ltx
    @exp = some_exp.to_ltx
  end

  def latex
    if @base.class <= Atom
      the_base = @base
    else
      the_base = @base.wrap
    end
    the_base.latex + '^{' + @exp.latex +  '}'
  end

end

class Fixnum
  def to_ltx
    (self >= 0) ? Atom.new(self) : -(Atom.new(-self))
  end

  alias_method :l, :to_ltx
end

class Float
  def to_ltx
    (self >= 0) ? Atom.new(self) : -(Atom.new(-self))
  end

  alias_method :l, :to_ltx
end

class String
  def to_ltx
    Atom.new(self)
  end

  alias_method :l, :to_ltx
end

class LatexList < Atom
  def initialize(arr)
    @list = arr
  end
  
  def latex
    "(" + @list.join(", ") + ")"
  end
end

class Array
  def to_ltx
    a = map{ |obj| obj.to_ltx.latex }
    LatexList.new(a)
  end
end

class LatexSet < Atom

  def initialize(s)
    @set = s.to_a
  end
  
  def latex
    "{" + @set.join(", ") + "}"
  end

end

class Set

  def to_ltx
    s = map{ |obj| obj.to_ltx.latex }
    LatexSet.new(s)
  end

end

class Rational
  def l
    self.to_f.l
  end
end

class Bignum
  def l
    self.to_s.l
  end
end

Plus = Atom.new('+')
Times = Atom.new('\cdot ')
Minus = Atom.new('-')

#      Greek alphabet
def alpha() Atom.new('\alpha ') end
def beta() Atom.new('\beta ') end
def gamma() Atom.new('\gamma ') end
def delta() Atom.new('\delta ') end
def epsilon() Atom.new('\epsilon ') end
def varepsilon() Atom.new('\varepsilon ') end
def zeta() Atom.new('\zeta ') end
def eta() Atom.new('\eta ') end
def theta() Atom.new('\theta ') end
def vartheta() Atom.new('\vartheta ') end
def kappa() Atom.new('\kappa ') end
def mu() Atom.new('\mu ') end
def nu() Atom.new('\nu ') end
def xi() Atom.new('\xi ') end
def pi() Atom.new('\pi ') end
def varpi() Atom.new('\varpi ') end
def rho() Atom.new('\rho ') end
def varrho() Atom.new('\varrho ') end
def sigma() Atom.new('\sigma ') end
def varsigma() Atom.new('\varsigma ') end
def tau() Atom.new('\tau ') end
def upsilon() Atom.new('\upsilon ') end
def phi() Atom.new('\phi ') end
def varphi() Atom.new('\varphi ') end
def chi() Atom.new('\chi ') end
def psi() Atom.new('\psi ') end
def omega() Atom.new('\omega ') end
def cGamma() Atom.new('\Gamma ') end
def cDelta() Atom.new('\Delta ') end
def cTheta() Atom.new('\Theta ') end
def cLambda() Atom.new('\Lmabda ') end
def cXi() Atom.new('\Xi ') end
def cPi() Atom.new('\Pi ') end
def cSigma() Atom.new('\Sigma ') end
def cUpsilon() Atom.new('\Upsilon ') end
def cPhi() Atom.new('\Phi ') end
def cPsi() Atom.new('\Psi ') end
def cOmega() Atom.new('\Omega ') end
