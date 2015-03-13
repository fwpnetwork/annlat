require "annlat/latex_eval"

# ExpressionHelper module simplifies the creation of question forms and
# unifies most of the #generate method functionality across all concepts.
# While each concept can still utilize subconcept rankings to modify the parameter ranges,
# when using ExpressionHelper, the main concept ranking is used to determine which of several
# forms to use.  These forms are defined in the nonfinal concept's initialize method.
#
# To use the ExpressionHelper in a concept, first require it:
#   require "annlat/expression_helper"
#
# Next, include it inside your nonfinal concept:
#   class C_NonFinal < Concept
#     include ExpressionHelper
#
#     def self.name()
#     ...
#   end
#
# Key to understanding how the ExpressionHelper functions is the idea of *forms*.
# A *form* is an equality whose left hand side is a question and whose right hand
# side is the answer.  Both sides of the equality can utilize variables, which will
# be substituted from random selections made in the #generate method. For example, for
# an equivalent expressions concept you might have the form:
#   (:c1.l*:x1.l + :c2.l*:x1.l).is((:c1.l+:c2.l)*:x1.l)
# where c1, and c2 are random coefficients and x1 is a random letter from a list of
# variables.  All forms are aggregated into an class variable array called @forms.  The
# forms should be ordered by difficulty, so
#   @forms[0]
# is the easiest and the last form is
# the most difficult.
#
# In addition to filling in @forms, you must specify an array of ranges for the generate method
# to choose from.  For the form above, we would need a range for each of c1, c2, and x1:
#   @ranges = {
#     :c1 => (2..5),
#     :c2 => (2..5),
#     :x1 => ['a','b','c','x','y','z']
#   }
# For all ranges, the variable to be replaced is the key (as a string or a symbol) and the value is
# either a range or an array from which to make our random selection.
#
# If you want to ensure the selection for multiple variables is mutually exclusive, you can specify this
# via the @uniques array.  For example, if you want to make sure c1 and c2 are not the same value:
#   @uniques = [[:c1, :c2]]
# Each interior list is mutually exclusive, and multiple lists can be added.
#
# There are a few other details to take care of in your concept's #initialize method:
#   def initialize(form_index=nil, params=nil)
#     # first, call #init_forms to initialize forms and parameters
#     init_forms(form_index, params)
#
#     # next, create your forms, with increasing difficulty
#     @forms << (:c1.l*:x1.l + :c2.l*:x1.l).is((:c1.l+:c2.l)*:x1.l)
#     @forms << (:c1.l*:x1.l + :c2.l*:x1.l + :c3.l*:x1.l).is((:c1.l+:c2.l+:c3.l)*:x1.l)
#     @forms << (:c1.l*:x1.l + :c2.l*:x1.l + :c3.l*:x2.l).is((:c1.l+:c2.l)*:x1.l+:c3.l*:x2.l)
#
#     # define the parameter ranges
#     @ranges = {
#       :c1 => (2..5),
#       :c2 => (2..5),
#       :c3 => (3..7),
#       :x1 => ['a','b','c','x','y','z'],
#       :x2 => ['a','b','c','x','y','z']
#     }
#
#     # specify mutual exclusion
#     @uniques = [[:c1, :c2, :c3],
#                 [:c1, :x2]]
#
#     # when testing, you can enable random selection of forms instead of using difficulty scaling
#     @testing = true
#   end
# If you wish to initialize the class with a specific form and parameters, you can pass in
# a form_index and a hash of parameters.  For example, with the above initialize method:
#   C_Concept.new(0, {:c1 => 3, :c2 => 5, :x1 => 'x'})
# would give us the expression
#   3*x+5*x=(3+5)*x
# This is particularly helpful when using subconcepts within show_how methods.
#
# If you have mutiple choice questions, set the right hand side to the number of the correct answer
# and add your options to the @answers array:
#   @forms << "Select the color.".l.is(1)
#   @answers << ['1) green', '2) apple', '3) phone']
#   @forms << "Select the device.".l.is(3)
#   @answers << ['1) green', '2) apple', '3) phone']
#   @forms << "Select the fruit.".l.is(2)
#   @answers << ['1) green', '2) apple', '3) phone']
# In the showQuestion method, you can access the answers for the chosen form, after substitutions
# have been made, by calling the #options method.
#   l = AnnLat.new
#   options.each do |o|
#     l.add({:multiple => true}, o)
#   end
#
# When implementing solve, validate, show_question, show_how, and show_answer, you can use
# the #expression method to get the correct form with the selected values substituted in.
#   def solve
#     # if your right hand side contains variables
#     expression.rhs.simplfy_full!
#     # if you right hand side evaluates to a number (or multiple choice)
#     expression.rhs.eval
#   end
#
#   def validate(answer)
#     # if your right hand side contains variables
#     answer.parse_latex.latex == solve.latex
#     # if you right hand side evaluates to a number
#     answer == solve.to_s
#     # if you are using multiple choice
#     answer == "#{solve})"
#   end
#
#   def showQuestion
#     l = AnnLat.new
#     l.add expression.lhs
#     l.addHint "Hint goes here"
#     l
#   end
# Of course, you are free to pack as much info into the left hand side as you need using
# nested .is operations:
#   @forms << ("What is the mean of the following dataset?".l.is([[:n1, :n2:, :n3, :n4, :n5]].l)).
#     is((:n2.l + :n2.l + :n3.l + :n4.l + :n5.l)/5.l)
# And unpack it via .rhs and .lhs operations
#   def showQuestion
#     l = AnnLat.new
#     # prose portion
#     l.add expression.lhs.lhs
#     # dataset (will be displayed as latex array)
#     l.add expression.lhs.rhs
#     l.addHint "Hint goes here"
#   end
#
# For the final concept, the generate method can be deleted if there are no subconcepts.
# If there are subconcepts, the difficulty factor can be used to alter the variable ranges
#   def generate(opts)
#     if opts["C_SubConcept"] > 0.5
#       # double ranges
#       @ranges.each_key do |k|
#         @ranges[k] = @ranges[k].collect do |value|
#           [value, value*2]
#         end.flatten
#     end
#     # call generate in ExpressionHelper
#     super(opts)
#   end
#
#
#
#
#
#
# Author:: Larry Reaves
# License:: MIT

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

      # duplicate ranges so we don't modify it directly
      unselected = @ranges.dup
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
      if @testing
        @form_index = rand(@forms.size)
      else
        @form_index = 0
        @form_index += 1 while (@form_index+1)/@forms.size.to_f < diff + 0.2
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

  def names
    @@names ||= ["Sam", "Betty", "George", "Edward", "Ralph", "Vanessa", "Lydia", "Sally"]
  end

  def fruit
    @@fruit ||= ["apples", "bananas", "strawberries", "grapes", "oranges", "peaches"]
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
