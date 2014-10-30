require 'securerandom'

class Image

  attr_accessor :path
  attr_reader :uuid, :options

  def initialize(path, options={dynamic: true})
    @options=options
    @path=path
    @uuid=SecureRandom.uuid
  end

  def my_json
    path
  end

end
