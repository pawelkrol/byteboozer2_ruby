# frozen_string_literal: true

module ByteBoozer2
  # This class implements file handling related helper methods.
  class File
    attr_accessor :data, :name

    def self.load(*args)
      new(*args).tap(&:read)
    end

    def self.save(*args)
      new(*args).tap(&:write)
    end

    def initialize(name, data = nil)
      @name = name
      @data = data
    end

    def read
      @data = IO.binread(@name).unpack('C*')
    end

    def write
      ::File.open(@name, ::File::WRONLY | ::File::CREAT | ::File::EXCL, binmode: true, encoding: 'ASCII-8BIT') do |file|
        file.write @data.pack('C*')
      end
    end
  end
end
