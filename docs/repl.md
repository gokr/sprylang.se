# Spry JavaScript REPL
On this page we have the Spy interpreter compiled, together with 10 extra VM modules (core, debug, extend, math, OO, string, modules, reflect, block and browser) and minified to [about 126kb ugly js](repl/spry.js). You can find this [in github](https://github.com/gokr/spry/tree/master/samples/browser/).

You can enter code and eval below, output is appended below the code area.

<div style="text-align:left;margin:0px 0px"> 

<script type="text/javascript" src="shortcut.js"></script>
<script type="text/javascript" src="spry.js"></script>
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
<p><textarea cols="80" rows="12" id='code'>3 + 4</textarea></p>
<p><button onclick="evalInSpry(document.getElementById('code').value)">Eval (ctrl-enter)</button></p>
<p id='output'></p>
</div>
