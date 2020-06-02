# Welcome to Spry!

Spry borrows **homoiconicity** from Rebol and Lisp, **free form syntax** from Forth and Rebol, **words of different types** from Rebol, **good data structure literal support** from JavaScript and the **general coding experience and style** from Smalltalk. It also has a few ideas of its own, like an interesting argument passing mechanism and a relatively novel take on OO.

Spry is **dynamically typed** and while trying to recreate the "feeling" of Smalltalk this is an experiment in trying out "interesting" approaches.

The current reference implementation of Spry is in a **few thousand lines** of Nim which gives very easy access to C/C++ and Nim eco systems. It also enables **native threads** and **high performance garbage collection**. This interpreter is modular and can be compiled **statically to around 100kb in size**. It can also be compiled to JavaScript, as this [REPL here on the website](repl.md) shows.

Currently Spry can run as a standalone interpreter called `spry` (just like Python), as an embedded interpreter in a Nim executable (easy to make single binary programs!) or as an interactive interpreter, a REPL, called `ispry`.

There is a fair bit of [example code available](https://github.com/gokr/spry/tree/master/examples) including **cross platform UI examples**. Take a look at [Tasting Spry](taste.md) for a sense of the language.

## Vision of Spry

My vision of Spry is to support **100% live coding** in a Smalltalk style **immersive environment**, but much more integrated with the various eco systems outside of Spry. Think Smalltalk, but distilled to the core and without the island isolation.

I also wish to explore other things with it like **simple game development**, perhaps aimed primarily at kids but also the live image model in a distributed multi user scenario by using a [modern embedded database](http://rocksdb.org), cloud and networking technology. Yeah, not entirely super clear but if you know about [GemStone/S](https://gemtalksystems.com/products/gs64/), try visualize that on a global cloud scale, although simplified in architecture.

[Join for the fun](community.md)!