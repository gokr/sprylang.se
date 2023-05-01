# Spry JavaScript REPL
On this page we have the Spry interpreter compiled, together with 10 extra VM modules (core, debug, extend, math, OO, string, modules, reflect, block and browser) and minified to [about 157kb ugly js](repl/spry.js). You can find this [in github](https://github.com/gokr/spry/tree/master/samples/browser/).

You can enter code and eval below, output is appended below the code area. Code is evaluated in the same interpreter so assignments are kept between evaluations.

Here are just some examples:

```self
# Spry is homoiconic
code = [3 + 4]
code at: 0 put: 8
do code
```

```self
# Let's add a method to:do: that works as in Smalltalk.
# Methods take the first argument, the "receiver", from the left
# and binds it to "self". Note second assignment is a "reassignment"
# so that we for sure assign the outer n and not a new local n.
# This already exists implemented as a native.
to:do: = method [:to :block
  n = self
  [n <= to] whileTrue: [
    do block n
    n := (n + 1)]]

# Then we can loop in Smalltalk style echoing 1 to 5!
1 to: 5 do: [echo :x]
```

```self
# We can similarly implement select: from Smalltalk.
# This already exists implemented as a native, but anyway.
select: = method [:pred
  result = clone []
  self reset
  [self end?] whileFalse: [
    n = (self next)
    do pred n then: [result add: n]]
  ^result]

# Then use it to produce [3 4]
[1 2 3 4] select: [:x > 2]
```

<div style="text-align:left;margin:0px 0px"> 

<script type="text/javascript" src="repl/shortcut.js"></script>
<script type="text/javascript" src="repl/spry.js"></script>
<script type="text/javascript">
function echoSpry(html) {
  document.getElementById('output').appendChild(document.createTextNode(html))
  document.getElementById('output').appendChild(document.createElement('br'))
}
function evalInSpry(code) {
  echoSpry(spryEval(code))
}
shortcut.add("ctrl+enter", function() {
  evalInSpry(document.getElementById('code').value)
})
</script>
<p>Enter Spry code:</p>
<p><textarea cols="80" rows="12" id='code'>"3 + 4 = ", ((3 + 4) print)</textarea></p>
<p><button onclick="evalInSpry(document.getElementById('code').value)">Eval (ctrl-enter)</button></p>
<p id='output'></p>
</div>
