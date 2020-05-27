# frozen_string_literal: true

require 'byteboozer2/cruncher'
require 'byteboozer2/file'
require 'byteboozer2/version'
require 'logger'

# This module provides compression methods available in ByteBoozer 2.0.
module ByteBoozer2
  def crunch(file_name)
    compress(file_name)
  end

  def ecrunch(file_name, address)
    compress(file_name, address: address, executable: true)
  end

  def self.logger
    @logger ||= Logger.new('byteboozer2.log').tap do |log|
      log.level = Logger::WARN
      log.progname = 'ByteBoozer2'
    end
  end

  def self.log_level=(level)
    logger.level = level
  end

  def rcrunch(file_name, address)
    compress(file_name, address: address, relocated: true)
  end

  private

  def compress(file_name, *options)
    file = ByteBoozer2::File.load(file_name)
    result = ByteBoozer2::Cruncher.crunch(file.data, *options)
    ByteBoozer2::File.save(file_name + '.b2', result)
  end
end
