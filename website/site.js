/* Static documentation only: no workbook uploads, credentials, or tracking. */
(() => {
  'use strict';
  const source = 'https://github.com/Marginal-Z/SMT-CHECK';
  const releases = `${source}/releases`;
  const languages = {zh:'中文', en:'English', th:'ไทย'};
  const query = new URLSearchParams(location.search);
  let saved;
  try { saved = localStorage.getItem('fusion-language'); } catch (_) { /* Private browsing. */ }
  let language = query.get('lang') || saved || 'zh';
  if (!Object.hasOwn(languages, language)) language = 'zh';
  const t = window.FUSION_CONTENT[language];
  const guide = document.body.dataset.page === 'guide';
  const escape = value => String(value).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  const page = (path, hash = '') => `${path}?lang=${language}${hash}`;
  const download = filename => `${releases}/latest/download/${filename}`;
  const link = (url, label, primary = false) => `<a class="button${primary?' primary':''}" href="${url}">${escape(label)}<span aria-hidden="true">↗</span></a>`;
  document.documentElement.lang = t.lang;
  document.title = guide ? `SMT Fusion — ${t.guideTitle}` : t.title;
  document.getElementById('site-header').className = 'site-header';
  document.getElementById('site-header').innerHTML = `<div class="container header-inner"><a class="brand" href="${page('index.html')}" aria-label="SMT Fusion"><img src="assets/app-icon.png" alt="" width="42" height="42">SMT Fusion</a><nav aria-label="${escape(t.contents)}"><a href="${page('index.html','#features')}">${escape(t.nav[0])}</a><a href="${page('index.html','#downloads')}">${escape(t.nav[1])}</a><a href="${page('guide.html')}"${guide?' aria-current="page"':''}>${escape(t.nav[2])}</a><a href="${page('index.html','#faq')}">${escape(t.nav[3])}</a></nav><select class="lang" aria-label="Language / 语言 / ภาษา">${Object.entries(languages).map(([code,name])=>`<option value="${code}"${code===language?' selected':''}>${name}</option>`).join('')}</select></div>`;
  document.querySelector('.lang').addEventListener('change', event => {
    const next = event.target.value;
    try { localStorage.setItem('fusion-language', next); } catch (_) { /* Optional preference. */ }
    const url = new URL(location.href); url.searchParams.set('lang', next); location.assign(url.href);
  });
  document.getElementById('site-footer').className = 'footer';
  document.getElementById('site-footer').innerHTML = `<div class="container footer-inner"><span>SMT Fusion · ${escape(t.footer)}</span><div class="footer-links"><a href="${source}">${escape(t.source)} ↗</a><a href="${releases}">${escape(t.versions)} ↗</a><a href="${page('guide.html')}">${escape(t.guide)}</a></div></div>`;
  if (guide) {
    const mapping = [['料件编号','料号'],['品名','物料描述'],['组成用量','数量'],['插件位置','位号']];
    document.getElementById('main').innerHTML = `<div class="container guide-shell"><aside class="guide-nav"><input class="guide-search" type="search" aria-label="${escape(t.search)}" placeholder="${escape(t.search)}"><label>${escape(t.contents)}</label><nav class="guide-links">${t.sections.map(s=>`<a href="#${s.id}">${escape(s.title)}</a>`).join('')}</nav></aside><article class="guide-content"><span class="kicker">SMT FUSION / DOCUMENTATION</span><h1>${escape(t.guideTitle)}</h1><p class="guide-intro">${escape(t.guideIntro)}</p><p class="no-results" role="status" hidden>${escape(t.noResults)}</p>${t.sections.map(s=>`<section class="guide-section" id="${s.id}"><h2>${escape(s.title)}</h2><ol>${s.steps.map(x=>`<li>${escape(x)}</li>`).join('')}</ol>${s.fields?`<table><thead><tr>${t.fieldHeaders.map(x=>`<th scope="col">${escape(x)}</th>`).join('')}</tr></thead><tbody>${mapping.map(([a,b])=>`<tr><td>${a}</td><td>${b}</td></tr>`).join('')}</tbody></table>`:''}<p class="notice${s.red?' red':''}">${escape(s.note)}</p></section>`).join('')}</article></div>`;
    const input = document.querySelector('.guide-search');
    const sections = [...document.querySelectorAll('.guide-section')];
    input.addEventListener('input', () => {
      const term = input.value.trim().toLocaleLowerCase(); let count = 0;
      sections.forEach(section => {
        const match = section.textContent.toLocaleLowerCase().includes(term);
        section.hidden = !match;
        document.querySelector(`.guide-links a[href="#${section.id}"]`).hidden = !match;
        if (match) count++;
      });
      document.querySelector('.no-results').hidden = count > 0;
    });
    if ('IntersectionObserver' in window) {
      const observer = new IntersectionObserver(entries => entries.forEach(entry => {
        if (!entry.isIntersecting) return;
        document.querySelectorAll('.guide-links a').forEach(a => a.classList.toggle('active', a.hash === `#${entry.target.id}`));
      }), {rootMargin:'-100px 0px -65% 0px'});
      sections.forEach(section => observer.observe(section));
    }
  } else {
    const cards = [
      ['Windows',t.winNote,t.winSmall,[['SMT-CHECK-Setup-x64.exe',`x64 · ${t.setup}`],['SMT-CHECK-Setup-arm64.exe',`ARM64 · ${t.setup}`]]],
      ['Linux',t.linuxNote,t.linuxSmall,[['SMT-CHECK-linux-amd64.deb',`AMD64 · ${t.deb}`],['SMT-CHECK-linux-arm64.deb',`ARM64 · ${t.deb}`]]],
      ['macOS',t.macNote,t.macSmall,[['SMT-Fusion-macos-universal.pkg',`Universal · ${t.pkg}`],['SMT-CHECK-macos-universal.dmg',`Universal · ${t.dmg}`]]]
    ];
    document.getElementById('main').innerHTML = `<div class="container"><section class="hero"><div><div class="eyebrow">${escape(t.eyebrow)}</div><h1>${escape(t.hero[0])}<br><em>${escape(t.hero[1])}</em></h1><p class="lead">${escape(t.lead)}</p><div class="actions">${link('#downloads',t.download,true)}${link(page('guide.html'),t.guide)}</div><p class="version-line"><a href="${releases}/latest" id="latest-version">${escape(t.release)}</a> · ${escape(t.local)}</p></div><img class="hero-art" src="assets/app-icon.png" alt="SMT Fusion · BOM / CAD" width="512" height="512"></section><figure class="product"><div class="window"><div class="window-bar"><i class="window-dot"></i><i class="window-dot"></i><i class="window-dot"></i><span>SMT Fusion · Native desktop</span></div><img src="assets/workbench-${language}.png" alt="${escape(t.demo)}" width="1560" height="920" fetchpriority="high"></div><figcaption class="caption"><span>${escape(t.demo)}</span><a href="assets/workbench-${language}.png">${escape(t.enlarge)}</a></figcaption></figure><section class="section" id="features"><span class="kicker">${escape(t.workflowLabel)}</span><h2>${escape(t.workflowTitle)}</h2><div class="workflow">${t.workflow.map(([title,desc],i)=>`<article><span class="step-num">0${i+1}</span><h3>${escape(title)}</h3><p>${escape(desc)}</p></article>`).join('')}</div></section><section class="section split"><div><span class="kicker">${escape(t.evidenceLabel)}</span><h2>${escape(t.evidenceTitle)}</h2><p class="muted">${escape(t.evidenceText)}</p><ul>${t.evidencePoints.map(x=>`<li>${escape(x)}</li>`).join('')}</ul></div><div><div class="data-box"><table><thead><tr>${t.sampleHeaders.map(x=>`<th scope="col">${escape(x)}</th>`).join('')}</tr></thead><tbody><tr><td>DEMO-R01</td><td><span class="ref pass">R101</span> <span class="ref pass">R102</span></td><td><span class="badge pass">PASS</span></td></tr><tr><td>DEMO-C02</td><td><span class="ref ng">C104</span></td><td><span class="badge ng">NG</span></td></tr><tr><td>DEMO-U03</td><td><span class="ref pass">U1</span></td><td><span class="badge pass">PASS</span></td></tr></tbody></table></div><p class="download-note">${escape(t.sampleNote)}</p></div></section><section class="section split"><div><span class="kicker">${escape(t.coordinateLabel)}</span><h2>${escape(t.coordinateTitle)}</h2><p class="muted">${escape(t.coordinateText)}</p></div><div><div class="tags"><span class="tag">RefDes + Board + Layer</span><span class="tag">±0.001 mm</span><span class="tag">0° ≡ 360°</span></div><p class="muted">${escape(t.specialText)}</p><p class="notice">${escape(t.coordinateNote)}</p></div></section></div><section class="downloads" id="downloads"><div class="container"><span class="kicker">WINDOWS / LINUX / MACOS</span><h2>${escape(t.downloadsTitle)}</h2><p class="muted">${escape(t.downloadsText)}</p><div class="download-grid">${cards.map(([platform,note,small,items])=>`<article class="download-card"><h3 class="platform">${platform}</h3><p class="muted">${escape(note)}</p>${items.map(([file,label])=>link(download(file),label)).join('')}<small>${escape(small)}</small></article>`).join('')}</div><p class="download-note">${escape(t.downloadNote)} <a href="${releases}/latest">${escape(t.checksums)} ↗</a></p></div></section><section class="section container faq-layout" id="faq"><div><span class="kicker">FAQ</span><h2>${escape(t.faqTitle)}</h2><div class="actions">${link(page('guide.html'),t.guide)}</div></div><div class="faq">${t.faq.map(([q,a])=>`<details><summary>${escape(q)}</summary><p>${escape(a)}</p></details>`).join('')}</div></section>`;
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 4000);
    fetch('https://api.github.com/repos/Marginal-Z/SMT-CHECK/releases/latest', {signal:controller.signal})
      .then(response => response.ok ? response.json() : null)
      .then(release => { if (release && /^v\d+\.\d+\.\d+/.test(release.tag_name)) document.getElementById('latest-version').textContent = `${t.release} · ${release.tag_name}`; })
      .catch(() => { /* Download links work without the optional version badge. */ })
      .finally(() => clearTimeout(timeout));
  }
})();

