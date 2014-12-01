#Almost all code here is not used (Except Rational to_ltx and prettify methods for numbers).
class Hash
  # That code was used for tables, however they are not yet fully supported.
  #
  # def my_json
  #   if self[:objects] and self[:types]
  #     hash={}
  #     hash[:objects] = self[:objects].map {|row| row.map {|cell| cell.my_json }}
  #     hash[:types]=self[:types]
  #     hash
  #   end
  # end

end

class Rational

  def to_ltx
    Frac.new(numerator,denominator)
  end

end
class Array

  def to_table
    #  raise "It must be two-dimensional array" unless self.depth==2
    table=Table.new
    self.each_with_index do |row,i|
      table.objects[i]=row
      temp=[]
      row.each do |item|
        temp << get_type(item)
      end
      table.types[i]=temp
    end
    table
  end

  #depth of an array
  def depth
    return 0 if self.class != Array
    result = 1
    self.each do |sub_a|
      if sub_a.class == Array
        dim = sub_a.depth
        result = dim + 1 if dim + 1 > result
      end
    end
    result
  end

end

class Fixnum

  def prettify
    self
  end

end

class Float

  def prettify
    to_i == self ? to_i : self
  end

end

class Rational

  def prettify
    denominator == 1 ? numerator : self
  end

end

