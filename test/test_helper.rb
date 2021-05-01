# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'byteboozer2'

require 'awesome_print'
require 'minitest/autorun'
require 'minitest/spec'

def test_data(fixture_name)
  file_path = "test/fixtures/#{fixture_name}.prg"
  [file_path, format('%s.b2', file_path)].map { |file_name| file_read(file_name) }
end

def file_read(file_name)
  IO.binread(file_name).unpack('C*')
end
