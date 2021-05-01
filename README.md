# ByteBoozer2

[![Gem Version](https://badge.fury.io/rb/byteboozer2.svg)](https://rubygems.org/gems/byteboozer2)

`ByteBoozer2` package provides a native Ruby port of David Malmborg's [ByteBoozer 2.0](http://csdb.dk/release/?id=145031), a data cruncher for Commodore files written in C.

## Version

Version 0.0.4 (2021-05-01)

## Description

`ByteBoozer 2.0` is very much the same as `ByteBoozer 1.0`, but it generates smaller files and decrunches at about 2x the speed. An additional effort was put into keeping the encoder at about the same speed as before. Obviously it is incompatible with the version 1.0.

Compressed data is by default written into a file named with `.b2` suffix. Target file must not exist. If you want an executable, use `ecrunch`. If you want to decrunch yourself, use `crunch` or `rcrunch`. The decruncher should be called with `X` and `Y` registers loaded with a hi- and lo-byte address of the crunched file in a memory.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'byteboozer2', '~> 0.0.4'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install byteboozer2

## Usage

The following operations are supported: crunching files, crunching files and making an executable with start address `$xxxx`, crunching files and relocating data to hex address `$xxxx`.

    require 'byteboozer2'
    include ByteBoozer2

    # Crunch file:
    crunch(file_name)

    # Crunch file and make executable with start address $xxxx:
    ecrunch(file_name, address)

    # Crunch file and relocate data to hex address $xxxx:
    rcrunch(file_name, address)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment. To install this gem onto your local machine, run `rake install`. To release a new version, update the version number in `version.rb`, and then run `rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/pawelkrol/) at [https://github.com/pawelkrol/byteboozer2_ruby](https://github.com/pawelkrol/byteboozer2_ruby).

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
