require_relative 'LatexEval.rb'

# author: Larry Reaves
# ExpressionHelper module and Latex customizations in LatexEval
# that simplify expression creation, simplification, and evaluation

module ExpressionHelper
  def generate(opts)
    diff = opts[self.class.to_s]

    @parameters ||= {}

    if @ranges and @parameters.empty?
      new_ranges = {}
      # convert Symbol to String for keys
      # convert Range to Array for values
      @ranges.each_key do |k|
        if k.class <= String
          new_k = k
        else
          new_k = k.to_s
        end
        v = @ranges[k]
        v = v.to_a unless v.class <= Array
        new_ranges[new_k] = v
      end
      @ranges = new_ranges

      unselected = @ranges
      # first, select parameters with uniqueness requirements
      if @uniques
        @uniques.each do |u|
          # for each unique group
          used = {}
          u.each do |k|
            key = k.to_s
            begin
              # sample range until we get a unique parameter
              @parameters[key] = Atom.new(@ranges[key].sample)
            end while used[@parameters[key].latex]
            # record used params
            used[@parameters[key].latex] = true
            # remove selected key
            unselected.delete(key)
          end
        end
      end

      # select remaining parameters
      unselected.each_pair do |var, range|
        @parameters[var] = Atom.new(range.sample)
      end
    elsif @parameters.empty?
      # old-style fixed ranges for compatibility
      @coefficients.each do |c|
        @parameters[c.to_s] = rand((2 + 5*(diff + 0.2)).to_i) + 1
      end

      used = {}
      @variables.each do |v|
        k = v.to_s
        begin
          @parameters[k] = alphabet[rand(alphabet.size)]
        end until used[@parameters[k]].nil?
        used[@parameters[k]] = true
        if @parameters[k] == 'u'
          used['n'] = true
        elsif @parameters[k] == 'n'
          used['u'] = true
        elsif @parameters[k] == 'p'
          used['q'] = true
        elsif @parameters[k] == 'q'
          used['p'] = true
        end
      end

      @summands.each do |s|
        @parameters[s.to_s] = rand((100*(diff + 0.2)).to_i) + 1
      end

      @parameters.each_key do |k|
        val = @parameters[k]

        # randomly invert if number
        begin
          val = val.to_f if Float(val)
          if rand(2) == 0
            @parameters[k] = Negative.negate(r(val))
          else
            @parameters[k] = Atom.new(r(val))
          end
        rescue ArgumentError
          # otherwise, form an atom
          @parameters[k] = Atom.new(val)
        end
      end
    end

    if @delayed_forms
      eval @delayed_forms
    end

    unless @form_index
      if diff == 0
        if @testing
          @form_index = rand(@forms.size)
        else
          @form_index = rand(2)
        end
      elsif diff < 0.5
        @form_index = rand(3)
      else
        @form_index = rand(@forms.size)
      end
    end

    @form = @forms[@form_index]
  end

  private
  def init_forms(form_index, params)
    @forms = []
    @answers = []
    @form_index = form_index
    @parameters = {}
    unless params.nil?
      params.each_pair do |k, v|
        @parameters[k.to_s] = Atom.new v
      end
    end
  end

  def form
    Marshal.load(Marshal.dump(@form))
  end

  def expression
    @expression ||= form.subs(p).simplify_full!
    Marshal.load(Marshal.dump(@expression))
  end

  def options
    @options ||= [@answers[@form_index]].l.subs(p).flat
    Marshal.load(Marshal.dump(@options))
  end

  def alphabet
    @@alphabet ||= ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
  end

  def birds
    @@birds ||= ["blue jay", "cardinal", "swallow", "finch", "hawk", "eagle"]
  end

  def crops
    @@crops ||= ["soybeans", "corn", "bell peppers", "wheat", "carrots", "green beans", "lettuce", "kale"]
  end

  def dogs
    @@dogs ||= ["beagle", "golden retriever", "poodle", "bulldog", "pitbull"]
  end

  def fish
    @@fish ||= ["salmon", "blue gill", "trout", "bass", "swordfish"]
  end

  # round
  def r(answer, places = 2)
    if answer == answer.to_i
      answer.to_i
    else
      answer.round(places)
    end
  end

  # parameters
  def p
    @parameters
  end
end
