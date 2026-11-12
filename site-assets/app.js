/* Souse 官网通用交互：玻璃导航 / 汉堡菜单 / 滚动渐显 / 主题切换 */
(function () {
  'use strict';

  var nav = document.getElementById('nav');
  if (nav) {
    addEventListener('scroll', function () { nav.classList.toggle('on', scrollY > 24); }, {passive: true});
    nav.classList.toggle('on', scrollY > 24);
  }

  var mm = document.getElementById('mm');
  if (mm && nav) {
    var close = function () { nav.classList.remove('open'); mm.setAttribute('aria-expanded', 'false'); };
    mm.addEventListener('click', function () {
      var open = nav.classList.toggle('open');
      mm.setAttribute('aria-expanded', String(open));
    });
    document.querySelectorAll('.nav-links a,.nav-r .btn').forEach(function (a) { a.addEventListener('click', close); });
    document.addEventListener('click', function (e) { if (nav.classList.contains('open') && !nav.contains(e.target)) close(); });
    addEventListener('keydown', function (e) { if (e.key === 'Escape') close(); });
  }

  if ('IntersectionObserver' in window) {
    var io = new IntersectionObserver(function (es) {
      es.forEach(function (e) { if (e.isIntersecting) { e.target.classList.add('on'); io.unobserve(e.target); } });
    }, {threshold: .12, rootMargin: '0px 0px -6% 0px'});
    document.querySelectorAll('.rv').forEach(function (el) { io.observe(el); });
  } else {
    document.querySelectorAll('.rv').forEach(function (el) { el.classList.add('on'); });
  }

  var tt = document.getElementById('tt');
  if (tt) {
    var meta = document.querySelector('meta[name=theme-color]');
    tt.addEventListener('click', function () {
      var cur = document.documentElement.dataset.theme === 'light' ? 'light' : 'dark';
      var next = cur === 'light' ? 'dark' : 'light';
      document.documentElement.dataset.theme = next;
      if (meta) meta.setAttribute('content', next === 'light' ? '#f4f6f7' : '#060809');
      try { localStorage.setItem('souse-theme', next); } catch (e) {}
      tt.setAttribute('aria-pressed', String(next === 'light'));
    });
  }

  document.querySelectorAll('[data-copy]').forEach(function (btn) {
    btn.addEventListener('click', function () {
      var el = document.querySelector(btn.getAttribute('data-copy'));
      if (!el) return;
      var text = el.textContent.trim();
      var old = btn.textContent;
      var done = function () { btn.textContent = 'OK'; setTimeout(function () { btn.textContent = old; }, 1400); };
      var fallback = function () {
        var ta = document.createElement('textarea');
        ta.value = text; document.body.appendChild(ta); ta.select();
        try { document.execCommand('copy'); } catch (e) {}
        ta.remove(); done();
      };
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(done, fallback);
      } else { fallback(); }
    });
  });

  // 产品窗口跟着鼠标轻微转动：桌面端才启用，尊重 reduced-motion
  (function () {
    var shot = document.querySelector('.shot');
    var win = shot && shot.querySelector('.shot-win');
    if (!shot || !win) return;
    if (window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    if (window.matchMedia && matchMedia('(pointer: coarse)').matches) return; // 触屏不做
    var raf = 0, tx = 0, ty = 0;
    function apply() {
      raf = 0;
      win.style.setProperty('--tilt-x', tx.toFixed(2) + 'deg');
      win.style.setProperty('--tilt-y', ty.toFixed(2) + 'deg');
    }
    shot.addEventListener('pointermove', function (e) {
      var r = shot.getBoundingClientRect();
      var dx = (e.clientX - r.left) / r.width - 0.5;
      var dy = (e.clientY - r.top) / r.height - 0.5;
      ty = dx * 10;   // 左右 ±5°
      tx = -dy * 7;   // 上下 ±3.5°
      if (!raf) raf = requestAnimationFrame(apply);
    });
    shot.addEventListener('pointerleave', function () {
      tx = 0; ty = 0;
      if (!raf) raf = requestAnimationFrame(apply);
    });
  })();
})();
