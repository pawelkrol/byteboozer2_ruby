# frozen_string_literal: true

require 'test_helper'

describe ByteBoozer2 do
  include ByteBoozer2

  before :each do
    @source = 'test/fixtures/small.prg'
    @target = format('%s.b2', @source)
    @data = [0x00, 0x00, 0x00, 0x10, 0x3f, 0x60, 0xff, 0x80]
  end

  it 'has a version number' do
    refute_nil ByteBoozer2::VERSION
  end

  describe 'crunch' do
    after :each do
      File.unlink(@target)
    end

    it 'crunches file' do
      crunch(@source)
      @data[0] = 0xfe
      @data[1] = 0x0f
      expect(ByteBoozer2::File.load(@target).data).must_equal @data
    end
  end

  describe 'ecrunch' do
    before :each do
      @address = 0x1000
    end

    describe 'with valid start address' do
      after :each do
        File.unlink(@target)
      end

      it 'crunches file and makes executable with given start address' do
        ecrunch(@source, @address)
        @data = [0x01, 0x08] + ByteBoozer2::Cruncher::DECRUNCHER.dup + @data[4..]
        @data[0x21] = 0xda
        @data[0x22] = 0x07
        @data[0xbe] = 0xfc
        @data[0xbf] = 0xff
        @data[0x87] = 0x00
        @data[0x88] = 0x10
        @data[0xcc] = 0x00
        @data[0xcd] = 0x10
        expect(ByteBoozer2::File.load(@target).data).must_equal @data
      end
    end

    describe 'with invalid start address' do
      it 'raises ArgumentError' do
        expect { ecrunch(@source, 'test') }.must_raise ArgumentError
        expect { ecrunch(@source, -1) }.must_raise ArgumentError
        expect { ecrunch(@source, 0x10000) }.must_raise ArgumentError
      end
    end
  end

  describe 'rcrunch' do
    before :each do
      @address = 0x4000
    end

    after :each do
      File.unlink(@target)
    end

    it 'crunches file and relocates data to given hex address' do
      rcrunch(@source, @address)
      @data[0] = 0xfa
      @data[1] = 0x3f
      expect(ByteBoozer2::File.load(@target).data).must_equal @data
    end
  end
end
