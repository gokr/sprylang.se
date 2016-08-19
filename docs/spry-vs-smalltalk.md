# Spry vs Smalltalk
Spry is a functional language with OO mechanisms and syntax that makes it feel very close to Smalltalk.

Let's translate a few snippets of Smalltalk code to Spry.

Smalltalk:

```Smalltalk
| a b |
a := 5.
b := a + 1.
^b
```

Spry:
```bash
a = 5
b = (a + 1)
^b
```

* In Spry we don't declare locals, in fact, there are no declarations of variables anywhere.
* Assignment uses `=` and there are no statement separators. The lack of statement separators also mean that we need to use parentheses sometimes to make sure the right hand side of the assignment is a single expression.
* Return behaves and looks the same using `^`.




Smalltalk | Spry | Comment
------------ | ------------- | ------------
`"a comment"` | `# a comment` |
`'abc'` | `"abc"` |
`$x` | | Spry does not have Characters yet.
`#foo` | `'foo` | Symbols are called Literal Words
`#(1 2 3)` | `[1 2 3]`  |
`x := 3 + 4.` | `x = (3 + 4)` | In Spry parentheses are needed since there are no statement separators.
`[:x | x + 1]` | `[:x + 1]` | In Spry `:x` is an operation, not a declaration.
`OrderedCollection with: 1 with: 2` | `[1 2]` | Spry blocks are used for all sequences.
`MyClass new` | `object [MyClass] {}` | 
`{1 + 2. 2 + 3}` | `reduce [(1 + 2) (2 + 3)]` |
