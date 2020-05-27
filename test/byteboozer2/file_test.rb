# frozen_string_literal: true

require 'test_helper'

describe ByteBoozer2::File do
  describe '#data' do
    before :each do
      @data = [0x00, 0x10, 0x60]
      @name = 'test/fixtures/small.prg'
      @file = ByteBoozer2::File.load(@name)
    end

    it 'reads attribute value' do
      expect(@file.data).must_equal @data
    end

    it 'writes attribute value' do
      @data = [0x00, 0x40, 0x4c, 0x00, 0x40]
      @file.data = @data
      expect(@file.data).must_equal @data
    end
  end

  describe '#name' do
    before :each do
      @name = 'test/fixtures/small.prg'
      @file = ByteBoozer2::File.new(@name)
    end

    it 'reads attribute value' do
      expect(@file.name).must_equal @name
    end

    it 'writes attribute value' do
      @name = 'test/fixtures/small.prg.b2'
      @file.name = @name
      expect(@file.name).must_equal @name
    end
  end

  describe '#read' do
    before :each do
      @data = [0x00, 0x10, 0x60]
    end

    describe 'when file exists' do
      before :each do
        @name = 'test/fixtures/small.prg'
        @file = ByteBoozer2::File.new(@name)
      end

      it 'reads data' do
        expect(@file.read).must_equal @data
      end
    end

    describe 'when file does not exist' do
      before :each do
        @name = 'test/fixtures/none.prg'
        @file = ByteBoozer2::File.new(@name)
      end

      it 'raises Errno::ENOENT' do
        expect { @file.read }.must_raise Errno::ENOENT
      end
    end
  end

  describe '#save' do
    before :each do
      @data = [0x00, 0x40, 0x4c, 0x00, 0x40]
      @name = 'test/fixtures/small.prg.b2'
    end

    after :each do
      File.unlink(@name)
    end

    it 'creates new file' do
      ByteBoozer2::File.save(@name, @data)
      expect(File.exist?(@name)).must_equal true
    end

    it 'writes data' do
      ByteBoozer2::File.save(@name, @data)
      expect(ByteBoozer2::File.load(@name).data).must_equal @data
    end
  end

  describe '#write' do
    describe 'when target file does not exist' do
      before :each do
        @data = [0x00, 0x40, 0x4c, 0x00, 0x40]
        @name = 'test/fixtures/small.prg.b2'
        @file = ByteBoozer2::File.new(@name, @data)
      end

      after :each do
        File.unlink(@name)
      end

      it 'creates new file' do
        @file.write
        expect(File.exist?(@name)).must_equal true
      end

      it 'writes data' do
        @file.write
        expect(ByteBoozer2::File.load(@name).data).must_equal @data
      end
    end

    describe 'when target file exists' do
      before :each do
        @name = 'test/fixtures/small.prg'
        @file = ByteBoozer2::File.new(@name)
      end

      it 'does not overwrite existing file' do
        expect { @file.write }.must_raise Errno::EEXIST
      end
    end
  end
end
