# Welcome to Spry!

Spry is a programming language primarily inspired by Smalltalk/Rebol/Lisp/JavaScript/Forth and Nim.

Spry borrows **homoiconicity** from Rebol and Lisp, **free form syntax** from Forth and Rebol, **the word of different types** from Rebol, **good data structure literal support** from JavaScript and the **general coding experience and style** from Smalltalk. It also has a few ideas of its own, like an interesting argument passing mechanism and a relatively novel take on OO.

Mandatory bullet list trying to get you interested:

* A **dynamically typed** minimalistic language with a **very flexible free form syntax**
* Is truly **homoiconic** where everything is an AST node
* No builtin keywords at all, **all computation are functions including assignment**
* Macro like mechanisms for code manipulation
* Both **prefix and infix** function syntax including support for Smalltalk **keyword syntax**
* Very lightweight **lambdas** (we call them blocks) that are **proper closures**
* Uses Smalltalk style **non local return**
* Very easy access to C/C++ and Nim eco systems
* Piggy backs on Nim for things like **native threads** and **high performance garbage collector**
* Core interpreter can be compiled **statically to around 100kb in size**
* Implementation only around **1600 lines of Nim code**
* Can be compiled via **C, C++ or JavaScript**
* Has a **REPL** both on command line (ispry) and [here on the website](repl)

The reference implementation of Spry is in Nim, however one idea of Spry is to keep the interpreter simple so that it can be ported to other eco systems, like for example C# or Java. The simple implementation also means Spry is "slow as CPython", but the idea is to easily be able to drop down to Nim for primitive functions in C/C++ speeds where needed. The Spry interpreter is also highly modular and easy to extend further.

## Taste it

```self
# Let's add an infix function to:do: that works as in Smalltalk
# An infix function takes the first argument from the left
to:do: = funci [:n :m :blk
  x = n
  [x <= m] whileTrue: [
    do blk x
    x = (x + 1)]]

# Then we can loop in Smalltalk style echoing 1 to 5
1 to: 5 do: [echo :x]

# We can similarly implement select: from Smalltalk as an infix Spry function
select: = funci [:blk :pred
  result = ([] clone)
  blk reset
  [blk end?] whileFalse: [
    n = (blk next)
    if do pred n [result add: n]]
  return result]

# Then use it to produce [3 4]
[1 2 3 4] select: [:x > 2]
```

## Vision of Spry

The future vision of Spry is to support **100% live coding** in a Smalltalk style **immersive environment** with advanced tools, but being much more integrated with the various eco systems outside of Spry. Think Smalltalk, but distilled to the core and without the island isolation.

I also wish to explore the live image model in a distributed multi user scenario by using [modern database](http://sphia.org), cloud and networking technology. Yeah, not entirely super clear but if you know about [GemStone/S](https://gemtalksystems.com/products/gs64/), try visualize that on a global cloud scale, although simplified in architecture.

Join for the fun!



