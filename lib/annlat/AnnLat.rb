# The class AnnLat, short for AnnotatedLatex, allows a concept to create 
# step-by-step solutions with text, latex, hints, more hints, and embedded prerequisite concepts. 
# It also allows for the creation of questions with text, latex, hints, and suggestions.
# The communication between the engine and the concepts is faciliated by AnnLat 
# by the agreement that all communication from a concept back to the engine that is intended
# to be displayed to the user is an AnnLat object.

# An instance object maintains an array of objects to be presented on the screen together
# with an array indicating the type of each object. The engine can then access both arrays 
# and decide how to encode each object, and which ones to present on the screen.
require 'json'
require 'securerandom'


public
def my_json
  self.to_s
end

def get_type(thing)
  if thing.class.ancestors.include? Concept
    :Concept
  elsif thing.class.ancestors.include? Latex
    :Latex
  elsif thing.class.ancestors.include? AnnLat
    :AnnLat
  else
    thing.class.to_s.to_sym
  end
end

def which_types(stuff)
  subtypes = []
  stuff.each do |stuffoid|
    subtypes.insert(-1, get_type(stuffoid))
  end
  subtypes
end

class AnnLat #just the scafolds, the idea is to implement this so it will support the example concepts

  include Enumerable

  attr_accessor :objects, :tags, :options
  def initialize
    @objects = []
    @tags = []
    @options = {}
  end 

  def each_with_symbols
    @objects.each_with_index do |x,i|
      yield(@objects[i][0],@tags[i][0])
    end
  end

  def each
    @objects.each {|x| yield(x)}
  end

  def +(x)
    out=AnnLat.new
    out.objects=self.objects+x.objects
    out.tags=self.tags+x.tags
    out
  end

  def add(*stuff) # adds stuff to the @objects array, in sequential order. 
    arr1=[]
    arr2=[]
    stuff.flatten.each do |object|
      case get_type(object)
      when :Table
        hash = {}
        hash[:objects]=object.objects
        hash[:types]=object.types
        arr1 << hash
        arr2 << :Table
      #when :Image
      #  str = object.path
      #  arr1 << str
      #  arr2 << get_type(object)
      else
        arr1 << object
        arr2 << get_type(object)
      end

    end
    @objects << arr1
    @tags << arr2
    self
  end

  #hint is new AnnLat object that is passed with tag :Hint
  def addHint(*stuff)
    x=AnnLat.new
    x.add(*stuff)
    @objects << [x]
    @tags << [:Hint]
    self
  end

  def my_json
    output={} 
    obs=[]
    tags=[]
    @objects.each_with_index do |array, external_index|
      arr=[]
      tags_arr = []
      array.each_with_index do |object, index|
        tag=@tags[external_index][index]
        unless tag == :Hint
          arr << object.my_json
          tags_arr << tag
        end
      end  
      obs << arr unless arr == []
      tags << tags_arr unless arr == []
    end
    output[:objects]=obs
    output[:tags]=tags
    output[:options]=@options
    output
  end
 
  #returns all the hints — an array of AnnLat objects
  def hints
    output = []
    @objects.each_with_index do |hint, index|
      if @tags[index] == [:Hint]
        output << hint[0]
      end
    end
    output
  end

end

class String 
  def my_json
    self
  end
end

class Latex
  def my_json
    latex
  end
end

class Image
  attr_accessor :path    
  attr_reader :uuid
  attr_reader :options


  def initialize(path, options={:dynamic => true})
    @options=options
    @path=path
    @uuid=SecureRandom.uuid
  end

  def my_json
    path
  end

end

class Hash
  def my_json
    if self[:objects] and self[:types]
      hash={}
      hash[:objects] = self[:objects].map {|row| row.map {|cell| cell.my_json }}
      hash[:types]=self[:types]
      hash
    end
  end
end

#this class represents a table, it's just a two-dimensional array, [[a,x,f],[q]]
class Table
  include Enumerable
  attr_accessor :objects, :types

  def my_json
    t=Table.new
    t.objects = self.objects.map {|row| row.map {|cell| cell.my_json }}
    t.types=self.types
    t
  end

  def initialize
    @objects=[]
    @types=[]
  end

  def each
    @objects.each {|row| yield(row)}
  end

  alias_method :each_row, :each
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

