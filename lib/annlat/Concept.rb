class Concept

  def self.name
    nil
  end

  def self.version
    0
  end

  def solve
    nil
  end

  def validate(attempt)
   attempt.to_f == solve.to_f
  end

  def showQuestion
    nil 
  end

  def showAnswer
    nil
  end

  def showHow
    nil
  end

  def self.whichConcepts
    nil
  end

  def variants
    nil
  end
end

