# Welcome to Spry!

Spry is a programming language primarily inspired by Smalltalk/Rebol/Lisp/JavaScript/Forth and Nim.

Spry borrows **homoiconicity** from Rebol and Lisp, **free form syntax** from Forth and Rebol, **the word of different types** from Rebol, **good data structure literal support** from JavaScript and the **general coding experience and style** from Smalltalk. It also has a few ideas of its own, like an interesting argument passing mechanism and a relatively novel take on OO.

Mandatory bullet list trying to get you interested:

* A **dynamically typed** minimalistic language with a **very flexible free form syntax**
* Is truly **homoiconic** where everything is an AST node
* No builtin keywords, **all computation are functions including assignment**
* Both **prefix and infix** function syntax including support for Smalltalk **keyword syntax**
* Very lightweight **lambdas** called blocks that are **proper closures**
* Uses Smalltalk style **non local return**
* Very easy access to C/C++ and Nim eco systems
* Piggy backs on Nim for things like **native threads** and **high performance garbage collector**
* Core interpreter can be compiled **statically to around 100kb in size**
* Interpreter implementation only around **2300 lines of Nim code**
* Can be compiled via **C, C++ or JavaScript**
* Has a **REPL** both on command line (ispry) and [here on the website](repl)

The reference implementation of Spry is in Nim, however one idea of Spry is to keep the interpreter simple so that it can be ported to other eco systems, like for example Dart, C# or Java. The simple implementation also means Spry is "slow as CPython", but the idea is to easily be able to drop down to Nim for primitive functions in C/C++ speeds where needed. The Spry interpreter is also highly modular and easy to extend further.

## Taste it

```self
# Let's add a method to:do: that works as in Smalltalk.
# Methods take the first argument, the "receiver", from the left
# and binds it to "self".
to:do: = method [:to :block
  n = self
  [n <= to] whileTrue: [
    do block n
    ..n = (n + 1)]]

# Then we can loop in Smalltalk style echoing 1 to 5!
1 to: 5 do: [echo :x]

# We can similarly implement select: from Smalltalk
select: = method [:pred
  result = ([] clone)
  self reset
  [self end?] whileFalse: [
    n = (self next)
    do pred n then: [result add: n]]
  ^result]

# Then use it to produce [3 4]
echo ([1 2 3 4] select: [:x > 2])
```
In fact... both the above methods are now available as primitive-methods in Spry, so not needed to be implemented like above - but it still works.

## Vision of Spry

The future vision of Spry is to support **100% live coding** in a Smalltalk style **immersive environment** with advanced tools, but being much more integrated with the various eco systems outside of Spry. Think Smalltalk, but distilled to the core and without the island isolation.

I also wish to explore the live image model in a distributed multi user scenario by using [modern database](http://sophia.systems/), cloud and networking technology. Yeah, not entirely super clear but if you know about [GemStone/S](https://gemtalksystems.com/products/gs64/), try visualize that on a global cloud scale, although simplified in architecture.

Join for the fun!

