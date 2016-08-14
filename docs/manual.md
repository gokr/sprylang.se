# Language Manual

**IN PROGRESS!!!!**

Spry code consists solely of **comments, literals, words and composites** separated by whitespace.

In Spry **everything is an AST node**, hereafter referred to as a **node**. The parsing step produces an AST (Abstract Syntax Tree) of such nodes from a string of code. This AST fully mirrors the Spry syntax. The nodes can then be evaluated. This means the Spry VM executes the AST directly without compiling it further to bytecodes or native code.

## Comments
In Spry a comment begins with a `#` parsed outside literals and consumes the rest of the line. This is the only syntax for comments.

```python
# Comments can be on their
# own lines but each line must start with a #
echo "Hey" # But they can also begin after code
echo "Comments begin with # but they can not start inside literals"
```

## Literals
Spry has three standard literals; **int**, **float** and **string**. A literal is a specific syntax that the parser can identify and solely from that - create the proper type of node. Te nodes created are "boxed" Nim values of the corresponding Nim types `int`, `float` and `string`.

It is worth noting that the literal nodes are created during parsing and not during evaluation.

!!! note
    The Spry VM also supports **pluggable literals** so you can easily add your own new literals in extra Spry VM modules,
    there is an example in the module `spryextend.nim` that adds support for multiline string literals.

### Literal int
An **int** is signed and its size is platform dependent and has the same size as a pointer. `_` is allowed inside an integer literal and is ignored, it can make big numbers easier to read like `340_000_000`. Examples are `42`, `-34`, `+12`.

### Literal float
The size of a **float** is platform dependent, the Nim compiler chooses the processor's fastest floating point type. The literal syntax supports exponents using either `e` or `E` and also ignores any embedded `_`. Examples are `3.14`, `4e2`, `-2.734e-3` and `40.00_001e2`.

### Literal string
A **string** is written using double quotes like `"abc"`. Inside the string we replace any `\\` by `\`, any `\'` by `'`, any `\"` by `"` and any `\xHH` (where `HH` is a hexadecimal value) with the corresponding ASCII character. All characters are valid inside the string, including newlines. Examples are `"abc"`, `"hey \"there\""` and `"abc\x0Adef"`.

## Words
If it's not a literal, then it's a word. Words are separated from each other using whitespace or any of the composite characters "`()[]{}`". There is also a special set of characters that can only form words together with other characters **from the same set** (or on their own) - "`,;\^&%|~`".

!!! note
    The special characters rule removes some uncomfortable need of whitespace to separate things but you still need whitespace to ensure that words like `=` and `+` are properly parsed for code like `3 + 4` or `x = 14`. Pull requests to fix this in the parser are welcome :)

Words come in different types depending on prefixing characters. The word type dictates the behavior when the word is evaluated:

1. A **Get word** is prefixed with `$`.
2. An **Eval word** has no prefix. This is the most common word.
3. A **Literal word** is prefixed with `'`.

Get and Eval words also come in 5 different variants, totalling 11 different concrete word types.

Finally we also have **Keywords** which is simply a "syntactical sugar" in the Spry parser that enables Smalltalk style keyword calls.

### Get word
When evaluated, a get word simply performs a lookup using the word itself as the key and the result is the node found. Get words are used when you want to refer to something by name and make sure you only perform the lookup. This way you can refer to for example functions without evaluating them.

!!! note
    In many other languages you refer to the function itself using it's name like `foo` and you call the function using a different syntax, for example `foo()`.
    In Spry it's the other way around, we call functions simply by their name like `foo`, but if we want to refer to the function itself without calling it
    we use `$foo`.

There are different variants:

1. Regular get word, for example `$x`. This looks first among local variables (in `locals`), then outwards lexically.
2. Module qualified get word, for example `$Foo::x`. This looks directly in the Module named `Foo` and nowhere else. It's equivalent to `Foo at: 'x`.
3. Self get word, for example `$@x`. This looks directly in `self` and nowhere else. It's equivalent to `$self::x` or `self at: 'x`.
4. Outer get word, for example `$..x`. This is like a regular get word but does not first look in local variables.
5. Arg get word, for example `:$x`. This pulls in the next argument for the lexically closest outer `func`, **without first evaluating it** in the calling scope, and stores it in `locals` as `x`. This makes it possible to write "macro like" functions.

### Eval word
An eval word works like a get word, but it **also evaluates the result of the lookup**. If the result of the lookup is for example a `func` then it is called. Just like get words we have the same 5 different variants, the difference is only the added evaluation.

1. Regular eval word, for example `x`. This looks first in `locals`, then outwards lexically and then evaluates the result.
2. Module eval word, for example `Foo::x`. This looks directly in the Module named `Foo` and nowhere else, and then evaluates the result. It's equivalent to `eval (Foo at: 'x)`.
3. Self eval word, for example `@x`. This looks directly in `self` and nowhere else and then evaluates the result. It's equivalent to `self::x` or `self at: 'x`.
4. Outer eval word, for example `..x`. This is like a regular eval word but does not first look in `locals`.
5. Arg eval word, for example `:x`. This pulls in the next argument to the lexically closest outer `func`, but first evaluates it in the calling scope, and then stores the result in `locals` as `x`.

### Literal word
A literal word is a canonicalized (there is only ever one instance of every unique word) string and is written like `'foo`. This is very much like a Symbol in Smalltalk or Ruby. Obviously all described words above can be created in literal form just by prepending a `'`, like `'$foo`, `':foo` and so on. A literal word **evaluates as itself**.

You use a literal word when you want to compose code or in situations where you would use a Symbol in Ruby/Smalltalk. Literal words can be reified using `reify`.

### Keywords
The message syntax of Smalltalk has proven itself over many years to be very readable and expressive. In Smalltalk a call (message) that takes arguments is written in "keyword style" like `'hello' copyFrom: 1 to: 2` which roughly in other languages would translate to `"hello".copy(1, 2)` or at best `"hello".copy(from=1, to=2)`. The advantage of the Smalltalk style is that it doesn't make you wonder what the arguments actually denote and in which order they should be given.

The name of the method in this example in Smalltalk is `copyFrom:to:` so the colons are part of the identifier. Spry (unlike Rebol) allows for colons in words just like Smalltalk does and the Spry parser will thus automatically perform a rewrite of `"hello" copyFrom: 1 to: 2` into `"hello" copyFrom:to: 1 2` thus turning the call into a regular infix (first argument to the left) Spry function call, see [Functions](#functions).

Both ways of writing are valid, although the latter would be... very ugly.

But before explaining functions and function calls we first need to go through some simpler parts.

## Precedence
All programming languages have more or less complicated rules for evaluation precedence in expressions. Rebol and Smalltalk excel with very simple rules, while some other languages have dreadful intricate rules. Rebol and Smalltalk both have a base rule of evaluating from left to right and Spry has the very same rule.

Then Smalltalk evaluate unary before binary, and binary before keyword messages. This usually removes a lot of parentheses and is quite natural in Smalltalk.
Rebol has something similar where it evaluates operators before functions.

But in Spry there is no such additional rules. The rule is simply **from left to right**. To do anything different you use parentheses.


## Booleans
There are no literals for booleans (!), but there are two singleton instances of the VM's internal boolean node type (BoolVal) that are bound to the words `true` and `false` in the [root](#root) namespace. That's a mouthful explaining that yes, you can use `true` and `false` pretty much as usual. This design is borrowed from Smalltalk.

## Nil and Undef
In the same manner as booleans we also have the word `nil` bound to the sole instance of the NilVal node type, and `undef` bound to the sole instance of UndefVal.

Spry is experimenting with distinguishing between `nil` meaning *"no value"* and `undef` meaning *"never assigned any value"*. When a lookup fails you will get `undef`, but if you get `nil` it means the lookup succeeded and the value in question is in fact `nil`. There is a primitive infix function called `?` that checks if a node is `undef`.

```python
echo x     # prints "undef"
echo (x ?) # prints "false"
x = nil
echo (x ?) # prints "true"
echo x     # prints "nil"
```

## Composites
Literals and words are the "atoms" of Spry but in order to **compose** both data and code (Spry is homoiconic) we need some kind of "structures of many". We have three of these in core Spry - Block, Paren and Curly.

### Block
The Block is the work horse sequential structure in Spry but it is also the unit of code! Compared to Smalltalk one can almost say it does double duty as BlockClosure and OrderedCollection. A Block is formed using `[]`, for example `[1 + 2]`. There is no separator needed.

When parsed this will create a Block and when evaluated **a Block evaluates to itself** - in other words, it does nothing.

But if we have a Block we can do a lot of things with it explicitly - like **evaluating it as code** using the `do` function:

```python
# Evaluates to 3, try it in ispry
do [1 + 2]
```
A Block evaluates in its **own local closure** which means that the activation of the block has its own Map of local bindings. Assignments operate on this Map but it can also be explicitly accessed using the `locals` primitive. But in Spry we can also manipulate the Block as a sequence:

```python
# Evaluates to 7
foo = [1 + 2]
foo at: 0 put: 5
do foo
```
!!! note
    Yes, in Spry we use the same convention as in Nim regarding indexing - first element is at position 0.

### Paren
In most programming languages parentheses are only used to control evaluation order and do not reify as anything concrete during execution. In Rebol and Spry however, `(1 + 2)` reify as a Paren when parsed. A Paren is a Composite internally just like a Block is, but when evaluated **a Paren evaluates itself as code without creating a new closure and the result is the result of the last expression**. It can be used pretty much as parentheses are used traditionally.

### Curly
The third Composite is the Curly which is written like `{a b c}`. It reifies as a Curly when parsed, which also is a Composite internally just like a Block. When a Curly is evaluated **it evaluates itself like a Block does in its own closure, but the result is the locals Map of the closure**. The net effect of that is that we use Curlys to create Maps:

```python
map = {x = 50 y = 100}
```

### Map
As mentioned, the Block is the sequential collection in Spry corresponding to OrderedCollection in Smalltalk. The Map corresponds similarly to Dictionary. All nodes in Spry can be used as keys in a Map. Word nodes come in 11 different types, as earlier described, but when used as keys only the actual word itself is used for hash and equality. This means that when used as keys, `$foo`, `foo` and `:foo` (for example) are all equal since only the actual word "foo" is used for hash and `==`. Literal words on the other hand are always different from each other, for example `'$foo` is different from `'foo`.

## Root and Modules
Spry is similar to Smalltalk in the sense that there is a special Map that holds all globals. In Smalltalk that Dictionary is called `Smalltalk`. In Spry we call it `root`. The root Map is created by the Spry interpreter and populated with words referring to primitive functions and known values like `true`, `false` etc. Lookups are done through the lexical scopes, which Blocks and Curlys create when evaluated, up to root. If a lookup still fails there is a special Block held in the word `modules` containing Modules that participate in global lookups. A Module is a Map with some extra meta information in it.

The interpreter will iterate through them and perform the lookup in each one until giving up and returning `undef`. This means Modules will shadow each other depending on their position in the `modules` block. But you can always refer to names directly using Module getwords `Foo::x` or simple Map lookups like `Foo at: 'x`. This design is an experiment in "modelessness" since there are no import statements or other mechanisms to modify how lookups are made in a certain part of your source code.

At the same time Modules can be loaded and used even if they do contain naming conflicts.

## Functions and Methods
This inevitably brings us to functions, or Funcs as they are called in Spry. Spry is a heavily functional language, in fact, there are **no builtin keywords or operators** at all in Spry - everything is a function, including such fundamental things as assignment `=`.

Funcs can be written either as "primitives" in [Nim](http://nim-lang.org) or in Spry of course. The Spry VM has a bunch of Funcs included internally, most of which are primitives but also some defined in Spry.

Then there are [VMModules](#VMModules) that define more Funcs, again both primitives and Spry funcs. VMModules are linked into the VM when you build the Spry VM, currently statically but they could be made to load dynamically as .so/.dlls too.

Finally Spry also has [Modules](#Modules) that are pure Spry.

### Func
Functions are created from Blocks using the `func` function that takes a Block of code, performs a shallow copy of it to create a Func and returns it:

```python
# We create a func from a block and assign it to foo
foo = func [3 + 4]
# Now evaluating foo will give 7
foo
```

A Func **evaluates the code when it's evaluated**. This is in contrast to a Block which evaluates to itself. The return value of a Func is either the result of the last expression or you can return explicitly using the primitive return Func using the same character as in Smalltalk, `^`.

Funcs use prefix calling and they are called just like in Rebol:

```python
# Call foo with no arguments
foo

# Call foo with one argument, an int
foo 4

# Call foo with two arguments
foo 4 "hey"
```

Arguments to Funcs are "pulled in" using Arg words which are prefixed with `:`. Note that an arg word is an **operation**, not a declaration, so they can appear anywhere in the Func.

```python
# This func takes one argument and adds 4 to it
foo = func [:x + 4]
# Prints 9 on stdout
echo foo 5
```
The Func `echo` is included in the VMModule `spryio` which in turn is included in the standard spry and ispry VMs. For embedded use one can however build a Spry VM that does not include it. `echo` is a prefix Func that takes one argument that it will turn into a string before writing it to stdout using [Nim's echo proc](http://nim-lang.org/docs/system.html#echo,varargs[typed,]).

The arg word `:x` will take the next argument AST node (the `5` literal) to the `foo` Func, evaluate it at the call site (literals evaluate to themselves) and take the resulting node and store it in the local variable `x` in the Func closure, and the result of the arg word will be that node. Since the result is the value it means you can actually use `:x` in an expression just like we do above.

!!! note
    The fact that arg words are operations also means the arity of a Func is not static,
    it could in theory pull in a different number of arguments - although that would
    be very confusing.

You could also write the Func in "Smalltalk style" that looks like declarations:

```python
# This func takes one argument and adds 4 to it
foo = func [:x x + 4]
# Prints 9 on stdout
echo foo 5
```
Currently that will be slightly slower since we first evaluate `:x` and then `x` but it may sometimes make the code easier to read.

Arg words can also be "get arg words" which means that we can pull in the argument AST node **without first evaluating it at the call site**. Here is an example that shows the difference:

```python
foo = func [:$x echo $x]
bar = func [:x echo $x]
x = "abc"
bar x # prints "abc"
foo x # prints "x"
bar (3 + 4) # prints "7"
foo (3 + 4) # prints "(3 + 4)"
```
The reason we use `echo $x` is to prevent `x` from being evaluated inside the func.

### Methods

Methods are just like Funcs but they always take at least one argument, from the left. This mandatory "receiver" is accessible using the primitive func `self`, so no need to use an arg word to pull it in.

```python
# Call method foo on an int
4 foo

# Call method foo on a string, with one more argument
"hey" foo 7

# Call method foo with three arguments
4 foo "hey" "there"
```

Methods are created using `method`:

```python
# Create a method that adds 5 to self
plusfive = method [self + 5]
echo (3 plusfive) # prints "8"
```

Both methods and funcs can use keyword naming and calling style:

```python
# Create a function and assign it to a keyword
add:to: = func [:x + :y]
echo (add: 5 to: 6)   # prints "11"

# And a method in the same way
add:and: = method [self + :x + :y]
echo (3 add: 5 and: 6) # prints "14"

# Can also be called like this
echo (add:to: 5 6)    # prints "11"
echo (3 add:and: 5 6) # prints "14"
```

## Standard Library
The Spry VM includes a very minimal "standard library" in the form of primitive Methods and Funcs, a few Spry only Methods and Funcs and a few singleton nodes. The VM creates the global `root` Map and populates it with words.

The regular Spry VM `spry` and the REPL `ispry` also loads several VM Modules that adds more words to `root`. Finally, the file `spry.sy` is loaded with additional Spry library code that are not primitives.

### Singletons
The following singleton nodes are created and bound to these words by the VM.

Word | Comment
------- | ---------
`false` | Reference to the singleton for falsehood
`true` | Reference to the singleton for truth
`undef` | Reference to the singleton for missing value
`nil` | Reference to the singleton for value meaning no value
`modules` | Reference to a Block of Maps for lookups

### Reflection 
The following Funcs and Methods are available for reflection purposes.

Word | Type | Comment
-----|------|--------
`root` | Func | Returns the Map of global bindings
`activation` | Func | Returns the current Activation
`locals` | Func | Returns the Map of local bindings
`self` | Func | Returns the receiver in a Method, undef in a Func
`node` | Func | Returns the receiver in a Method, unevaluated
`;` | Func | Returns the previous receiver, enables Smalltalk style cascades
`type` | Method | Returns a literal word representing the nodetype, see below.

Type literal | Comment
-----|-------------
`'int`
`'float`
`'string`
`'boolean`
`'undefined`
`'novalue`
`'block`
`'paren`
`'curly`
`'map`
`'binding`
`'evalword`
`'evalmoduleword`
`'evalselfword`
`'evalouterword`
`'evalargword`
`'getword`
`'getmoduleword`
`'getselfword`
`'getouterword`
`'getargword`
`'litword`

!!! note
    The Activation node does not yet expose any functionality, but it will eventually be used to open up access to the execution stack etc similar to `thisContext` in Smalltalk. The reason for `root` to not be a reference to the singleton is to avoid a recursive global Map.

### Tags
All nodes of all types in Spry can have a block of tags. Tags are currently limited to being literal words. It's used mainly for Maps which forms the basis of OO in Spry.

Word | Type | Comment
-----|------|--------
`x tag: aWord` | Method | Add a tag on a node x. If aWord is not a literal word, it will be converted to one
`x tag? aWord` | Method | Check if a node x has the given tag. If aWord is not a literal word, it will be converted to one
`x tags` | Method | Returns the Block of tags on node x
`x tags: aBlock` | Method | Set the Block of tags on node x

### Assignments
In Spry we don't have Rebol style "set words", instead we have a word `=` that is bound to a primitive Method that performs assignment. This method uses the left hand side unevaluated, which means it works for most normal cases. For more advanced cases where you want to compute the left hand side you can use `set:` instead. Similarly `?` has a counterpart in `get?`.

Finally there is no unset word, but you can instead assign to `undef` which will remove the binding.

Word | Type | Comment
-----|------|--------
`x = aNode` | Method | Assigns the right hand node to the left hand word x. Left hand side is not evaluated. It can be any kind of word, including a literal word.
`x ?` | Method | Checks if x is bound to something. Left hand side is not evaluated. It can be any kind of word, including a literal word.
`x set: aNode` | Method | Assigns the right hand node to the left hand literal word. Left hand side is evaluated and should evaluate to a literal word. 
`x set?` | Method | Checks if x is bound to something. Left hand side is evaluated and should evaluate to a word.

### Arithmetic
Spry has int and float as numeric nodes and will automatically convert from int to float if they are mixed.

Word | Type | Comment
-----|------|--------
`+`, `-`, `*`, `/` | Method | Normal arithmetic methods, ints are converted to floats if needed

### Comparions
`<`, `>`, `<=`, `>=` | Method | Defined so far for int, float and strings

### Equality
In Spry `=` is taken for assignment so we use `==` (and `!=`) for testing equality and `===` for testing identity.

Word | Type | Comment
-----|------|--------
`==` | Method | Check equality
`===` | Method | Check identity
`!=` | Method | Checks for inequality
`!===` | Method | Checks for non identity

### Booleans
Word | Type | Comment
-----|------|--------
`not` | Method | Negates a boolean
`and` | Method | If left hand side expression evaluates to true, then right hand side is also evaluated. True if both are true, otherwise false
`or` | Method | If left hand side expression evaluates to false, then right hand side is also evaluated. True if either is true, otherwise false

### Concatenation
Word | Type | Comment
-----|------|--------
`,` | Method | Concatenates strings, blocks, parens and curlys

### Conversions
Word | Type | Comment
-----|------|--------
`print` | Method | Returns the node in the user friendly string format for presentation (like Rebol's "form")
`parse` | Func | Parse a string of Spry into nodes, comments are kept
`serialize` | Method | Returns the node as a string in source form excluding comments
`commented` | Method | Returns the node as a string in source form including comments
`asFloat` | Method | Converts an int to float
`asInt` | Method | Converts a float to int

### Composites
These methods operate mainly on the sequential composites - blocks, parens and curlys. Some also work for strings. And some also work for maps.

Word | Type | Comment
-----|------|--------
`size` | Method | Returns number of elements, works for string, blocks, parens, curlys and maps.
`at:` | Method | Get element at a key, works for blocks, parens, curlys and maps. Returns undef if not found.
`at:put:` | Method | Set element at a key to a value, works for blocks, parens, curlys and maps. Using `undef` as value means removing the binding for Maps.
`get:` | Method | Get element at unevaluated argument. Works for blocks, parens, curlys and maps. Returns undef if not found.
`set:to:` | Method | Set element at unevaluated argument. Works for blocks, parens, curlys and maps. Using `undef` as value means removing the binding for Maps. 
`add:` | Method | Add element to sequential composite. Works for blocks, parens and curlys.
`removeLast` | Method | Remove last element of sequential composite. Works for blocks, parens and curlys.
`copyFrom:to:` | Method | Copy a sub range to form a new composite of the same type. Works for blocks, parens and curlys.
`contains:`  | Method | Test if the composite contains any element equal to the given argument. Works for blocks, parens, curlys and maps.
`first` | Method | Return element at position 0.
`second` | Method | Return element at position 1.
`third` | Method | Return element at position 2.
`fourth` | Method | Return element at position 3.
`fifth` | Method | Return element at position 4.
`last` | Method | Return last element.
`do:` | Method | Iterate over block, paren or curly and evaluate argument block for each element, Smalltalk style.
`sum` | Method | Sums all elements of a block, paren or curly. Can contain a mix of ints and floats. If all are int result will be an int.

For Maps you can also use `::`-syntax to get and together with `=` to set. Using `undef` as value means **removing the binding** for Maps.

### Blocks
Blocks actually double as **positionable streams** too, with an internal position just like in Rebol. This means we can easily step through a Block using its internal position. The following methods form the base of this stream protocol.

Word | Type | Comment
-----|------|--------
`reset` | Method | Set position to 0
`pos` | Method | Get current position, first position is 0
`pos:` | Method | Set current position
`read` | Method | Get the element at the current position without moving forward
`write:` | Method | Set the element at the current position without moving forward
`next` | Method | Get the element at the current position and increase the position
`prev` | Method | Get the element at the current position and decrease the position
`end?` | Method | Return true if position is >= size, which indicates we have reached the end

### Funcs and Methods

Word | Type | Comment
-----|------|--------
`func` | Func | Creates a func which is a prefix function taking all arguments on the right side
`method` | Func | Creates a method which is an infix function taking the first argument, the receiver, on the left side

### Evaluation
The following funcs performs explicit evaluation in various ways.

Word | Type | Comment
-----|------|--------
`do` | Func | Takes one argument, a block. Evaluates the block.
`$` | Func | Takes one argument but does not evaluate it, returns it unevaluated. Can be used to prevent evaluation of nodes.
`eva` | Func | Takes one argument, evaluates it and returns the result.
`eval`| Func | Takes one argument, evaluates it and then also evaluates the result.
`^` | Func | Takes one argument, evaluates it and performs an early return.

### Words
Word | Type | Comment
-----|------|--------
`reify`
`sym`
`litword`
`word`

`clone`

### Conditionals
Spry uses Smalltalk style keyword based conditionals but I decided to rename the Smalltalk variants `ifTrue:`, `ifFalse:`, `ifTrue:ifFalse:`, `ifFalse:ifTrue:` to the slightly shorter `then:`, `else:`, `then:else:`, `else:then:`. 

Word | Type | Comment
-----|------|--------
`then:` | Method | If receiver is true then evaluate the given block
`unless:` | Method | If receiver is false then evaluate the given block
`then:else:` | Method | If receiver is true then evaluate the first block, otherwise the second
`unless:else:` | Method | If receiver is false then evaluate the first block, otherwise the second

Other variants can easily be implemented in Spry too, like for example reimplementing `then:`, using `then:`. Pointless of course:

```
ifTrue: = method [:blk self then: [^do blk] nil]
3 < 4 ifTrue: [echo "Works"] 
```

Or you could of course just make an alias, assigning `ifTrue:` to the same primitive as `then:` is bound to.
```
ifTrue: = $then:
3 < 4 ifTrue: [echo "Works"]
```

### Loops
The following loop words are also designed like in Smalltalk. 

Word | Type | Comment
-----|------|--------
`timesRepeat:` | Method | Smalltalk style loop. The receiver is an int and the argument is a block to evaluate that number of times
`to:do:` | Method | Smalltalk style for-loop, although currently limited to a step by +1
`whileTrue:` | Method | Smalltalk style conditional loop
`whileFalse:` | Method | Smalltalk style conditional loop


### Misc

Word | Type | Comment
-----|------|--------
`quit` | Func | Quits the interpreter. Takes one argument, the numeric exit code to return to the OS


### Polymethod


### Spry library

Word | Type | Comment
-----|------|--------
error
assert
obect
module
sprydo:
detect:
select:



## Modules






## Spry grammar

Here is a very informal extended BNF of Spry (as of now) written using similar conventions that Nim does. I think it's fairly correct - however - the [current parser in Spry](https://github.com/gokr/spry/blob/master/src/spryvm.nim#L1-L734) is a handwritten iterative (not recursive) parser so some parts were hard to express, like rules for comments and whitespace, see the notes in the BNF for details.

In this EBNF `(a)*` means 0 or more a's, `a+` means 1 or more a's, and `(a)?` means an optional a. Parentheses may be used to group elements.
`{}` are used to describe character sets. Stuff I can't figure out is described inside `{{ }}` using plain english.

Note that `true, false, nil, undef` and all control structures are expressed using words, so these 26 lines are actually the complete grammar!

```bnf
# Ints are parsed using Nim parseInt, floats using parseFloat and strings using unescape.
# This means they follow the following grammar.
int = ['+' | '-'] digit (['_'] digit)*
exponent = ('e' | 'E') ['+' | '-'] digit (['_'] digit)*
float = ['+' | '-'] digit (['_'] digit)* (('.' (['_'] digit)* [exponent]) | exponent)

# Inside the string we replace any \\ by \, any \' by ', any \" by " and any
# \xHH (where HH is a hexadecimal value) with the corresponding character
string = '"' {{all sequences of characters except a \" not preceded by a \\}} '"'

# Literals are pluggable in the Parser, but these three are the core ones
literal = int | float | string

# Same definition as in Nim strutils, whitespace separates words in Spry
whitespace = {' ', '\x09', '\x0B', '\x0D', '\x0A', '\x0C'}

# Note that there is a set of special characters that can only form
# names together with other special characters.
name = {{any sequence of characters not parsed as a literal}}

qualifiedname = name '::' name

evalnormalword = (name | qualifiedname)
evalselfword = '@' name
evalouterword = '..' name

evalword = evalouterword | evalselfword | evalnormalword

getnormalword = '$' (name | qualifiedname)
getselfword = '$@' name
getouterword = '$..' name

getword = getouterword | getselfword | getnormalword

argevalword = ':' name
arggetword =  ':$' name

argword = argevalword | arggetword

word = evalword | getword | argword

block = '[' program ']'
paren = '(' program ')'
curly = '{' program '}'

# Comments are detected outside literals and consume the rest of the line
# They do NOT constitute nodes in Spry. Yet.
comment = '#' (any)* '\l'

node = literal | word | block | paren | curly

# A program is just a sequence of nodes separated by optional whitespace.
# Perhaps not exactly correct, two words in sequence *must* be separated by whitespace.
program = ((whitespace)? node (whitespace)?)*
```



