// Connects xterm.js to a termr app running in R. Messages start with a
// one-letter type: the page sends "i<input>" and "r<cols>,<rows>", R sends
// "o<output>" and "x" when the app exits. See R/terminal-viewer.R.
(function () {
  var light = window.matchMedia && window.matchMedia("(prefers-color-scheme: light)").matches;
  var term = new Terminal({
    fontFamily: "Menlo, Consolas, 'DejaVu Sans Mono', 'Liberation Mono', monospace",
    fontSize: 13,
    scrollback: 0,
    theme: light
      ? { background: "#ffffff", foreground: "#1e1e1e", cursor: "#1e1e1e", selectionBackground: "#add6ff" }
      : { background: "#1e1e1e", foreground: "#d4d4d4", cursor: "#d4d4d4", selectionBackground: "#264f78" }
  });
  var fit = new FitAddon.FitAddon();
  term.loadAddon(fit);
  term.open(document.getElementById("terminal"));
  fit.fit();

  // Relative to the page, so it also works behind RStudio Server's proxy.
  var base = location.href.replace(/[?#].*$/, "").replace(/[^\/]*$/, "");
  var ws = new WebSocket(base.replace(/^http/, "ws") + "ws");
  var finished = false;

  function send(message) {
    if (ws.readyState === WebSocket.OPEN) ws.send(message);
  }
  function sendSize() {
    send("r" + term.cols + "," + term.rows);
  }
  function finish(text) {
    if (finished) return;
    finished = true;
    term.options.disableStdin = true;
    var status = document.getElementById("status");
    status.textContent = text;
    status.className = "shown";
  }

  ws.onopen = function () {
    sendSize();
    term.focus();
  };
  ws.onmessage = function (event) {
    var data = event.data;
    var type = data.charAt(0);
    if (type === "o") term.write(data.slice(1));
    else if (type === "x") finish("The app has exited.");
  };
  ws.onclose = function () {
    finish("Disconnected from R.");
  };

  term.onData(function (data) { send("i" + data); });
  term.onBinary(function (data) { send("i" + data); });
  term.onResize(sendSize);

  var refit = function () { try { fit.fit(); } catch (e) {} };
  if (window.ResizeObserver) new ResizeObserver(refit).observe(document.getElementById("terminal"));
  else window.addEventListener("resize", refit);
})();
