# frozen_string_literal: true

require 'test_helper'

describe ByteBoozer2::Cruncher do
  describe 'when crunching plain executable file' do
    before :each do
      @data, @expected = test_data('test')
    end

    describe 'when called as an object method' do
      before :each do
        @cruncher = ByteBoozer2::Cruncher.new(@data)
      end

      describe '#crunch!' do
        it 'returns true upon success' do
          expect(@cruncher.crunch!).must_equal true
        end

        it 'crunches data' do
          @cruncher.crunch!
          expect(@cruncher.result).must_equal @expected
        end
      end

      describe '#crunch' do
        it 'crunches data' do
          expect(@cruncher.crunch).must_equal @expected
        end

        it 'memoizes result' do
          @cruncher.crunch
          expect(@cruncher.result).must_equal @expected
        end
      end
    end

    describe 'when called as a class method' do
      describe '.crunch' do
        it 'returns crunched data upon success' do
          expect(ByteBoozer2::Cruncher.crunch(@data)).must_equal @expected
        end
      end
    end
  end

  describe 'when crunching custom character set' do
    before :each do
      @data, @expected = test_data('fonts')
      @cruncher = ByteBoozer2::Cruncher.new(@data)
    end

    describe '#crunch' do
      it 'crunches data' do
        expect(@cruncher.crunch).must_equal @expected
      end
    end
  end

  describe 'when crunching SID soundtrack tune' do
    before :each do
      @data, @expected = test_data('music')
      @cruncher = ByteBoozer2::Cruncher.new(@data)
    end

    describe '#crunch' do
      it 'crunches data' do
        expect(@cruncher.crunch).must_equal @expected
      end
    end
  end
end
