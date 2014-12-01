#this class represents a table, it's just a two-dimensional array, [[a,x,f],[q]]
class Table
  include Enumerable
  attr_accessor :objects, :types

  # def my_json
  #   t=Table.new
  #   t.objects = self.objects.map {|row| row.map {|cell| cell.my_json }}
  #   t.types=self.types
  #   t
  # end

  def initialize
    @objects=[]
    @types=[]
  end

  def each
    @objects.each {|row| yield(row)}
  end

  alias_method :each_row, :each

end