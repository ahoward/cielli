NAME
====
cielli

SYNOPSIS
========
a minimalist's toolkit for quickly writing well behaved CLI/cee-el-ahy programs
  
DESCRIPTION
===========

cielli is the command line tool your mother wanted you to use.  i learned this [the hard way](https://github.com/ahoward/main].


SAMPLES
=======

  <========< samples/a.rb >========>

  ~ > cat samples/a.rb

    #! /usr/bin/env ruby
    
    require 'cielli'
    
    cli do
      run do
        p [@argv, @options]
      end
    end

  ~ > ruby samples/a.rb

    [[], {}]



INSTALL
=======
gem install cielli -v 0.4.2
