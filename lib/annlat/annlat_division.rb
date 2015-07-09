class AnnLatDivision
  def initialize(numer, denom)
    @n = numer
    @d = denom
  end

  def add_to_annlat(l, use_remainder = false)
    l.add_step "Begin the division algorithm"
    digit_count = @n_i.to_s.split('').size
    steps.each_with_index do |step, i|
      n = i == 0 ? @n_i : steps[i-1][2] * 10
      l.add "Use mental math to find that #{@d_i}, goes into #{n}, #{step[0]} times."
      l.add "First, multiply, #{step[0]} times #{@d_i} is #{step[1]}."
      l.add "Then, subtract, #{n} minus #{step[1]} is #{step[2]}."
      l.add tables[2*i]
      if i < digit_count
        l.add_step "Bring down the next digit and continue"
      elsif use_remainder
        l.add "The remainder is #{step[2]}"
        break
      elsif step[2] == 0
        l.add "Since the remainder is 0, we end the division."
        l.add "The division result is #{@answer}"
        break
      else
        l.add_step "Add a 0"
        new_n = "#{@n_i}."
        new_n += "0"*(i+1)
        l.add "Remember that #{@n_i} can be written #{new_n} and bring down the 0."
      end
      l.add tables[2*i + 1]
    end
    l
  end

  private
  def steps
    @steps ||= calculate_steps
  end

  def calculate_steps
    # result digit, subtract, remainder
    steps = []
    convert_to_integer
    n = @n_i
    d = @d_i
    seen = {}
    begin
      digit = (n/d).to_i
      subtract = d*digit
      remainder = (n - subtract)
      steps << [digit, subtract, remainder]
      n = remainder*10
      key = steps[-1].join(',')
      break if seen[key]
      seen[key] = true
    end until remainder == 0
    steps
  end

  def tables
    @tables ||= generate_tables
  end

  def generate_tables
    tables = []
    digits = @n_i.to_s.split('')
    digit_count = digits.size
    answer_spaces = @d_i.to_s.split('').size - 1
    answer_digits = ['']*answer_spaces
    answer_digits += [steps[0][0]]
    decimal_index = nil
    steps.each_with_index do |step, i|
      [false, true].each do |carry|
        if carry
          if decimal_index.nil? and step[2] < @d_i
            decimal_index = answer_digits.size
            answer_digits << '.'
            digits << '.'
            digits << '0'
          end
        else
          answer_digits << step[0] unless i == 0
        end
        enclose_table = [digits].l
        enclose_table.align = "r"
        enclose_table.set_lines :none
        enclose_table = Atom.new("\\kern -6pt\\rlap{\\enclose{longdiv}{#{enclose_table.latex}}}")
        raw_table = [
          [''] + answer_digits,
          [@d_i, enclose_table]
        ]
        remainder_digits = digits.dup
        (0..i).each do |j|
          s = j
          s -= 1 unless j == 0
          skips = ['']*s
          subtraction_digits = steps[j][1].to_s.split('')
          subtraction = skips + ['-'] + subtraction_digits
          if decimal_index and j + 1 > decimal_index
            subtraction = subtraction[0..digit_count] + ['.'] + subtraction[digit_count + 1..-1]
          end
          raw_table << subtraction
          remainder_count = remainder_digits.size
          remainder_digits = steps[j][2].to_s.split('')
          spaces = remainder_count - remainder_digits.size
          remainder_digits = [' ']*spaces + remainder_digits
          if not(decimal_index.nil?)
            remainder_digits = remainder_digits[0..decimal_index - 1] + ['.'] + remainder_digits[decimal_index..-1]
          end
          if carry or j < i
            remainder_digits += [digits[j+1]]
          end
          remainder_digits[0] = "\\hline #{remainder_digits[0]}"
          remainder_table = [remainder_digits].l
          remainder_table.align = "r"
          remainder_table.set_lines :none
          raw_table << skips + ['', Atom.new("\\kern 2pt\\rlap{#{remainder_table.latex}}")]
        end
        table = raw_table.l
        table.align = 'l'
        table.set_lines :none
        tables << table
      end
      digits << '0' unless answer_digits.size <= digit_count + 1
    end
    @answer = answer_digits.join
    tables
  end

  def convert_to_integer
    @n_i = @n
    @d_i = @d
    shift = 0
    while @n_i.round(5) != @n_i.round or
          @d_i.round(5) != @d_i.round
      shift += 1
      @n_i *= 10
      @d_i *= 10
    end
    @n_i = @n_i.round
    @d_i = @d_i.round
  end
end
