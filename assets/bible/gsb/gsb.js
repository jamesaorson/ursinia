// Greek Source Bible full-text page (/bible/versions/gsb/text/): page options,
// per-word lookup and color modes. The page is complete without this file; it
// only adds markup to a verse when the reader points at, taps or tabs to it.
// Data comes from /bible/versions/gsb/data/ (written by scripts/gsb-site.scm).
(function () {
  "use strict";
  var DATA = "/bible/versions/gsb/data/";
  var KEY = "gsb-options";
  var body = document.body;
  var cache = {};

  function get(url, parse) {
    if (!cache[url]) {
      cache[url] = fetch(url)
        .then(function (r) {
          if (!r.ok) throw new Error(url + ": HTTP " + r.status);
          return r.text();
        })
        .then(parse);
    }
    return cache[url];
  }
  function rows(text) {
    return text
      .split("\n")
      .slice(1)
      .filter(Boolean)
      .map(function (l) {
        return l.split("\t");
      });
  }
  // Greek table rows: ref n pre word post lemma strong morph flags.
  function table(file) {
    return get(DATA + file + ".tsv", function (t) {
      var m = new Map();
      rows(t).forEach(function (r) {
        if (!m.has(r[0])) m.set(r[0], []);
        m.get(r[0]).push(r);
      });
      return m;
    });
  }
  function strongs() {
    return get(DATA + "strongs.tsv", function (t) {
      var m = new Map();
      rows(t).forEach(function (r) {
        m.set(r[0], r);
      });
      return m;
    });
  }
  function glosses() {
    return get(DATA + "glosses.json", JSON.parse);
  }
  function translation(file) {
    return get(DATA + "translation/" + file + ".json", JSON.parse);
  }
  function el(tag, cls, text) {
    var e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text != null) e.textContent = text;
    return e;
  }

  // ---- Options --------------------------------------------------------------

  var opts = { layer: "both", color: "none" };
  try {
    var saved = JSON.parse(localStorage.getItem(KEY) || "{}");
    if (saved.layer) opts.layer = saved.layer;
    if (saved.color) opts.color = saved.color;
  } catch (e) {
    /* storage blocked: defaults */
  }
  function apply() {
    body.classList.toggle("hide-l", opts.layer === "readable");
    body.classList.toggle("hide-r", opts.layer === "literal");
    ["align", "clause", "pos", "tr"].forEach(function (c) {
      body.classList.toggle("c-" + c, opts.color === c);
    });
    if (opts.color !== "none") observeAll();
  }
  var form = document.getElementById("options");
  if (form) {
    form.hidden = false;
    form.layer.value = opts.layer;
    form.color.value = opts.color;
    form.addEventListener("change", function () {
      opts.layer = form.layer.value;
      opts.color = form.color.value;
      try {
        localStorage.setItem(KEY, JSON.stringify(opts));
      } catch (e) {
        /* not persisted */
      }
      apply();
    });
    // Book and chapter pickers. Choosing a book jumps to it and fills the
    // chapter list from that book's own chapter links.
    form.book.addEventListener("change", function () {
      var id = form.book.value;
      var links = id
        ? document.getElementById(id).querySelectorAll(".chs a")
        : [];
      form.chapter.length = 1;
      links.forEach(function (a) {
        form.chapter.add(new Option(a.textContent, a.hash.slice(1)));
      });
      form.chapter.disabled = !links.length;
      if (id) location.hash = id;
    });
    form.chapter.addEventListener("change", function () {
      if (form.chapter.value) location.hash = form.chapter.value;
    });
  }

  // ---- Wrapping a verse into words and segments -----------------------------

  var POS = {
    N: "pn",
    V: "pv",
    A: "pa",
    T: "pt",
    PREP: "pr",
    CONJ: "pc",
    COND: "pc",
    ADV: "pd",
    PRT: "px",
    INJ: "px",
  };
  function pos(morph) {
    var p = (morph || "").split("-")[0];
    if (POS[p]) return POS[p];
    return p.length === 1 && "PRDCIXQKFS".indexOf(p) >= 0 ? "pp" : "";
  }

  function info(v) {
    var book = v.closest(".book");
    var chapter = v.parentNode.id.slice(book.id.length + 1);
    var key = chapter + "." + v.firstChild.textContent;
    return {
      file: book.dataset.f,
      key: key,
      ref: book.dataset.id + "." + key,
      t: v.classList.contains("t"),
    };
  }

  function english(p, segs, seg, trWords) {
    p.textContent = "";
    segs.forEach(function (s, i) {
      if (i) p.append(" ");
      var e = el("span", "s");
      // [Supplied] words inside a segment keep the muted supplied styling.
      s.text.split(/(\[[^\]]*\])/).forEach(function (part) {
        if (part) e.append(part[0] === "[" ? el("span", "sup", part) : part);
      });
      if (s.ns.length) {
        var first = seg[s.ns[0]];
        if (first) e.classList.add("a" + (first[0] % 8));
        if (
          s.ns.some(function (n) {
            return trWords[n];
          })
        )
          e.classList.add("tr");
      } else {
        e.classList.add("sup");
      }
      if (s.clause >= 0) e.classList.add("k" + (s.clause % 6));
      e.dataset.w = s.ns.join(" ");
      p.append(e);
    });
  }

  function wrap(v) {
    if (v._wrapped) return v._wrapped;
    var i = info(v);
    v._wrapped = Promise.all([
      table(i.file),
      i.t ? translation(i.file) : null,
    ]).then(function (res) {
      var words = res[0].get(i.ref);
      if (!words) return;
      var tv = res[1] && res[1][i.key];
      var seg = {}; // word n -> [segment index, clause, sense]
      if (tv) {
        tv.l.forEach(function (s, si) {
          s[2].forEach(function (n, j) {
            // A word's first segment is its own; later ones continue it
            // ([cont n...]) and share its color and highlight.
            if (!seg[n]) seg[n] = [si, s[0], s[3][j]];
          });
        });
      }
      var trWords = {};
      var g = v.querySelector("p[lang=grc]");
      g.textContent = "";
      words.forEach(function (r, k) {
        if (k) g.append(" ");
        if (r[2]) g.append(r[2]);
        var w = el("span", "w", r[3]);
        var cls = pos(r[7]);
        if (cls) w.classList.add(cls);
        if (r[8].split(",").indexOf("tr") >= 0) {
          w.classList.add("tr");
          trWords[r[1]] = true;
        }
        var s = seg[r[1]];
        if (s) {
          w.classList.add("a" + (s[0] % 8));
          if (s[1] >= 0) w.classList.add("k" + (s[1] % 6));
        }
        w.tabIndex = 0;
        w.dataset.n = r[1];
        w._row = r;
        w._sense = s && s[2];
        g.append(w);
        if (r[4]) g.append(r[4]);
      });
      if (tv) {
        english(
          v.querySelector(".e .l"),
          tv.l.map(function (s) {
            return { text: s[1], ns: s[2], clause: s[0] };
          }),
          seg,
          trWords,
        );
        if (tv.r) {
          english(
            v.querySelector(".e .r"),
            tv.r.map(function (s) {
              return { text: s[0], ns: s[1], clause: -1 };
            }),
            seg,
            trWords,
          );
        }
      }
    });
    v._wrapped.catch(function (err) {
      v._wrapped = null;
      console.warn("gsb:", err);
    });
    return v._wrapped;
  }

  // ---- Highlighting counterparts --------------------------------------------

  // Marks the pointed-at word or segment, every Greek word that shares its
  // literal segment, and the English segments (both layers) those words map to.
  function highlight(v, t) {
    v.querySelectorAll(".hi").forEach(function (e) {
      e.classList.remove("hi");
    });
    if (!t) return;
    t.classList.add("hi");
    var ns = {};
    function words(s) {
      return s.dataset.w ? s.dataset.w.split(" ") : [];
    }
    function add(n) {
      ns[n] = true;
    }
    if (t.classList.contains("w")) add(t.dataset.n);
    else words(t).forEach(add);
    v.querySelectorAll(".l .s").forEach(function (s) {
      if (
        words(s).some(function (n) {
          return ns[n];
        })
      )
        words(s).forEach(add);
    });
    v.querySelectorAll(".w, .s").forEach(function (e) {
      var mine = e.classList.contains("w") ? [e.dataset.n] : words(e);
      if (
        mine.some(function (n) {
          return ns[n];
        })
      )
        e.classList.add("hi");
    });
  }

  // ---- Word popup -----------------------------------------------------------

  var pop = el("span", "pop");
  pop.setAttribute("role", "dialog");
  pop.setAttribute("aria-label", "Word details");
  var popWord = null;
  var pinned = false;

  function hide() {
    pop.remove();
    popWord = null;
    pinned = false;
  }

  function line(parent, cls, text) {
    var e = el("span", cls, text);
    parent.append(e);
    return e;
  }

  function show(w, pin) {
    pinned = pin;
    if (popWord === w) return;
    popWord = w;
    Promise.all([strongs(), glosses()]).then(function (d) {
      if (popWord !== w) return;
      var r = w._row;
      var lemma = (r[5] || "").normalize("NFC");
      var strong = r[6];
      var num = strong ? String(Number(strong.slice(1))) : "";
      var lex = strong && d[0].get(strong);
      var senses = d[1][lemma] || [];
      pop.textContent = "";
      var head = line(pop, "pw");
      head.append(el("b", null, r[3]));
      if (lemma) head.append(" ", el("span", null, "· " + lemma));
      head.lang = "grc";
      var facts = [strong, r[7]].filter(Boolean).join(" · ");
      if (facts) line(pop, null, facts);
      if (lex && lex[3]) line(pop, null, "Gloss: " + lex[3]);
      senses.forEach(function (s) {
        var e = line(pop, null, "");
        e.append(
          el("b", null, s[1][0] || "(not rendered)"),
          " (" + s[0] + (s[0] === w._sense ? ", used here" : "") + ") " + s[2],
        );
      });
      if (senses.length) {
        var c = el("a", null, "Concordance entry");
        c.href = "#lemma-" + lemma;
        line(pop, null, "").append(c);
      }
      var flags = r[8].split(",").filter(Boolean);
      if (flags.indexOf("tr") >= 0)
        line(
          pop,
          null,
          "Restored Textus Receptus reading (not in Nestle 1904).",
        );
      else if (flags.length) line(pop, null, "Flags: " + flags.join(", "));
      if (num) {
        var links = line(pop, null, "");
        var blb = el("a", null, "Blue Letter Bible");
        blb.href =
          "https://www.blueletterbible.org/lexicon/g" + num + "/kjv/tr/0-1/";
        var bh = el("a", null, "Bible Hub");
        bh.href = "https://biblehub.com/greek/" + num + ".htm";
        links.append(blb, " · ", bh);
      }
      body.append(pop);
      place();
    });
  }

  // The popup sits in <body>, fixed to the viewport, so opening it never moves
  // the text. Below the word, or above it when there is no room below.
  function place() {
    if (!popWord || !pop.parentNode) return;
    var r = popWord.getBoundingClientRect();
    var below = r.bottom + 4;
    var top =
      below + pop.offsetHeight > window.innerHeight && r.top > pop.offsetHeight
        ? r.top - pop.offsetHeight - 4
        : below;
    pop.style.top = top + "px";
    pop.style.left =
      Math.max(4, Math.min(r.left, window.innerWidth - pop.offsetWidth - 4)) +
      "px";
  }
  window.addEventListener("scroll", place, { passive: true });
  window.addEventListener("resize", place);

  // ---- Events ---------------------------------------------------------------

  function verseOf(t) {
    var v = t.closest && t.closest("#text .v");
    return v || null;
  }

  document.addEventListener("pointerover", function (e) {
    var v = verseOf(e.target);
    if (!v) return;
    wrap(v);
    highlight(v, e.target.closest(".w, .s"));
    if (
      e.pointerType === "mouse" &&
      e.target.classList.contains("w") &&
      !pinned
    )
      show(e.target, false);
  });

  document.addEventListener("pointerout", function (e) {
    if (!popWord || pinned) return;
    var v = popWord.closest(".v");
    var to = e.relatedTarget;
    if (!to || !(v.contains(to) || pop.contains(to))) hide();
  });

  document.addEventListener("focusin", function (e) {
    var v = verseOf(e.target);
    if (pop.contains(e.target)) return;
    if (!v) {
      hide();
      return;
    }
    if (e.target === quiet) {
      quiet = null;
      highlight(v, e.target);
      return;
    }
    var p = wrap(v);
    if (e.target.classList.contains("w")) {
      highlight(v, e.target);
      show(e.target, true);
    } else if (p) {
      hide();
    }
  });

  document.addEventListener("click", function (e) {
    if (pop.contains(e.target)) return;
    var v = verseOf(e.target);
    if (!v) {
      hide();
      return;
    }
    if (e.target.classList.contains("w")) {
      show(e.target, true);
      return;
    }
    // A tap on a verse not yet split into words: split it, then open the word
    // that was under the finger.
    var x = e.clientX;
    var y = e.clientY;
    var p = wrap(v);
    if (p) {
      p.then(function () {
        var t = document.elementFromPoint(x, y);
        if (t && t.classList.contains("w")) {
          highlight(v, t);
          show(t, true);
        }
      });
    }
  });

  // The popup is at the end of <body>, so Tab is routed by hand: word -> the
  // popup's links -> the next word.
  var quiet = null; // a word to focus without reopening its popup
  function nextWord(w) {
    for (var n = w.nextElementSibling; n; n = n.nextElementSibling)
      if (n.classList.contains("w")) return n;
    return null;
  }
  document.addEventListener("keydown", function (e) {
    if (!popWord) return;
    if (e.key === "Escape") {
      popWord.focus(); // focus first: the focusin it fires sees the same word and is a no-op
      hide();
      return;
    }
    if (e.key !== "Tab" || !pop.parentNode) return;
    var links = pop.querySelectorAll("a");
    var at = document.activeElement;
    if (at === popWord && !e.shiftKey && links.length) {
      e.preventDefault();
      links[0].focus();
    } else if (at === links[0] && e.shiftKey) {
      e.preventDefault();
      popWord.focus();
    } else if (at === links[links.length - 1] && !e.shiftKey) {
      e.preventDefault();
      var w = popWord;
      var next = nextWord(w);
      hide();
      if (!next) quiet = w;
      (next || w).focus();
    }
  });

  // ---- Color modes: split verses as they come into view ---------------------

  var observer = null;
  function observeAll() {
    if (observer || !("IntersectionObserver" in window)) return;
    observer = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (en) {
          if (en.isIntersecting) {
            wrap(en.target);
            observer.unobserve(en.target);
          }
        });
      },
      { rootMargin: "300px" },
    );
    document.querySelectorAll("#text .v").forEach(function (v) {
      observer.observe(v);
    });
  }

  // ---- Links into closed <details> (notes, concordance) ---------------------

  function openTarget() {
    var id = decodeURIComponent(location.hash.slice(1));
    var t = id && document.getElementById(id);
    if (!t) return;
    var opened = false;
    for (
      var d = t.closest("details");
      d;
      d = d.parentElement && d.parentElement.closest("details")
    ) {
      if (!d.open) {
        d.open = true;
        opened = true;
      }
    }
    if (opened) t.scrollIntoView();
  }
  window.addEventListener("hashchange", openTarget);
  openTarget();
  apply();
})();
