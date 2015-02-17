# annlat/latex_eval
# This file extends various objects from standard ruby and annlat/latex_ruby in order to add
# the ability to simplify and evaluate latex expression trees involving numbers.  There are also
# methods such as :symbol.l that simplify the creation of latex expression trees.  Additionally, the
# ability to convert a latex string into a latex expression tree is added to the string class
# via the #parse_latex method
#
# Author:: Larry Reaves
# License:: MIT

class Symbol
  def l
    self.to_s.l
  end
end

class String
  def l
    if self.match /\\ /
      Atom.new(self)
    else
      tokens = self.split(' ')
      if tokens.size > 1
        tokens.inject do |total, token|
          total = Text.new(total.l) unless total.class <= Latex
          total = total.glue(token.l)
          total
        end
      else
        Atom.new(tokens[0])
      end
    end
  end

  def parse_latex(tokens = nil)
    tokens ||= latex_tokenize
    latex_tokens = classify_tokens(tokens)

    # convert invalid subtractions to negatives
    begin
      i = 0
      t = latex_tokens.detect do |t|
        result = (t.class <= DelayedLatexOp and t.is?(:-) and
                  (i - 1 < 0 or latex_tokens[i - 1].class <= DelayedLatexOp))
        i += 1 unless result
        result
      end
      if t
        latex_tokens.delete_at(i)
        latex_tokens[i] = Negative.negate(latex_tokens[i])
      end
    end while t

    ops.each do |op|
      sym = op_syms[op]
      begin
        t = latex_tokens.detect do |t|
          t.class <= DelayedLatexOp and t.is?(sym)
        end
        if t
          t_index = latex_tokens.index(t)
          # left and right indices
          l_i = t_index - 1
          r_i = t_index + 1
          unless r_i < latex_tokens.size and l_i >= 0
            raise SyntaxError, "no valid ops for DelayedLatexOp"
          end

          t.left = latex_tokens[l_i]
          t.right = latex_tokens[r_i]
          # build latex now that we have both arguments
          latex_tokens[t_index] = t.l

          if l_i >= 0
            latex_tokens.delete_at(l_i)
            latex_tokens.delete_at(r_i - 1)
          else
            latex_tokens.delete_at(r_i)
          end
        end
      end while t
    end

    # combine atoms
    if latex_tokens.size > 1
      raise SyntaxError, "tokens did not create a single Latex object"
    else
      latex_tokens[0]
    end
  end

  private
  def latex_tokenize
    @@latex_tokens ||= ops + [
                              '\left(',
                              '\right)',
                              '\frac{',
                              '{', '}',
                              '<=', '>=',
                              '=', '<',
                              '>', '\leq',
                              '\geq']

    # strip whitespace
    clean = self.gsub(/ /, '')

    tokens = []
    i = 0
    begin_token = 0
    begin
      found = false
      @@latex_tokens.each do |t|
        # does this token start at i
        if clean[i, t.size] == t
          # if we have accumulated an Atom, add it
          tokens << clean[begin_token..i - 1] unless begin_token == i
          # add the found token
          tokens << t
          found = true
          # next token starts after this one
          begin_token = i + t.size
          # start looking at beginning of next token
          i = begin_token
          break
        end
      end
      # if we found a token, i is already adjusted
      i += 1 unless found
    end while i < clean.size
    # grab last Atom unless we ended on a token
    tokens << clean[begin_token..-1] unless found
    tokens
  end

  def extract_paren(tokens)
    left = '\left('
    right = '\right)'
    extract_generic(tokens, left, right)
  end


  def extract_frac(tokens)
    left = '\frac{'
    second_left = '{'
    right = '}'

    before, first, rest = extract_generic(tokens, left, right)
    raise SyntaxError, 'missing denominator in \frac{}{}' unless rest[0] == second_left
    _, second, after = extract_generic(rest, second_left, right, left)
    [before, first, second, after]
  end

  def extract_generic(tokens, left, right, other_left = nil)
    left_i = tokens.index(left)
    cursor = left_i + 1
    count = 1
    begin
      next_left = tokens[cursor..-1].index(left)
      # for \frac{}{} left can be \frac{ or just {
      if other_left
        other_left = tokens[cursor..-1].index(other_left)
        next_left = other_left if other_left and other_left < next_left
      end
      next_right = tokens[cursor..-1].index(right)
      raise SyntaxError, "Nesting mismatch using #{left}#{right} pair" if next_right.nil?
      if next_left.nil? or next_right < next_left
        if count == 0
          cursor = cursor + next_right + 1
          break
        elsif (next_left and next_right < next_left) or
            next_right
          count -= 1
          cursor += next_right + 1
        else
          raise SyntaxError, "Nesting mismatch using #{left}#{right} pair"
        end
      else
        cursor += next_left + 1
        count += 1
      end
    end while count > 0

    [tokens[0,left_i], tokens[left_i + 1..cursor - 2], tokens[cursor..-1]]
  end

  def classify_tokens(tokens)
    return [] if tokens.nil? or tokens.empty?

    # handle comparisons
    comp_ops = {
      '=' => :is,
      '<' => :<,
      '>' => :>,
      '<=' => :<=,
      '\leq' => :<=,
      '>=' => :>=,
      '\geq' => :>=
    }
    ['=', '<', '>', '<=', '>=', '\leq', '\geq'].each do |c|
      if tokens.include?(c)
        index = tokens.index(c)
        op = comp_ops[c]
        first = parse_latex(tokens[0,index])
        second = parse_latex(tokens[index+1..-1])
        tokens = [first.send(op, second)]
      end
    end

    if tokens.include?('\left(') or tokens.include?('\frac{')
      mode = :parens
      # if we have both, find the first
      if tokens.include?('\left(') and tokens.include?('\frac{')
        paren_i = tokens.index('\left(')
        frac_i = tokens.index('\frac{')
        if frac_i < paren_i
          mode = :frac
        end
      elsif tokens.include?('\frac{')
        mode = :frac
      end

      if mode == :parens
        # handle parens
        before, during, after = extract_paren(tokens)
        tokens = classify_tokens(before) + [parse_latex(during)] + classify_tokens(after)
      else
        # handle fractions
        before, first, second, after = extract_frac(tokens)
        tokens = classify_tokens(before) + [parse_latex(first) / parse_latex(second)] +
          classify_tokens(after)
      end
    else
      raise SyntaxError, "Mismatched right paren" if tokens.include?('\right)')
      raise SyntaxError, "Mismatched }" if tokens.include?('}')

      tokens = parse_operators(tokens, ops, op_syms)
      tokens = parse_atoms(tokens)
    end
    tokens
  end

  def ops
    @@ops ||=[
             '^',
             '\cdot',
             '+',
             '-'
            ]
  end

  def op_syms
    @@op_syms ||= {
        '^' => :**,
        '\cdot' => :*,
        '+' => :+,
        '-' => :-
      }
  end

  def parse_atoms(tokens)
    tokens = tokens.collect! do |t|
      t = Atom.new(t) unless t.class <= Latex or t.class <= DelayedLatexOp
      t
    end
    tokens
  end

  def parse_operators(tokens, ops, op_syms)
    ops.each do |op|
      token_index = 0
      sym = op_syms[op]

      tokens.collect! do |t|
        if t.class <= String
          op_index = t.index(op)
          if op_index
            t = DelayedLatexOp.new(sym)
          end
        end
        token_index += 1
        t
      end
    end
    tokens
  end
end

class DelayedLatexOp
  attr_accessor :left, :right

  def initialize(op)
    @op = op
  end

  def is?(op)
    @op == op
  end

  def l
    @l ||= begin
             raise ArgumentError, "DelayedLatexOp missing left" unless @left
             raise ArgumentError, "DelayedLatexOp missing right" unless @right
             @left.send(@op, @right)
           end
  end
end

class Term < Product
  # override cdot
  def latex
    @args.map{|l| l.latex}.join
  end
end

class Underline < Latex
  def initialize(b)
    @base = b
  end

  def latex
    "\\underline{#{@base.latex}}"
  end
end

class LongDivision < Latex
  def initialize(n, d)
    @n = n
    @d = d
  end

  def latex
    "#{@d} \\enclose{longdiv}{#{@n}}"
  end
end

class LatexDiv < Latex
  def initialize(first, second)
    @first = first
    @second = second
  end

  def latex
    "#{@first}\\div#{@second}"
  end
  
  def walk!
    @first = @first.walk! do |n|
      yield n
    end
    @second = @second.walk! do |n|
      yield n
    end
    self
  end
end

class Latex
  def %(other)
    Term.new(self, other)
  end

  def div(other)
    LatexDiv.new(self, other)
  end

  def <(other)
    LatexConsec.new(self, '<', other)
  end

  def >(other)
    LatexConsec.new(self, '>', other)
  end

  def <=(other)
    LatexConsec.new(self, '\leq', other)
  end

  def >=(other)
    LatexConsec.new(self, '\geq', other)
  end

  def dup
    Marshal.load(Marshal.dump(self))
  end

  def underline
    Underline.new(self)
  end

  def method_missing(name, *args, &block)
    @@walk_bases ||= {}
    @@walk_bases[Atom] ||= true

    if name == :walk! and @@walk_bases[self.class]
      yield self
    else
      super
    end
  end

  def subs(parameters)
    atom = nil
    atom = true if self.class == Atom
    self.walk! do |l|
      l = parameters[l.latex] if parameters[l.latex]
      return l if atom
      l
    end
    self
  end

  def simplify_full!
    new = self
    begin
      old = new
      new = old.dup.simplify!
      new = new.simplify!(true)
    end while new.latex != old.latex
    new
  end

  def simplify_trivial!
    self.simplify!(true)
  end

  private
  def r(answer, places = 4)
    if answer == answer.to_i
      answer.to_i 
    else
      answer.round(places)
    end
  end
end

class Frac < Latex
  def walk!
    @numer = @numer.walk! do |n|
      yield n
    end
    @denom = @denom.walk! do |n|
      yield n
    end
    self
  end

  def simplify!(trivial = false)
    n_l = @numer.latex
    d_l = @denom.latex
    if trivial
      return @numer.simplify_trivial! if d_l == "1"
      return Negative.negate(@numer.simplify_trivial!) if d_l == "-1"
      return Atom.new(0) if n_l == "0"

      @numer = @numer.simplify_trivial!
      @denom = @denom.simplify_trivial!

      nc = @numer.class
      dc = @denom.class
      if nc == Negative and dc == Negative
        # both are negative, negatives cancel
        @numer = Negative.negate(@numer)
        @denom = Negative.negate(@denom)
        return self
      elsif nc == Negative or dc == Negative
        # one is negative, pull out the sign
        if nc == Negative
          @numer = Negative.negate(@numer)
        else
          @denom = Negative.negate(@denom)
        end
        return Negative.negate(self)
      end
      self
    else
      begin
        self.eval.l
      rescue ArgumentError
        return @numer.simplify! if d_l == "1"
        return Negative.negate(@numer.simplify!) if d_l == "-1"
        @numer = @numer.simplify!
        @denom = @denom.simplify!
        self
      end
    end
  end

  def eval
    r(@numer.eval.to_f / @denom.eval.to_f)
  end

  def to_string
    "#{@numer}/#{@denom}"
  end

  def reduce
    begin
      n = @numer.eval
      d = @denom.eval
      div = gcd(@numer.eval, @denom.eval)
      return Atom.new(n/div) if d/div == 1
      @numer = Atom.new(n/div)
      @denom = Atom.new(d/div)
    rescue
      "Error, can not reduce unless integers"
    end
    self
  end

  def simplify_nd
    begin
      @numer = Atom.new(@numer.eval)
      @denom = Atom.new(@denom.eval)
    rescue
      "Error, can not reduce unless integers"
    end
    self
  end

  def gcd(a, b)
    return a if b == 0
    gcd(b, a % b)
  end
end

class Text < Latex
  def initialize(atom)
    @atoms = [atom]
  end

  def glue(atom)
    @atoms << atom
    self
  end

  def latex
    @atoms.collect{|a| a.latex}.join '\ '
  end

  def to_string
    @atoms.collect{|a| a.latex}.join ' '
  end

  def walk!
    @atoms.collect! do |atom|
      atom.walk! do |a|
        yield a
      end
    end
    # if we replaced any atoms with
    # a string containing a space,
    # change that atom to text
    new_atoms = []
    @atoms.each do |a|
      if a.to_s.match(/ /)
        t = a.to_s.l
        t.atoms.each do |new_a|
          new_atoms << new_a
        end
      else
        new_atoms << a
      end
    end
    @atoms = new_atoms
    self
  end

  def simplify!(trivial = false)
    self
  end

  def eval
    raise ArgumentError
  end

  def atoms
    @atoms
  end
end

class LatexConsec < Latex
  def lhs
    @parts[0]
  end

  def rhs
    @parts[2]
  end

  def walk!
    @parts.collect! do |item|
      item.walk! do |i|
        yield i
      end
    end
    self
  end

  def simplify!(trivial = false)
    @parts.collect! do |p|
      if trivial
        p.simplify!(trivial)
      else
        begin
          p.eval.l
        rescue ArgumentError
          p.simplify!
        end
      end
    end
    self
  end

  def eval
    # attempt to evaluate each part
    @parts.collect! do |p|
      begin
        p.eval.l
      rescue ArgumentError
        p
      end
    end
    # throw ArgumentError anyway, this type doesn't map to a value
    raise ArgumentError
  end
end

class Wrapped < Latex
  def walk!
    @wrapee = @wrapee.walk! do |w|
      yield w
    end
    self
  end

  def eval
    @wrapee.eval
  end

  def simplify!(trivial = false)
    if trivial
      # unwrap negatives... not sure why Product wraps them
      return @wrapee if @wrapee.class == Negative
      @wrapee = @wrapee.simplify!(trivial)
      self
    else
      begin
        @wrapee.eval.l
      rescue ArgumentError
        @wrapee = @wrapee.simplify!
        self
      end
    end
  end
end

class Atom < Latex
  def eval
    r(@expr.to_f) if Float(@expr)
  end

  def simplify!(trivial = false)
    if trivial
      self
    else
      begin
        self.eval.l
      rescue ArgumentError
        self
      end
    end
  end

  def has_number
    begin
      self.eval
    rescue ArgumentError
      false
    end
  end

  def to_s
    @expr.to_s
  end
end

class Negative < Latex
  def self.negate(expr)
    return expr.expr if expr.class == Negative
    return self.new(expr)
  end

  def expr
    @expr
  end

  def walk!
    @expr = @expr.walk! do |e|
      yield e
    end
    self
  end

  def simplify!(trivial = false)
    if trivial
      @expr = @expr.simplify!(trivial)
      # eliminate nested negatives
      return @expr.instance_eval { self.expr } if @expr.class == Negative
      self
    else
      begin
        (-@expr.eval).l
      rescue ArgumentError
        @expr = @expr.simplify!
        self
      end
    end
  end

  def eval
    -@expr.eval
  end

  def has_number
    begin
      self.eval
    rescue ArgumentError
      false
    end
  end
end

class Sum < Latex
  def walk!
    @summands.collect! do |item|
      item.walk! do |i|
        yield i
      end
    end
    self
  end

  def eval
    throw TooManySummandsError if @summands.size > 2

    sum = @summands.inject(0) do |accum, s|
      accum += s.eval
    end

    r(sum)
  end

  def simplify!(trivial = false)
    if trivial
      # return the other summand if one is zero
      other = [0, 1]
      @summands.each_index do |i|
        other.delete(i) if @summands[i].latex == "0"
      end
      return @summands[other[0]].simplify!(trivial) if other.size == 1

      # otherwise simplify each summand
      @summands.collect! do |s|
        s.simplify!(trivial)
      end

      self
    else
      begin
        self.eval.l
      rescue ArgumentError
        # return the other summand if one is zero
        other = [0, 1]
        @summands.each_index do |i|
          other.delete(i) if @summands[i].latex == "0"
        end
        return @summands[other[0]] if other.size == 1

        # handle nested summands, assume only 2 summands
        # eval will throw an error if there are more than 2
        # for the moment we don't handle negated sums,
        # only negated atoms
        c0 = @summands[0].class
        nc0 = Negative.negate(@summands[0]).class
        c1 = @summands[1].class
        nc1 = Negative.negate(@summands[1]).class
        if (c0 == Atom or c0 == Sum or nc0 == Atom) and
            (c1 == Atom or c1 == Sum or nc1 == Atom)
          begin
            left = @summands[0].eval
            right = @summands[1].eval
          rescue ArgumentError
            # we know at least one will fail, so if left is defined, right failed
            # so check right for a number
            if left and n = @summands[1].has_number
              # since Atoms will succeed at eval if they have a number,
              # we know right is a Sum

              # replace left with sum of left and number from right
              @summands[0] = Atom.new(left + n)
              # replace right with non number from right
              @summands[1] = @summands[1].non_number
              # left failed, so check right
            else
              begin
                # left failed, check right
                right = @summands[1].eval
                # right is number, check left for number
                if n = @summands[0].has_number
                  # we know we have a Sum on the left since left.eval failed
                  # replace right with sum of right and number from left
                  @summands[1] = Atom.new(right + n)
                  # replace left with non number from left
                  @summands[0] = @summands[0].non_number
                end
              rescue ArgumentError
                # both fail, check if each has a number
                left_n = @summands[0].has_number
                right_n = @summands[1].has_number
                if left_n and right_n
                  # save left non number
                  left_non = @summands[0].non_number
                  # replace left with sum of non_numbers from each
                  @summands[0] = left_non + @summands[1].non_number
                  # replace right with sum of numbers from each
                  @summands[1] = Atom.new(left_n + right_n)
                end
              end
            end
          end
        end
        # end nested sums

        @summands.collect! do |s|
          s.simplify!
        end
        self
      end
    end
  end

  protected
  def has_number
    begin
      @summands[0].eval
    rescue ArgumentError
      begin
        @summands[1].eval
      rescue ArgumentError
        false
      end
    end
  end

  def non_number
    begin
      @summands[0].eval
      @summands[1]
    rescue ArgumentError
      begin
        @summands[1].eval
        @summands[0]
      rescue ArgumentError
        self
      end
    end
  end
end

class Expon < Latex
  def walk!
    @base = @base.walk! do |b|
      yield b
    end
    @exp = @exp.walk! do |e|
      yield e
    end
    self
  end

  def eval
    r(@base.eval ** @exp.eval)
  end

  def simplify!(trivial = false)
    if trivial
      @base = @base.simplify_trivial!
      @exp = @exp.simplify_trivial!
      self
    else
      begin
        self.eval.l
      rescue ArgumentError
        @base = @base.simplify!
        @exp = @exp.simplify!
        self
      end
    end
  end
end

class BinOpe < Latex
  def walk!
    @args.collect! do |arg|
      arg.walk! do |a|
        yield a
      end
    end
    self
  end

  def eval
    r(@args[0].eval.send(oper_to_sym(@oper), @args[1].eval))
  end

  def simplify!(trivial = false)
    if trivial
      # return other arg if operation is multiplication and
      # the other is "1", Negative of arg if "-1"
      # also, return 0 if either arg is 0
      if oper_to_sym(@oper) == :*
        l0 = @args[0].latex
        return @args[1].simplify_trivial! if l0 == "1"
        return Negative.negate(@args[1].simplify_trivial!) if l0 == "-1"
        l1 = @args[1].latex
        return @args[0].simplify!(trivial) if l1 == "1"
        return Negative.negate(@args[0].simplify!(trivial)) if l1 == "-1"
        if l0 == "0" or l1 == "0"
          return Atom.new(0)
        end

        # simplify each arg
        @args.collect! do |a|
          a.simplify!(trivial)
        end

        c0 = @args[0].class
        c1 = @args[1].class

        if c0 == Negative and c1 == Negative
          # if both arguments are negative, negatives cancel
          @args[0] = Negative.negate(@args[0])
          @args[1] = Negative.negate(@args[1])
          return self
        elsif c0 == Negative or c1 == Negative
          # one is negative, pull its sign out
          if c0 == Negative
            @args[0] = Negative.negate(@args[0])
          else
            @args[1] = Negative.negate(@args[1])
          end
          return Negative.negate(self)
        end
      end

      self
    else
      begin
        self.eval.l
      rescue ArgumentError
        if oper_to_sym(@oper) == :*
          return @args[1].simplify! if @args[0].latex == "1"
          return Negative.negate(@args[1].simplify!) if @args[0].latex == "-1"
          return @args[0].simplify! if @args[1].latex == "1"
          return Negative.negate(@args[0].simplify!) if @args[1].latex == "-1"
        end
        @args.collect! do |a|
          a.simplify!
        end
        self
      end
    end
  end

  private
  def oper_to_sym(oper)
    case @oper.latex
    when '\cdot '
      :*
    else
      @oper.latex.to_sym
    end
  end
end

module LatexPlots
  def occurrences_numerical
    occ = self.occurrences
    new_hash = {}
    occ.keys.each do |latex_str|
      begin
        num = latex_str.parse_latex.eval
      rescue ArgumentError
        puts "warning: dot_plot requires numerical data"
        num = 0
      end
      new_hash[num] = occ[latex_str]
    end
    new_hash
  end

  def dot_plot
    occ = self.occurrences_numerical
    items = occ.keys
    min_x = items.min
    max_x = items.max
    min_y = 0
    max_y = occ.values.max
    plot = [(min_x..max_x).to_a]
    plot[0][0] = "\\hline" + plot[0][0].to_s
    while items.size > 0
      row = []
      (min_x..max_x).to_a.each do |x|
        if items.include?(x)
          row << "\\bigcirc"
        else
          row << "\\ "
        end
      end
      new_hash = {}
      items.each do |i|
        occ[i] -= 1
        new_hash[i] = occ[i] unless occ[i] == 0
      end
      occ = new_hash
      items = occ.keys
      plot.unshift row
    end
    latex_plot = plot.l
    latex_plot.set_lines(:outside)
    latex_plot
  end

  def bar_chart(id=0)
    require 'gnuplot'

    filename = "bar_chart_#{id}.png"

    occ = self.occurrences_numerical
    items = occ.keys
    min_x = items.min
    max_x = items.max
    min_y = 0
    max_y = occ.values.max + 1

    png = Gnuplot.open do |gp|
      Gnuplot::Plot.new(gp) do |plot|

        plot.terminal "pngcairo"
        plot.output filename

        plot.style  "data histograms"
        plot.style "histogram gap 1"
        plot.yrange "[#{min_y}:#{max_y}]"
        plot.xlabel "#{@title}\" font \",15"
        plot.xtics "center nomirror out font \",15\""
        plot.ytics "1"

        x = []
        y = []
        (min_x..max_x).to_a.each do |current_x|
          x << current_x
          current_y = occ[current_x]
          current_y ||= 0
          y << current_y
        end

        plot.data << Gnuplot::DataSet.new( [x, y] ) do |ds|
          ds.title = ""
          ds.using = "2:xtic(1)"
        end
      end
    end

    filename
  end

  def bar_chart_latex
    occ = self.occurrences_numerical
    items = occ.keys
    min_x = items.min
    max_x = items.max
    min_y = 0
    max_y = occ.values.max
    plot = [(min_x..max_x).to_a.unshift("\\hline \\ ")]
    row_count = 1
    while items.size > 0
      row = ["^{#{row_count}-}"]
      (min_x..max_x).to_a.each do |x|
        if items.include?(x)
          if occ[x] == 1
            row << "\\lceil\\rceil"
          else
            row << "|\\ |"
          end
        else
          row << "\\ "
        end
      end
      new_hash = {}
      items.each do |i|
        occ[i] -= 1
        new_hash[i] = occ[i] unless occ[i] == 0
      end
      occ = new_hash
      items = occ.keys
      plot.unshift(row)
      row_count += 1
    end
    latex_plot = plot.l
    latex_plot.set_lines(:outside)
    latex_plot.row_spacing = ["-5pt"] * (row_count-2)
    latex_plot
  end

  def box_plot(id=0)
    require 'gnuplot'

    occ = self.occurrences_numerical
    items = occ.keys
    min_x = items.min - 1
    max_x = items.max + 1

    filename = "box_plot_#{id}.png"

    Gnuplot.open do |gp|
      Gnuplot::Plot.new(gp) do |plot|

        plot.terminal "pngcairo"
        plot.output filename

        plot.style  "data boxplot"
        plot.unset "xtics"
        plot.grid "y2tics lc rgb \"#888888\" lw 1 lt 0"
        plot.yrange "[#{min_x}:#{max_x}]"
        plot.y2range "[#{min_x}:#{max_x}]"
        plot.y2tics "center rotate by 90 font \",15\""
        plot.unset "ytics"
        plot.y2label "#{@title}\" font \",15"

        x = []
        y = []
        (min_x..max_x).to_a.each do |current_x|
          occ[current_x].times do
            x << 1
            y << current_x
          end if occ[current_x]
        end

        plot.data << Gnuplot::DataSet.new([x, y]) do |ds|
          ds.title = ''
        end
      end
    end

    `convert -rotate 90 #{filename} #{filename}`

    filename
  end

  def box_plot_latex
    "unimplemented".l
  end

  def cont_plot(id=0)
    require 'gnuplot'

    filename = "cont_plot_#{id}.png"
    mu, sigma = @rows[0].collect {|x| x.eval}

    Gnuplot.open do |gp|
      gp.write "invsqrt2pi = 0.398942280401433\n"
      gp.write "normal(x,mu,sigma)=sigma<=0?1/0:invsqrt2pi/sigma*exp(-0.5*((x-mu)/sigma)**2)\n"

      Gnuplot::Plot.new(gp) do |plot|

        plot.terminal "pngcairo"
        plot.output filename

        plot.style  "data lines"
        plot.xrange "[#{mu - 2*sigma - 1}:#{mu + 2*sigma + 1}]"
        plot.yrange "[0:1.1*(normal(#{mu}, #{mu}, #{sigma}) - normal(#{mu - 2*sigma}, #{mu}, #{sigma}))]"
        plot.xlabel "#{@title}\" font \",15"
        plot.xtics "1 font \",15\""
        plot.unset "ytics"

        plot.data << Gnuplot::DataSet.new("normal(x, #{mu}, #{sigma}) - normal(#{mu - 2*sigma}, #{mu}, #{sigma})") do |ds|
          ds.title = ''
        end
      end
    end

    filename
  end

  def cont_plot_latex
    "unimplemented".l
  end

  def set_lines(lines)
    @h_lines = lines
    @v_lines = lines
  end

  def plot_type=(type)
    @plot_type = type
  end

  def plot_type
    @plot_type
  end

  def row_spacing=(spacing)
    @row_spacing = spacing
  end

  def title=(t)
    if t.respond_to?(:to_string)
      @title = t.to_string
    else
      @title = t.to_s
    end
  end

  def align=(a)
    @align = a
  end

  def latex(h_lines = :all, v_lines = :all)
    @plot_type ||= :array
    @row_spacing ||= []
    if @plot_type != :array
      if [:cont_plot, :bar_chart, :box_plot].include? @plot_type
        self.send((@plot_type.to_s + "_latex").to_sym).latex
      else
        self.send(@plot_type).latex
      end
    else
      h_lines = @h_lines if @h_lines
      v_lines = @v_lines if @v_lines
      str = "\\begin{array}{"
      str += "|" if [:all, :outside].include?(v_lines)
      align = @align
      align ||= "c"
      index = 0
      @rows[0].size.times do
        str += align
        unless index == @rows[0].size - 1
          str += "|" if [:all, :inside].include?(v_lines)
        end
        index += 1
      end
      str += "|" if [:all, :outside].include?(v_lines)
      str += "}\n"
      str += "\\hline " if [:all, :outside].include?(h_lines)
      index = 0
      str += @rows.collect do |row|
        r = row.collect do |item|
          item.latex
        end.join('&') + "\\\\"
        r += "[#{@row_spacing[index]}]" if @row_spacing[index]
        r += "\n"
        unless index == @rows.size - 1
          r += "\\hline " if [:all, :inside].include?(h_lines)
        end
        index += 1
        r
      end.join
      str += "\\hline \n" if [:all, :outside].include?(h_lines)
      str += "\\end{array}"
    end
  end
end

class LatexTable < Latex
  include LatexPlots

  def initialize(rows)
    @rows = rows
    @rows.collect! do |row|
      row.collect! do |item|
        item = item.l unless item.class <= Latex
        item
      end
    end
  end

  def walk!
    @rows.collect! do |row|
      row.collect! do |item|
        item.walk! do |i|
          yield i
        end
      end
    end
    self
  end

  def eval
    throw ArgumentError
  end

  def simplify!(trivial = false)
    @rows.collect! do |row|
      row.collect! do |item|
        item.simplify!(trivial)
      end
    end
    self
  end

  def sum(sorted = false)
    data = self.flat
    data = data.sort do |a, b|
      a.eval <=> b.eval
    end if sorted
    data.inject(0.l) do |sum, d|
      sum += d
    end.simplify_trivial!
  end

  def mean
    (self.sum / self.size).eval
  end

  def median
    s = self.sorted
    sz = self.size
    if sz % 2 == 1
      s[sz/2].l
    else
      [[s[sz/2 - 1], s[sz/2]]].l.sum/2.l
    end
  end

  def mode
    occur = self.occurrences
    v = occur.values
    r(occur.keys[v.index(v.max)].to_f)
  end

  def range
    s = self.sorted
    s[-1] - s[0]
  end

  def mad
    m = self.mean
    [self.flat.map do |d|
       r((d.eval - m).abs)
     end].l.mean
  end

  def middle_half
    s = self.sorted
    sz = s.size
    h = sz/2
    m = h
    [s[m - h/2..m + (h+1)/2 - 1]].l
  end

  def highlight_middle
    s = self.sorted
    sz = s.size
    h = sz/2
    m = h
    middle = s[m - h/2..m + (h+1)/2 - 1].map do |datum|
      datum.l.underline
    end

    [s[0..m - h/2 - 1] + middle + s[m + (h+1)/2..-1]].l
  end

  def middle_quarter
    s = self.sorted
    sz = s.size
    q = sz/4
    m = sz/2
    [s[m - q/2..m + (q+1)/2 - 1]].l
  end

  def iqr
    q = self.quartiles
    q[-1].l - q[0].l
  end

  def quartiles
    q = []
    s = self.sorted
    sz = self.size
    q[0] = [s[0..sz/2 - 1]].l.median.eval
    q[1] = self.median.eval
    if sz % 2 == 1
      q[2] = [s[sz/2 + 1..-1]].l.median.eval
    else
      q[2] = [s[sz/2..-1]].l.median.eval
    end
    q
  end

  def size
    @rows.size * @rows[0].size
  end

  def occurrences
    hash = {}
    self.flat.each do |item|
      l = item.latex
      hash[l] = 0 unless hash[l]
      hash[l] += 1
    end
    hash
  end

  def sorted
    flat.map{|i| i.eval}.sort
  end

  def flat
    @rows.flatten
  end
end

class Array
  def l
    LatexTable.new(self)
  end
end
