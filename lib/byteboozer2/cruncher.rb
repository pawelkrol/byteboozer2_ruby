# frozen_string_literal: true

require 'active_model'
require 'ostruct'

module ByteBoozer2
  # This class implements ByteBoozer's 2.0 crunching algorithm.
  class Cruncher
    include ActiveModel::Validations

    attr_reader :address, :result

    validates_numericality_of :address, only_integer: true,
                                        allow_nil: true,
                                        greater_than_or_equal_to: 0x0000,
                                        less_than_or_equal_to: 0xffff

    def self.crunch(*args)
      new(*args).crunch
    end

    def initialize(data, options = {})
      @data       = data
      @executable = options[:executable] || false
      @relocated  = options[:relocated]  || false
      @address    = options[:address]    || 0x0000

      raise ArgumentError unless valid?
    end

    def crunch!
      @ibuf_size = @data.length - 2

      # Load ibuf and clear context
      @ibuf     = @data[2..-1]
      @context  = Array.new(@ibuf_size) { new_node }
      @link     = Array.new(@ibuf_size) { 0 }
      @rle_info = Array.new(@ibuf_size) { OpenStruct.new(value: 0, value_after: 0, length: 0) }

      setup_help_structures
      find_matches
      @obuf = Array.new(MEM_SIZE) { 0 }
      margin = write_output

      pack_len = @put
      file_len = @put
      decr_len = 0
      if @executable
        decr_len = DECRUNCHER_LENGTH
        file_len += decr_len + 2
      else
        file_len += 4
      end

      @result = Array.new(file_len) { 0 }

      if @executable
        start_address  = 0x10000 - pack_len
        transf_address = file_len + 0x6ff

        decr_code[0x1f] = transf_address & 0xff # Transfer from...
        decr_code[0x20] = transf_address >> 8
        decr_code[0xbc] = start_address & 0xff # Depack from...
        decr_code[0xbd] = start_address >> 8
        decr_code[0x85] = @data[0] # Depack to...
        decr_code[0x86] = @data[1]
        decr_code[0xca] = @address & 0xff # Jump to...
        decr_code[0xcb] = @address >> 8

        @result[0] = 0x01
        @result[1] = 0x08

        @result[2, decr_len] = decr_code

        @result[2 + decr_len, @put] = @obuf[0, @put]
      else # Not executable...
        # Experimantal decision of start address
        # start_address = 0xfffa - pack_len - 2
        start_address = (@data[1] << 8) | @data[0]
        start_address += (@ibuf_size - pack_len - 2 + margin)

        start_address = @address - pack_len - 2 if @relocated

        @result[0] = start_address & 0xff # Load address
        @result[1] = start_address >> 8
        @result[2] = @data[0] # Depack to address
        @result[3] = @data[1]

        @result[4, @put] = @obuf[0, @put]
      end

      true
    end

    def crunch
      @result if crunch!
    end

    private

    DECRUNCHER = [
      0x0b, 0x08, 0x00, 0x00, 0x9e, 0x32, 0x30, 0x36, 0x31, 0x00, 0x00, 0x00, 0x78, 0xa9, 0x34, 0x85,
      0x01, 0xa2, 0xb7, 0xbd, 0x1e, 0x08, 0x95, 0x0f, 0xca, 0xd0, 0xf8, 0x4c, 0x10, 0x00, 0xbd, 0xd6,
      0x07, 0x9d, 0x00, 0xff, 0xe8, 0xd0, 0xf7, 0xc6, 0x12, 0xc6, 0x15, 0xa5, 0x12, 0xc9, 0x07, 0xb0,
      0xed, 0x20, 0xa0, 0x00, 0xb0, 0x17, 0x20, 0x8e, 0x00, 0x85, 0x36, 0xa0, 0x00, 0x20, 0xad, 0x00,
      0x91, 0x77, 0xc8, 0xc0, 0x00, 0xd0, 0xf6, 0x20, 0x83, 0x00, 0xc8, 0xf0, 0xe4, 0x20, 0x8e, 0x00,
      0xaa, 0xe8, 0xf0, 0x71, 0x86, 0x7b, 0xa9, 0x00, 0xe0, 0x03, 0x2a, 0x20, 0x9b, 0x00, 0x20, 0x9b,
      0x00, 0xaa, 0xb5, 0xbf, 0xf0, 0x07, 0x20, 0x9b, 0x00, 0xb0, 0xfb, 0x30, 0x07, 0x49, 0xff, 0xa8,
      0x20, 0xad, 0x00, 0xae, 0xa0, 0xff, 0x65, 0x77, 0x85, 0x74, 0x98, 0x65, 0x78, 0x85, 0x75, 0xa0,
      0x00, 0xb9, 0xad, 0xde, 0x99, 0x00, 0x00, 0xc8, 0xc0, 0x00, 0xd0, 0xf5, 0x20, 0x83, 0x00, 0xd0,
      0xa0, 0x18, 0x98, 0x65, 0x77, 0x85, 0x77, 0x90, 0x02, 0xe6, 0x78, 0x60, 0xa9, 0x01, 0x20, 0xa0,
      0x00, 0x90, 0x05, 0x20, 0x9b, 0x00, 0x10, 0xf6, 0x60, 0x20, 0xa0, 0x00, 0x2a, 0x60, 0x06, 0xbe,
      0xd0, 0x08, 0x48, 0x20, 0xad, 0x00, 0x2a, 0x85, 0xbe, 0x68, 0x60, 0xad, 0xed, 0xfe, 0xe6, 0xae,
      0xd0, 0x02, 0xe6, 0xaf, 0x60, 0xa9, 0x37, 0x85, 0x01, 0x4c, 0x00, 0x00, 0x80, 0xdf, 0xfb, 0x00,
      0x80, 0xef, 0xfd, 0x80, 0xf0
    ].freeze

    DECRUNCHER_LENGTH = DECRUNCHER.length
    MEM_SIZE = 0x10000

    NUM_BITS_SHORT_0 = 3
    NUM_BITS_SHORT_1 = 6
    NUM_BITS_SHORT_2 = 8
    NUM_BITS_SHORT_3 = 10
    NUM_BITS_LONG_0 = 4
    NUM_BITS_LONG_1 = 7
    NUM_BITS_LONG_2 = 10
    NUM_BITS_LONG_3 = 13

    LEN_SHORT_0 = 1 << NUM_BITS_SHORT_0
    LEN_SHORT_1 = 1 << NUM_BITS_SHORT_1
    LEN_SHORT_2 = 1 << NUM_BITS_SHORT_2
    LEN_SHORT_3 = 1 << NUM_BITS_SHORT_3
    LEN_LONG_0 = 1 << NUM_BITS_LONG_0
    LEN_LONG_1 = 1 << NUM_BITS_LONG_1
    LEN_LONG_2 = 1 << NUM_BITS_LONG_2
    LEN_LONG_3 = 1 << NUM_BITS_LONG_3

    MAX_OFFSET = LEN_LONG_3
    MAX_OFFSET_SHORT = LEN_SHORT_3

    def cost_of_length(len)
      if len == 1
        1
      elsif len >= 2 && len <= 3
        3
      elsif len >= 4 && len <= 7
        5
      elsif len >= 8 && len <= 15
        7
      elsif len >= 16 && len <= 31
        9
      elsif len >= 32 && len <= 63
        11
      elsif len >= 64 && len <= 127
        13
      elsif len >= 128 && len <= 255
        14
      else
        ByteBoozer2.logger.warn "cost_of_length got wrong value: #{len}"
        10_000
      end
    end

    def calculate_cost_of_literal(old_cost, lit_len)
      new_cost = old_cost + 8

      # FIXME, what if lit_len > 255?
      #
      # FIXME, cost model for literals does not work
      # Quick wins on short matches are prioritized before a longer
      # literal run, which in the end results in a worse result
      # Most obvious on files hard to crunch
      case lit_len
      when 1 then new_cost += 1
      when 128 then new_cost += 1
      when 2 then new_cost += 2
      when 4 then new_cost += 2
      when 8 then new_cost += 2
      when 16 then new_cost += 2
      when 32 then new_cost += 2
      when 64 then new_cost += 2
      end

      new_cost
    end

    def calculate_cost_of_match(len, offset)
      cost = 1 # Copy-bit
      cost += cost_of_length(len - 1)
      cost += 2 # num offset bits
      cost += cost_of_offset(offset - 1, len - 1)
      cost
    end

    def cost_of_offset(offset, len)
      if len == 1
        return NUM_BITS_SHORT_0 if cond_short_0(offset)
        return NUM_BITS_SHORT_1 if cond_short_1(offset)
        return NUM_BITS_SHORT_2 if cond_short_2(offset)
        return NUM_BITS_SHORT_3 if cond_short_3(offset)
      else
        return NUM_BITS_LONG_0 if cond_long_0(offset)
        return NUM_BITS_LONG_1 if cond_long_1(offset)
        return NUM_BITS_LONG_2 if cond_long_2(offset)
        return NUM_BITS_LONG_3 if cond_long_3(offset)
      end

      ByteBoozer2.logger.warn "cost_of_offset got wrong offset: #{offset}"
      10_000
    end

    def cond_short_0(o)
      o >= 0 && o < LEN_SHORT_0
    end

    def cond_short_1(o)
      o >= LEN_SHORT_0 && o < LEN_SHORT_1
    end

    def cond_short_2(o)
      o >= LEN_SHORT_1 && o < LEN_SHORT_2
    end

    def cond_short_3(o)
      o >= LEN_SHORT_2 && o < LEN_SHORT_3
    end

    def cond_long_0(o)
      o >= 0 && o < LEN_LONG_0
    end

    def cond_long_1(o)
      o >= LEN_LONG_0 && o < LEN_LONG_1
    end

    def cond_long_2(o)
      o >= LEN_LONG_1 && o < LEN_LONG_2
    end

    def cond_long_3(o)
      o >= LEN_LONG_2 && o < LEN_LONG_3
    end

    def decr_code
      @decr_code ||= DECRUNCHER.dup
    end

    def find_matches
      matches = Array.new(256) { OpenStruct.new(length: 0, offset: 0) }

      last_node = new_node

      get = @ibuf_size - 1
      cur = @ibuf[get]

      while get >= 0
        # Clear matches for current position
        matches.each do |match|
          match.length = 0
          match.offset = 0
        end

        cur = (cur << 8) & 0xffff # Table 65536 lookup
        cur |= @ibuf[get - 1] if get.positive?
        scn = @first[cur]
        scn = @link[scn]

        longest_match = 0

        if @rle_info[get].length.zero? # No RLE-match here...
          # Scan until start of file, or max offset
          while get - scn <= MAX_OFFSET && scn.positive? && longest_match < 255
            # OK, we have a match of length 2 or longer, but max 255 or file start
            len = 2
            len += 1 while len < 255 && scn >= len && @ibuf[scn - len] == @ibuf[get - len]

            # Calc offset
            offset = get - scn

            # Store match only if it's the longest so far
            if len > longest_match
              longest_match = len

              # Store the match only if first (= best) of this length
              while len >= 2 && matches[len].length.zero?
                # If len == 2, check against short offset!
                if len > 2 || (len == 2 && offset <= MAX_OFFSET_SHORT)
                  matches[len].length = len
                  matches[len].offset = get - scn
                end

                len -= 1
              end
            end

            scn = @link[scn] # Table 65535 lookup
          end

          @first[cur] = @link[@first[cur]] # Waste first entry
        else # if RLE-match...
          rle_len = @rle_info[get].length
          rle_val_after = @rle_info[get].value_after

          # First match with self-RLE, which is always one byte shorter than the RLE itself
          len = rle_len - 1
          if len > 1
            len = 255 if len > 255
            longest_match = len

            # Store the match
            while len >= 2
              matches[len].length = len
              matches[len].offset = 1

              len -= 1
            end
          end

          # Search for more RLE-matches, scan until start of file, or max offset...
          while get - scn <= MAX_OFFSET && scn.positive? && longest_match < 255

            # Check for longer matches with same value and after...
            # FIXME: That is not what it does, is it?!
            if @rle_info[scn].length > longest_match && rle_len > longest_match
              offset = get - scn
              len = @rle_info[scn].length

              len = rle_len if len > rle_len

              if len > 2 || (len == 2 && offset <= MAX_OFFSET_SHORT)
                matches[len].length = len
                matches[len].offset = offset

                longest_match = len
              end
            end

            # Check for matches beyond the RLE...
            if @rle_info[scn].length >= rle_len && @rle_info[scn].value_after == rle_val_after

              # Here is a match that goes beyond the RLE...
              # Find out correct offset to use value_after, then search further to see if more bytes equal
              len = rle_len
              offset = get - scn + @rle_info[scn].length - rle_len

              if offset <= MAX_OFFSET
                len += 1 while len < 255 && get >= offset + len && @ibuf[get - offset - len] == @ibuf[get - len]

                if len > longest_match
                  longest_match = len

                  # Store the match only if first (= best) of this length
                  while len >= 2 && matches[len].length.zero?
                    # If len == 2, check against short offset!
                    if len > 2 || (len == 2 && offset <= MAX_OFFSET_SHORT)
                      matches[len].length = len
                      matches[len].offset = offset
                    end

                    len -= 1
                  end
                end
              end
            end

            scn = @link[scn] # Table 65535 lookup
          end

          if @rle_info[get].length > 2
            # Expand RLE to next position
            @rle_info[get - 1].length = @rle_info[get].length - 1
            @rle_info[get - 1].value = @rle_info[get].value
            @rle_info[get - 1].value_after = @rle_info[get].value_after
          else
            # End of RLE, advance link
            @first[cur] = @link[@first[cur]] # Waste first entry
          end
        end

        # Now that we have all matches from this position, visit all nodes reached by the matches
        255.downto(1).to_a.each do |i|
          # Find all matches we stored
          len = matches[i].length
          offset = matches[i].offset

          next if len.zero?

          target_i = get - len + 1
          target = @context[target_i]

          # Calculate cost for this jump
          current_cost = last_node.cost
          current_cost += calculate_cost_of_match(len, offset)

          # If this match is first or cheapest way to get here, then update node
          next if target.cost != 0 && target.cost <= current_cost

          target.cost = current_cost
          target.next = get + 1
          target.lit_len = 0
          target.offset = offset
        end

        # Calc the cost for this node if using one more literal
        lit_len = last_node.lit_len + 1
        lit_cost = calculate_cost_of_literal(last_node.cost, lit_len)

        # If literal run is first or cheapest way to get here, then update node
        this = @context[get]
        if this.cost.zero? || this.cost >= lit_cost
          this.cost = lit_cost
          this.next = get + 1
          this.lit_len = lit_len
        end

        last_node.cost = this.cost
        last_node.next = this.next
        last_node.lit_len = this.lit_len

        # Loop to the next position
        get -= 1
      end
    end

    def new_node
      OpenStruct.new(cost: 0, next: 0, lit_len: 0, offset: 0)
    end

    def setup_help_structures
      # Setup RLE-info
      get = @ibuf_size - 1
      while get.positive?

        cur = @ibuf[get]
        if cur == @ibuf[get - 1]

          len = 2
          len += 1 while get >= len && cur == @ibuf[get - len]

          @rle_info[get].length = len
          @rle_info[get].value_after = get >= len ? @ibuf[get - len] : cur # Avoid accessing @ibuf[-1]

          get -= len
        else
          get -= 1
        end
      end

      # Setup linked list
      @first = Array.new(MEM_SIZE) { 0 }
      @last = Array.new(MEM_SIZE) { 0 }

      get = @ibuf_size - 1
      cur = @ibuf[get]

      while get.positive?
        cur = ((cur << 8) | @ibuf[get - 1]) & 0xffff

        if @first[cur].zero?
          @first[cur] = @last[cur] = get
        else
          @link[@last[cur]] = get
          @last[cur] = get
        end

        get -= @rle_info[get].length.zero? ? 1 : @rle_info[get].length - 1 # if RLE-match...
      end
    end

    def wbit(bit)
      if @cur_cnt.zero?
        @obuf[@cur_index] = @cur_byte
        @cur_index = @put
        @cur_cnt = 8
        @cur_byte = 0
        @put += 1
      end

      @cur_byte <<= 1
      @cur_byte |= bit & 1
      @cur_cnt -= 1
    end

    def wbyte(b)
      @obuf[@put] = b
      @put += 1
    end

    def wbytes(get, len)
      (0..len - 1).each do
        wbyte(@ibuf[get])
        get += 1
      end
    end

    def wflush
      while @cur_cnt != 0
        @cur_byte <<= 1
        @cur_cnt -= 1
      end
      @obuf[@cur_index] = @cur_byte
    end

    def wlength(len)
      # return if len.zero? # Should never happen

      bit = 0x80
      bit >>= 1 while (len & bit).zero?

      while bit > 1
        wbit(1)
        bit >>= 1
        wbit((len & bit).zero? ? 0 : 1)
      end

      wbit(0) if len < 0x80
    end

    def woffset(offset, len)
      i = 0
      n = 0

      if len == 1
        if cond_short_0(offset)
          i = 0
          n = NUM_BITS_SHORT_0
        end
        if cond_short_1(offset)
          i = 1
          n = NUM_BITS_SHORT_1
        end
        if cond_short_2(offset)
          i = 2
          n = NUM_BITS_SHORT_2
        end
        if cond_short_3(offset)
          i = 3
          n = NUM_BITS_SHORT_3
        end
      else
        if cond_long_0(offset)
          i = 0
          n = NUM_BITS_LONG_0
        end
        if cond_long_1(offset)
          i = 1
          n = NUM_BITS_LONG_1
        end
        if cond_long_2(offset)
          i = 2
          n = NUM_BITS_LONG_2
        end
        if cond_long_3(offset)
          i = 3
          n = NUM_BITS_LONG_3
        end
      end

      # First write number of bits
      wbit((i & 2).zero? ? 0 : 1)
      wbit((i & 1).zero? ? 0 : 1)

      b = 1 << n
      if n >= 8 # Offset is 2 bytes

        # Then write the bits less than 8
        while b > 0x100
          b >>= 1
          wbit((b & offset).zero? ? 0 : 1)
        end

        # Finally write a whole byte, if necessary
        wbyte(offset & 255 ^ 255) # Inverted (!)
        # offset >>= 8

      else # Offset is 1 byte

        # Then write the bits less than 8
        while b > 1
          b >>= 1
          wbit((b & offset).zero? ? 1 : 0) # Inverted (!)
        end
      end
    end

    def write_output
      @put = 0

      @cur_byte = 0
      @cur_cnt = 8
      @cur_index = @put
      @put += 1

      max_diff = 0

      need_copy_bit = true

      i = 0
      while i < @ibuf_size
        link = @context[i].next
        # cost = @context[i].cost
        lit_len = @context[i].lit_len
        offset = @context[i].offset

        if lit_len.zero?
          # Put match
          len = link - i

          ByteBoozer2.logger.debug format('$%<i>04x: Mat(%<len>i, %<offset>i)', i: i, len: len, offset: offset)

          wbit(1) if need_copy_bit
          wlength(len - 1)
          woffset(offset - 1, len - 1)

          i = link

          need_copy_bit = true
        else
          # Put literal
          need_copy_bit = false

          while lit_len.positive?
            len = lit_len < 255 ? lit_len : 255

            ByteBoozer2.logger.debug format('$%<i>04x: Lit(%<len>i)', i: i, len: len)

            wbit(0)
            wlength(len)
            wbytes(i, len)

            need_copy_bit = true if lit_len == 255

            lit_len -= len
            i += len
          end
        end

        max_diff = i - @put if i - @put > max_diff
      end

      wbit(1)
      wlength(0xff)
      wflush

      max_diff - i + @put
    end
  end
end
