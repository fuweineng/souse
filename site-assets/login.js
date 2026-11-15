(function () {
  var f = document.getElementById('loginForm');
  if (!f) return;
  var err = document.getElementById('loginErr');
  f.addEventListener('submit', async function (e) {
    e.preventDefault();
    err.textContent = '';
    var btn = f.querySelector('button[type=submit]');
    btn.disabled = true;
    try {
      var r = await fetch('https://cz.neng.page/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          username: f.username.value.trim(),
          password: f.password.value
        })
      });
      var d = await r.json().catch(function () { return {}; });
      if (!r.ok) throw new Error(d.message || '账号或密码错误');
      var token = (d.data && d.data.access_token) || d.access_token || '';
      if (!token) throw new Error('登录响应缺少 token');
      var d2 = d.data || {};
      var q = '#token=' + encodeURIComponent(token)
        + '&uid=' + encodeURIComponent(d2.user_id || '')
        + '&role=' + encodeURIComponent(d2.role || 'admin')
        + '&uname=' + encodeURIComponent(d2.username || '');
      location.href = 'https://cz.neng.page/admin' + q;
    } catch (ex) {
      err.textContent = ex.message || '登录失败，请稍后重试';
    } finally {
      btn.disabled = false;
    }
  });
})();
