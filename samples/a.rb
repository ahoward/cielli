#! /usr/bin/env ruby

require 'cielli'

cli do
  run do
    p [@argv, @options]
  end
end
