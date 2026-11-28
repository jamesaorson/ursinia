// Copy buttons for the code blocks on the GSB data page
// (/bible/versions/gsb/data/, written by scripts/gsb-site.scm). Each
// <pre data-copy="query|command"> gets a button that copies its exact text;
// where the clipboard is unavailable, the text is selected for copying by hand.
// Without this file the blocks read as plain code.
(function () {
  "use strict";
  var ICON =
    '<svg viewBox="0 0 16 16" width="16" height="16" aria-hidden="true" focusable="false">' +
    '<rect x="5" y="4" width="8" height="10" rx="1.5" fill="none" stroke="currentColor" stroke-width="1.5"/>' +
    '<path d="M3 11V3.5C3 2.7 3.7 2 4.5 2H10" fill="none" stroke="currentColor" stroke-width="1.5"/></svg>';
  var status = document.createElement("p");
  status.className = "copy-status";
  status.setAttribute("aria-live", "polite");
  document.body.append(status);

  function say(button, label, text) {
    status.textContent = text;
    button.querySelector(".copy-label").textContent = label;
    clearTimeout(button._t);
    button._t = setTimeout(function () {
      button.querySelector(".copy-label").textContent = "Copy";
      status.textContent = "";
    }, 1500);
  }
  function select(code) {
    var range = document.createRange();
    range.selectNodeContents(code);
    var sel = window.getSelection();
    sel.removeAllRanges();
    sel.addRange(range);
  }

  document.querySelectorAll("pre[data-copy]").forEach(function (pre) {
    var code = pre.querySelector("code") || pre;
    var kind = pre.dataset.copy === "command" ? "command" : "query";
    var wrap = document.createElement("div");
    wrap.className = "copy-block";
    pre.before(wrap);
    wrap.append(pre);
    var b = document.createElement("button");
    b.type = "button";
    b.className = "copy-button";
    b.setAttribute("aria-label", "Copy " + kind);
    b.innerHTML = ICON + '<span class="copy-label" aria-hidden="true">Copy</span>';
    wrap.append(b);
    b.addEventListener("click", function () {
      var text = code.textContent.replace(/\n+$/, "");
      var fallback = function () {
        select(code);
        say(b, "Selected", "Could not copy automatically; the " + kind + " is selected, press Ctrl+C or Command+C to copy it.");
      };
      if (!navigator.clipboard || !navigator.clipboard.writeText) return fallback();
      navigator.clipboard.writeText(text).then(function () {
        say(b, "Copied", "Copied the " + kind + " to the clipboard.");
      }, fallback);
    });
  });
})();
