/* Swift Study — language switch, theme, Swift syntax highlighting, TOC scrollspy.
   Zero dependencies. Works from file:// with no network. */
(function () {
  'use strict';

  var root = document.documentElement;

  /* ---------------- language ---------------- */
  function setLang(lang, persist) {
    if (lang !== 'en' && lang !== 'it') return;
    root.dataset.lang = lang;
    root.lang = lang;
    document.querySelectorAll('[data-set-lang]').forEach(function (b) {
      b.setAttribute('aria-pressed', String(b.dataset.setLang === lang));
    });
    if (persist) { try { localStorage.setItem('study-lang', lang); } catch (e) {} }
    // keep the deep link honest, without adding history entries
    try {
      var u = new URL(location.href);
      u.searchParams.set('lang', lang);
      history.replaceState(null, '', u);
    } catch (e) {}
    buildTOCSpy();
  }

  document.querySelectorAll('[data-set-lang]').forEach(function (btn) {
    btn.addEventListener('click', function () { setLang(btn.dataset.setLang, true); });
  });

  // `l` keyboard shortcut toggles language
  document.addEventListener('keydown', function (e) {
    if (e.metaKey || e.ctrlKey || e.altKey) return;
    var t = e.target.tagName;
    if (t === 'INPUT' || t === 'TEXTAREA' || e.target.isContentEditable) return;
    if (e.key === 'l' || e.key === 'L') setLang(root.dataset.lang === 'en' ? 'it' : 'en', true);
  });

  setLang(root.dataset.lang || 'en', false);

  /* ---------------- theme ---------------- */
  var themeBtn = document.getElementById('theme-btn');
  if (themeBtn) {
    themeBtn.addEventListener('click', function () {
      var order = ['auto', 'light', 'dark'];
      var cur = root.dataset.theme || 'auto';
      var isDarkNow = cur === 'dark' ||
        (cur === 'auto' && matchMedia('(prefers-color-scheme: dark)').matches);
      var next = isDarkNow ? 'light' : 'dark';
      root.dataset.theme = next;
      try { localStorage.setItem('study-theme', next); } catch (e) {}
      void order;
    });
  }

  /* ---------------- mobile nav ---------------- */
  var menuBtn = document.getElementById('menu-btn');
  if (menuBtn) {
    menuBtn.addEventListener('click', function () {
      var open = document.body.classList.toggle('nav-open');
      menuBtn.setAttribute('aria-expanded', String(open));
    });
    document.querySelectorAll('.sidebar-nav a').forEach(function (a) {
      a.addEventListener('click', function () {
        document.body.classList.remove('nav-open');
        menuBtn.setAttribute('aria-expanded', 'false');
      });
    });
  }

  /* ---------------- Swift syntax highlighting ---------------- */
  var KEYWORDS = ('actor|any|as|associatedtype|async|await|borrowing|break|case|catch|class|consume|consuming|' +
    'continue|convenience|default|defer|deinit|distributed|do|dynamic|else|enum|extension|fallthrough|false|' +
    'fileprivate|final|for|func|get|guard|if|import|in|indirect|infix|init|inout|internal|is|isolated|lazy|let|' +
    'mutating|nil|nonisolated|nonmutating|open|operator|optional|override|package|postfix|precedencegroup|' +
    'prefix|private|protocol|public|repeat|required|rethrows|return|sending|self|Self|set|some|static|struct|' +
    'subscript|super|switch|throw|throws|true|try|typealias|unowned|var|weak|where|while|willSet|didSet').split('|');

  var RE = new RegExp([
    '("""[\\s\\S]*?"""|"(?:\\\\.|[^"\\\\\\n])*")',            // 1 string
    '(//[^\\n]*|/\\*[\\s\\S]*?\\*/)',                           // 2 comment
    '(@[A-Za-z_][A-Za-z0-9_]*|#[A-Za-z_][A-Za-z0-9_]*)',        // 3 attribute / macro
    '\\b(' + KEYWORDS.join('|') + ')\\b',                       // 4 keyword
    '\\b([A-Z][A-Za-z0-9_]*)\\b',                               // 5 type
    '\\b(0x[0-9A-Fa-f_]+|\\d[\\d_]*(?:\\.[\\d_]+)?)\\b'         // 6 number
  ].join('|'), 'g');

  function esc(s) {
    return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }

  function highlightSwift(code) {
    var out = '', last = 0, m;
    RE.lastIndex = 0;
    while ((m = RE.exec(code)) !== null) {
      out += esc(code.slice(last, m.index));
      var cls = m[1] ? 'tok-str' : m[2] ? 'tok-com' : m[3] ? 'tok-attr'
              : m[4] ? 'tok-kw' : m[5] ? 'tok-type' : 'tok-num';
      out += '<span class="' + cls + '">' + esc(m[0]) + '</span>';
      last = m.index + m[0].length;
    }
    return out + esc(code.slice(last));
  }

  document.querySelectorAll('.doc pre > code').forEach(function (code) {
    var lang = ((code.className || '').match(/language-([\w-]+)/) || [, ''])[1];
    // Fences without an info string are Swift in these documents.
    // Anything explicitly tagged otherwise (bash, json, c) is left plain.
    if (!lang || lang === 'swift') {
      code.innerHTML = highlightSwift(code.textContent);
    }
  });

  /* ---------------- copy buttons ---------------- */
  document.querySelectorAll('.doc pre').forEach(function (pre) {
    var btn = document.createElement('button');
    btn.className = 'copy-btn';
    btn.type = 'button';
    btn.textContent = 'Copy';
    btn.addEventListener('click', function () {
      var text = pre.querySelector('code') ? pre.querySelector('code').textContent : pre.textContent;
      var done = function () { btn.textContent = 'Copied'; setTimeout(function () { btn.textContent = 'Copy'; }, 1400); };
      if (navigator.clipboard) { navigator.clipboard.writeText(text).then(done, function () {}); }
      else {
        var ta = document.createElement('textarea');
        ta.value = text; document.body.appendChild(ta); ta.select();
        try { document.execCommand('copy'); done(); } catch (e) {}
        document.body.removeChild(ta);
      }
    });
    pre.appendChild(btn);
  });

  /* ---------------- wrap wide tables so the page never scrolls sideways ------- */
  document.querySelectorAll('.doc table').forEach(function (t) {
    if (t.parentElement.classList.contains('table-wrap')) return;
    var w = document.createElement('div');
    w.className = 'table-wrap';
    t.parentNode.insertBefore(w, t);
    w.appendChild(t);
  });

  /* ---------------- TOC scrollspy ---------------- */
  var spy = null;

  function buildTOCSpy() {
    if (spy) { spy.disconnect(); spy = null; }
    var pane = document.querySelector('.shell > .lang[data-l="' + root.dataset.lang + '"]');
    if (!pane) return;
    var links = {};
    pane.querySelectorAll('.toc a[href^="#"]').forEach(function (a) {
      links[decodeURIComponent(a.getAttribute('href').slice(1))] = a;
    });
    var heads = Array.prototype.filter.call(
      pane.querySelectorAll('.doc h2[id], .doc h3[id]'),
      function (h) { return links[h.id]; }
    );
    if (!heads.length) return;

    var visible = new Set();
    spy = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (e.isIntersecting) visible.add(e.target.id); else visible.delete(e.target.id);
      });
      var active = heads.filter(function (h) { return visible.has(h.id); })[0];
      if (!active) return;
      Object.keys(links).forEach(function (id) { links[id].classList.toggle('active', id === active.id); });
    }, { rootMargin: '-70px 0px -72% 0px', threshold: 0 });

    heads.forEach(function (h) { spy.observe(h); });
  }

  buildTOCSpy();
})();
