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
    The Spry VM also supports **pluggable literals** so you can easily add your own new literals in extra Spry [VM modules](#vm-modules),
    there is an example in the module `spryextend.nim` that adds support for multiline string literals.

### Literal int
An **int** is signed and its size is platform dependent and has the same size as a pointer. `_` is allowed inside an integer literal and is ignored, it can make big numbers easier to read like `340_000_000`. Examples are `42`, `-34`, `+12`.

### Literal float
The size of a **float** is platform dependent, the Nim compiler chooses the processor's fastest floating point type. The literal syntax supports exponents using either `e` or `E` and also ignores any embedded `_`. Examples are `3.14`, `4e2`, `-2.734e-3` and `40.00_001e2`.

### Literal string
A **string** is written using double quotes like `"abc"`. Inside the string we replace any `\\` by `\`, any `\'` by `'`, any `\"` by `"` and any `\xHH` (where `HH` is a hexadecimal value) with the corresponding ASCII character. All characters are valid inside the string, including newlines. Examples are `"abc"`, `"hey \"there\""` and `"abc\x0Adef"`.

## Words
If it's not a literal, then it's a word. Words are separated from each other using whitespace or any of the composite characters "`()[]{}`". There is also a special set of characters that can only form words together with other characters **from the same set** (or on their own) - "`,;\^&%|~`". Of these only `,`, `;` and `^` are current core spry words, the other characters are still unused.

Note that a word in Spry can be a single character like `=` or `$` or a combination thereof, it doesn't have to be an alphabetic sequence. Words are normally keys bound to values and they are used both as classic "variables" but also for naming functions and other constructs in Spry. This is borrowed from Rebol.

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

But in Spry there is no such additional rules. The rule is simply **from left to right**. To do anything different you use parentheses!

```python
x = (3 + 4)       # Otherwise Spry assigns only 3 to x
y = (2 + 3 * 4)   # Equals 20
y = (2 + (3 * 4)) # Equals 14
```

## Booleans
There are no literals for booleans (!), but there are two  [singleton instances](#singletons) of the VM's internal boolean node type (BoolVal) that are bound to the words `true` and `false` in the [root](#Root) namespace. That's a mouthful explaining that yes, you can use `true` and `false` pretty much as usual. This design is borrowed from Smalltalk.

```python
x = true
y = false
x and y then: [echo "Both are not true"]
x or y then: [echo "But one is true"]
y not then: [echo "Y is not true"]
y else: [echo "Y is not true"]

```

## Nil and Undef
In the [same manner](#singletons) as booleans we also have the word `nil` bound to the sole instance of the NilVal node type, and `undef` bound to the sole instance of UndefVal.

Spry is experimenting with distinguishing between `nil` meaning **nothing** and `undef` meaning **never assigned any value**. For any word the value `nil` is thus a valid value. When a lookup doesn't find any valye for the key and fails you will get `undef`. If you get `nil` it means the lookup succeeded and the value in question is in fact `nil`. There is a primitive method called `?` that checks if a node is `undef`.

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

## Root
Spry is similar to Smalltalk in the sense that there is a special Map that holds all globals. In Smalltalk that Dictionary is called `Smalltalk`, in Spry we call it `root`.

The root Map is created by the Spry interpreter and populated with words referring to primitive functions and known values like `true`, `false` etc. Lookups are done through the lexical scopes, which Blocks and Curlys create when evaluated, up to root.

If a lookup still fails there is a special Block held in the word `modules` containing all [Modules](#modules) that we want should participate in global lookups, in the order they are in that block. A [Module](#modules) is just a Map with some extra meta information in it.

The interpreter will iterate through the Modules and perform the lookup in each one until finding a hit, or giving up and returning `undef`. This means Modules will shadow each other depending on their position in the `modules` block. But you can always refer to names directly using Module getwords `Foo::x` or simple Map lookups like `Foo at: 'x`.

This design is an experiment in "modelessness" since there are no import statements or other mechanisms to modify how lookups are made in a certain part of your source code. At the same time Modules can be loaded and used even if they do contain naming conflicts.


## Functions and Methods
This inevitably brings us to functions, or Funcs as they are called in Spry. Spry is a heavily functional language, in fact, there are **no builtin keywords or operators** at all in Spry - everything is a function, including such fundamental things as assignment `=`.

Funcs can be written either as "primitives" in [Nim](http://nim-lang.org) or in Spry of course. The Spry VM has a bunch of Funcs included internally, most of which are primitives but also some defined in Spry.

Then there are [VM modules](#vm-modules) that define more Funcs, again both primitives and Spry funcs. VM Modules are linked into the VM when you build the Spry VM, currently statically but they could be made to load dynamically as .so/.dlls too.

Finally Spry also has [Modules](#modules) that are pure Spry.

### Func
Functions are created from Blocks using the `func` function that takes a Block of code, performs a shallow copy of it to create a Func and returns it:

```python
# We create a func from a block and assign it to foo
foo = func [3 + 4]
# Now evaluating foo will give 7
foo
```

A Func **evaluates the block when it's evaluated**. This is in contrast to a Block which evaluates to itself. The return value of a Func is either the result of the last expression or you can return explicitly using the primitive return Func using the same character as in Smalltalk, `^`. Another important aspect of Funcs is that they are not polymorphic, or in other words, you can not overload them for different types of the arguments. However, several of the builtin core Funcs perform a bit of "type testing" internally so that you can indeed call them with different types of arguments and they handle them properly. For true polymorphic behaviors you should use (Polymethods](#Polymethods) in Spry.

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

Methods are just like Funcs but they always take at least one argument, from the left. This mandatory "receiver" is accessible using the primitive func `self`, so no need to use an arg word to pull it in. This means Methods "feel" like OO messages, but they are still not polymorphic based on the receiver, again you should use [Polymethods](#Polymethod) for that.

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

## Scoping
Spry code is organized in nested Blocks. Each Block is a scope, a closure in fact. And each closure has a Map containing its local bindings, which you can reach explicitly using `locals`. The top level's local bindings are in fact `root`.

Words are what you use to refer to things in Spry so if you use a regular eval word like `foo`, that means **lookup the key "foo" first in the locals and then outwards until reaching the global scope. Then evaluate whatever value is returned from the lookup**. In Spry we don't declare anything, not even local variables like you do in Smalltalk, instead we have 5 different variants of words to reach our bindings, here are all 5 described once more:

```python
# Lookup in locals and outwards to root and all Modules listed in modules, undef if not found
foo

# Lookup outside this closure and outwards to root and all Modules listed in modules, undef if not found
..foo

# Lookup in the Map called Bar, undef if not found
Bar::foo

# Lookup in self which is the nearest receiver Map
@foo

# Pull in the next argument to this Block invocation
:foo
```

The first 4 variants can also be used as left side in an assignment with these meanings:

```python
# Bind in locals, regardless of any outer reachable foo's
foo = 5

# Lookup outside this closure and outwards to root and all Modules listed in modules.
# If found assign to that foo, otherwise bind in nearest outer closure.
..foo = 5

# Bind in the Map called Bar
Bar::foo = 5

# Bind in self which is the nearest receiver Map
@foo = 5
```
The most uncommon effect of these rules is that you often need to use `..foo` as left hand side in assignments being done inside control structure blocks. This is because all blocks are closures and we don't declare locals in Spry so Spry has no way of knowing that you want to assign to the outer `foo` and not a local `foo`. This means that the following code has to be rewritten to work as intended:

```python
foo = func [ :a
  x = 10
  a > 10 then: [x = 20] # This needs to say "..x = 20"
  ^x]

echo foo 5  # prints 10
echo foo 12 # still prints 10!
```

The reason is that `x = 20` sets `x` in the local then-block, not in the outer func block. Rewriting with `..x` solves it, but we can perhaps do this instead:

```python
foo = func [ :a
  x = (a > 10 then: [20] else: [10])
  ^x]

echo foo 5  # prints 10
echo foo 12 # prints 20
```

Or even shorter of course:

```python
foo = func [:a > 10 then: [20] else: [10]]

echo foo 5  # prints 10
echo foo 12 # prints 20
```
For the moment this is a "language wart" - in other words - something I would like to fix but not sure exactly how yet. :)

!!! note 
    The rules for the left side in assignments are under evaluation. A variant could be that we distinguish between func/method/curly scopes and other blocks.
    
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

The method `type` returns a literal word representing the type of the receiver node: `'int`, `'float`, `'string`,`'boolean`, `'undefined`, `'novalue`, `'block`, `'paren`, `'curly`, `'map`, `'binding`, `'evalword`, `'evalmoduleword`, `'evalselfword`, `'evalouterword`, `'evalargword`, `'getword`, `'getmoduleword`, `'getselfword`, `'getouterword`, `'getargword`, `'litword`

!!! note
    The Activation node does not yet expose any functionality, but it will eventually be used to open up access to the execution stack etc similar to `thisContext` in Smalltalk. The reason for `root` to not be a reference to the singleton is to avoid a recursive global Map.

### Creating things
Spry is not a class based language. Things are created either using literal syntax (created at parse time), through specific evaluation mechanisms (maps are created through evaluating curlys) or through cloning already existing things:

```
# Literal syntax, created at parse time
x = "abc"
y = 12.0
z = 99

# Composites, created at parse time
# $ prevents evaluation so that we can hold the paren/curly itself
paren = $ (1 + 3)
curly = $ {1 2 3}
# No need for $ since blocks evaluate to themselves
block = [1 2 3]

# Create a map through evaluating a curly
# The curly is created at parse time, but the map
# is created when we evaluate the curly
map = {x = 12}

# Cloning at evaluation time, note need for parens
x = ("abc" clone)
y = ([1 2 3] clone)
z = ({x = 12} clone)
```

Word | Type | Comment
-----|------|--------
`clone` | Method | Performs a copy of strings, does nothing for floats and ints and a performs a shallow copy of blocks, parens, curlys and maps.


### Tags
All nodes of all types in Spry can have a block of tags. Tags are currently limited to being literal words. It's used mainly for Maps and Polymethods which forms the basis of OO in Spry.

Word | Type | Comment
-----|------|--------
`x tag: aWord` | Method | Add a tag on a node x. If aWord is not a literal word, it will be converted to one
`x tag? aWord` | Method | Check if a node x has the given tag. If aWord is not a literal word, it will be converted to one
`x tags` | Method | Returns the Block of tags on node x
`x tags: aBlock` | Method | Set the Block of tags on node x

### Assignments
In Spry we don't have Rebol style "set words", instead we have a word `=` that is bound to a primitive Method that performs assignment. This method uses the left hand side unevaluated, which means it works for most normal cases. For more advanced cases where you want to compute the left hand side you can use `set:` instead. Similarly `?` has a counterpart in `get?`.

Finally there is no unset word, but you can instead assign to `undef` which will remove the binding.

Currently there is a [language wart](#Language-Warts) that usually forces assignments to be written with parentheses. Spry has no statement separators and does not consider line breaks. You can write a Spry program in one single long line. This means Spry has no simple of knowing when the expression ends. Due to this the current rule is that assignment **only consumes a single node from the right**.

```python
# You need a paren here because otherwise
# Spry finds "3" and evaluates it (to 3 obviously)
# and then assigns that to x.
x = (3 + 4)

# This works because readFile is a func and when
# evaluated it will pull in the argument filename 
x = readFile "afile.txt"
```

One idea to improve this without introducing separators or making line breaks meaningful (I don't want to do any of those two) is to make evaluation more "eager". Using "look ahead" Spry could check if the word coming after "3" is in fact a method, and then it would continue evaluating it.


Word | Type | Comment
-----|------|--------
`x = aNode` | Method | Assigns the right hand node to the left hand word x. Left hand side is not evaluated. It can be a literal word or a regular word for local binding. An outer word for binding to an outer closure, or a module word for binding in a Map or Module.
`x ?` | Method | Checks if x is bound to something. Left hand side is not evaluated. It can be any kind of word, including a literal word.
`x set: aNode` | Method | Assigns the right hand node to the left hand literal word. Left hand side is evaluated and should evaluate to a word which is used through the same rules as `=`. 
`x set?` | Method | Checks if x is bound to something. Left hand side is evaluated and should evaluate to a word.

### Arithmetic
Spry has int and float as numeric nodes and will automatically convert from int to float if they are mixed.

Word | Type | Comment
-----|------|--------
`+`, `-`, `*`, `/` | Method | Normal arithmetic methods, ints are converted to floats if needed

### Comparisons
Word | Type | Comment
-----|------|--------
`<`, `>`, `<=`, `>=` | Method | Defined so far for int, float and strings

### Equality
In Spry `=` is used for assignment so we use `==` (and `!=`) for testing equality and `===` for testing identity.

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
The core unit of behavior in Spry is funcs and methods. As described above, both work essentially the same, but methods take the first argument (the "receiver") from the left and make it accessible using `self`, you don't use an arg word to pull it in. You use `^` to do an early return, just like in Smalltalk.

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
Spry has 11 different kinds of Words. The following funcs can create and convert words in different ways.

Word | Type | Comment
-----|------|--------
`reify` | Func | Makes a word from a literal word
`litify` | Func | Makes a literal word from a word
`quote` | Func | Makes a literal word from an unevaluated word
`litword` | Func | Makes a literal word from a string
`word` | Func | Makes a word from a string


### Conditionals
Spry uses Smalltalk style keyword based conditionals but I decided to rename the Smalltalk variants `ifTrue:`, `ifFalse:`, `ifTrue:ifFalse:`, `ifFalse:ifTrue:` to the slightly shorter `then:`, `else:`, `then:else:`, `else:then:`. 

Word | Type | Comment
-----|------|--------
`then:` | Method | If receiver is true then evaluate the given block
`else:` | Method | If receiver is false then evaluate the given block
`then:else:` | Method | If receiver is true then evaluate the first block, otherwise the second
`else:then:` | Method | If receiver is false then evaluate the first block, otherwise the second

Other variants can easily be implemented in Spry too, like for example implementing `ifTrue:`, using `then:`. Pointless of course:

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
Modules in Spry are simply Maps with an additional entry under the key `_meta` with a Map containing the meta information about the Module. Here is an example:

```python
{
  _meta = {
    name = 'Foo
    version = "1.0"
    description = "Testing module closure"
  }

  # Local baz. The Map itself is the lexical parent of the funcs we create below.
  # That means that lookups inside the funcs will continue outwards through the Map. 
  baz = 1
  
  # Here we rely on a baz in this module, or else in the global scope
  bar = func [:x + baz]
  
  # Here we make sure to use the module baz, avoiding the local one inside the func
  bar2 = func [ baz = 99 :x + ..baz]

  # Here we use Foo::baz, which will resolve to 1 if this module is indeed loaded as Foo
  bar3 = func [:x + Foo::baz]
}
```
As we can see the above is just Spry syntax for a [Map](#map) and the Map contains 3 funcs and one "variable" called `baz`. If we put this in `foo.sy` - the filename is not important and can be anything - we can then load this module into Spry using `loadFile: "foo.sy"`. The default behavior is to load and bind the module to the name in `_meta` as a global in `root`. Then we can manipulate it and reach it's members using `Foo::xxx` syntax:

```python
# Load the module as the name it has in the neta information
loadFile: "foo.sy"

# We can now access stuff in Foo, should print 1
echo Foo::baz

# Run the bar func with 1 as argument, should print 2
echo Foo::bar 1

# Set a global value for baz
baz = 10

# This should return 2
echo Foo::bar2 1

# And this should return 2
echo Foo::bar3 1

# If we throw away Foo and load it as Zoo
Foo = undef
loadFile: "foo.sy" as: 'Zoo

# Then all works the same, should print 2
echo Zoo::bar 1

# Create a different Foo, so that bar3 finds something
Foo = {baz = 8}

# Should print 9
echo Zoo::bar3 1
```

Finally, we can also add modules to the special block called `modules` which is used by the lookup machinery in Spry. Lookups go outwards lexically all the way up to `root` and if it fails Spry then looks in each module listed in `modules` until giving up and returning `undef`.
 

## VM Modules
Core Spry comes with a bunch of assorted VM modules. A VM module is a separate Nim package that has a Nim proc that "adds it" to a Spry Interpreter instance. The idea is that when you build a Spry VM you pick which VM modules you want to include and then call them one by one. The standard Spry VM has a section that looks something like this:
```nim
import spryextend, sprymath, spryos, spryio, sprythread,
 spryoo, sprydebug, sprycompress, sprystring, sprymodules,
 spryreflect, spryui

var spry = newInterpreter()

# Add extra modules
spry.addExtend()
spry.addMath()
spry.addOS()
spry.addIO()
spry.addThread()
spry.addOO()
spry.addDebug()
spry.addCompress()
spry.addString()
spry.addModules()
spry.addReflect()
spry.addUI()
```
Here we see that the regular VM imports a bunch of VM modules at the top, and then calls `addXXX` for each one. Let's look closer at the LZ4 compression VM module called `sprycompress.nim`:

```nim
import lz4
import spryvm

# Spry compression
proc addCompress*(spry: Interpreter) =
  # Compression of string
  nimFunc("compress"):
    newValue(compress(StringVal(evalArg(spry)).value, level=1))
  nimFunc("uncompress"):
    newValue(uncompress(StringVal(evalArg(spry)).value))
```

The name `addXXX` is just convention, but it must take an argument spry of type `aInterpreter`. Then in that proc we can do several things, but perhaps most importantly we can add primitives to Spry. We typically do that using the Nim templates `nimFunc` and `nimMeth`. A primitive is given a name and the code has access to the Interpreter via `spry`. Using Nim procs like `evalArg(spry)` we can pull in the next argument (`evalArgInfix(spry)` pulls in the receiver from the left) and at the end the primitive must return a `Node`. `newValue` will create the proper Node from a bunch of Nim types.

The templates `nimFunc` and `nimMeth` will then create a NimFunc (or NimMeth) node and bind it to the name given in the Spry `root` Map.

By looking at the various VM modules you can easily see how to make your own! It's easy.

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



