/* GitHub Pages project-site friendly: keep runtime assets and page links relative. */
(() => {
  'use strict';
  const source='https://github.com/Marginal-Z/SMT-CHECK';
  const releases=`${source}/releases`;
  const languages={zh:'中文',en:'English',th:'ไทย'};
  const query=new URLSearchParams(location.search);
  let saved;
  try {saved=localStorage.getItem('fusion-language');} catch (_) {}
  let language=query.get('lang')||saved||'zh';
  if(!Object.hasOwn(languages,language)) language='zh';
  const t=window.FUSION_CONTENT[language],labels=t.guideLabels;
  const guide=document.body.dataset.page==='guide';
  const escape=value=>String(value).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  const page=(path,hash='')=>`${path}?lang=${language}${hash}`;
  const button=(url,label,primary=false,extra='')=>`<a class="button${primary?' primary':''} ${extra}" href="${url}">${escape(label)}</a>`;
  const table=({heads,rows})=>`<div class="table-scroll"><table><thead><tr>${heads.map(h=>`<th scope="col">${escape(h)}</th>`).join('')}</tr></thead><tbody>${rows.map(row=>`<tr>${row.map(cell=>`<td>${escape(cell)}</td>`).join('')}</tr>`).join('')}</tbody></table></div>`;
  document.documentElement.lang=t.lang;
  document.title=guide?`SMT Fusion — ${t.guideTitle}`:t.title;
  document.getElementById('site-header').className='site-header';
  document.getElementById('site-header').innerHTML=`<div class="container header-inner"><a class="brand" href="${page('index.html')}" aria-label="SMT Fusion"><img src="assets/app-icon.png" alt="" width="35" height="35">SMT Fusion</a><nav aria-label="${escape(labels.contents)}"><a href="${page('index.html','#features')}">${escape(t.nav[0])}</a><a href="${page('index.html','#downloads')}">${escape(t.nav[1])}</a><a href="${page('guide.html')}"${guide?' aria-current="page"':''}>${escape(t.nav[2])}</a></nav><select class="lang" aria-label="Language / 语言 / ภาษา">${Object.entries(languages).map(([code,name])=>`<option value="${code}"${code===language?' selected':''}>${name}</option>`).join('')}</select>${button(page('index.html','#downloads'),t.download,true,'header-download')}</div>`;
  document.querySelector('.lang').addEventListener('change',event=>{
    const next=event.target.value;
    try {localStorage.setItem('fusion-language',next);} catch (_) {}
    const url=new URL(location.href);url.searchParams.set('lang',next);location.assign(url.href);
  });
  document.getElementById('site-footer').className='footer';
  document.getElementById('site-footer').innerHTML=`<div class="container footer-inner"><span>SMT Fusion · ${escape(t.footer)}</span><div class="footer-links"><a href="${source}">${escape(t.source)}</a><a href="${releases}">${escape(t.versions)}</a><a href="${page('guide.html')}">${escape(t.nav[2])}</a></div></div>`;
  if(guide) renderGuide(); else renderHome();

  function renderGuide(){
    const mapping={heads:t.fieldHeaders,rows:[['料件编号','料号'],['品名','物料描述'],['组成用量','数量'],['插件位置','位号']]};
    function chapter(section,index){
      const next=t.sections[index+1];
      const image=section.id==='check'?'workbench':section.id==='review'?'merge':null;
      return `<section class="guide-section" id="${section.id}" aria-labelledby="heading-${section.id}"><div class="chapter-heading"><span class="number">${String(index+1).padStart(2,'0')}</span><h2 id="heading-${section.id}">${escape(section.title)}</h2></div><p>${escape(section.intro||'')}</p>${section.before?`<div class="prepare"><h3>${escape(labels.before)}</h3><ul>${section.before.map(x=>`<li>${escape(x)}</li>`).join('')}</ul></div>`:''}<h3>${escape(labels.steps)}</h3><ol class="guide-steps">${section.steps.map(x=>`<li>${escape(x)}</li>`).join('')}</ol>${section.fields?table(mapping):''}${section.table?table(section.table):''}${section.example?`<div class="guide-example"><h3>${escape(labels.example)}</h3><p>${escape(section.example)}</p></div>`:''}${image?`<figure class="guide-image"><a href="assets/${image}-${language}.png"><img src="assets/${image}-${language}.png" alt="${escape(section.title)} · ${escape(labels.figure)}" width="1560" height="920" loading="lazy"></a><figcaption>${escape(labels.figure)} · ${escape(t.enlarge)}</figcaption></figure>`:''}${section.expected?`<div class="outcome"><h3>${escape(labels.expected)}</h3><p>${escape(section.expected)}</p></div>`:''}${section.note?`<div class="notice${section.red?' red':''}"><strong>${escape(labels.important)}</strong><p>${escape(section.note)}</p></div>`:''}${next?`<a class="guide-next" href="#${next.id}"><span>${escape(labels.next)}</span>${escape(next.title)} <b aria-hidden="true">→</b></a>`:''}</section>`;
    }
    document.getElementById('main').innerHTML=`<div class="container guide-shell"><aside class="guide-nav"><input class="guide-search" type="search" aria-label="${escape(labels.search)}" placeholder="${escape(labels.search)}"><button class="search-clear" type="button" hidden>${escape(labels.clear)}</button><span class="toc-title">${escape(labels.contents)}</span><nav class="guide-links">${t.sections.map((s,i)=>`<a href="#${s.id}">${String(i+1).padStart(2,'0')} &nbsp;${escape(s.title)}</a>`).join('')}</nav></aside><article class="guide-content"><h1>${escape(t.guideTitle)}</h1><p class="guide-intro">${escape(t.guideIntro)}</p><p class="search-status" role="status" hidden></p><p class="no-results" hidden>${escape(t.noResults)}</p>${t.sections.map(chapter).join('')}</article></div>`;
    const input=document.querySelector('.guide-search');
    const clear=document.querySelector('.search-clear');
    const sections=[...document.querySelectorAll('.guide-section')];
    function search(){
      const term=input.value.trim().toLocaleLowerCase();let count=0;
      sections.forEach(section=>{
        const match=section.textContent.toLocaleLowerCase().includes(term);
        section.hidden=!match;document.querySelector(`.guide-links a[href="#${section.id}"]`).hidden=!match;if(match)count++;
      });
      document.querySelectorAll('.guide-next').forEach(link=>{link.hidden=Boolean(term);});
      clear.hidden=!term;
      const status=document.querySelector('.search-status');status.hidden=!term;status.textContent=`${count} ${labels.count}`;
      document.querySelector('.no-results').hidden=count>0;
    }
    input.addEventListener('input',search);
    clear.addEventListener('click',()=>{input.value='';search();input.focus();});
    if('IntersectionObserver' in window){
      const observer=new IntersectionObserver(entries=>entries.forEach(entry=>{
        if(entry.isIntersecting)document.querySelectorAll('.guide-links a').forEach(a=>a.classList.toggle('active',a.hash===`#${entry.target.id}`));
      }),{rootMargin:'-100px 0px -65% 0px'});
      sections.forEach(section=>observer.observe(section));
    }
  }

  function renderHome(){
    const platforms=[
      ['Windows',t.winNote,t.winSmall,[['SMT-CHECK-Setup-x64.exe',`x64 · ${t.setup}`],['SMT-CHECK-Setup-arm64.exe',`ARM64 · ${t.setup}`]]],
      ['Linux',t.linuxNote,t.linuxSmall,[['SMT-CHECK-linux-amd64.deb',`AMD64 · ${t.deb}`],['SMT-CHECK-linux-arm64.deb',`ARM64 · ${t.deb}`]]],
      ['macOS',t.macNote,t.macSmall,[['SMT-Fusion-macos-universal.pkg',t.pkg],['SMT-CHECK-macos-universal.dmg',t.dmg]]]
    ];
    document.getElementById('main').innerHTML=`<div class="container"><section class="hero"><h1>${escape(t.heroTitle)}</h1><p class="lead">${escape(t.heroLead)}</p><div class="actions">${button('#downloads',t.download,true)}${button(page('guide.html'),t.guide)}</div><p class="native-note">${escape(t.nativeLabel)} &nbsp; <a href="${releases}/latest" id="latest-version">${escape(t.release)}</a></p><figure class="hero-visual"><img src="assets/hero-production.png" alt="${escape(t.artAlt)}" width="1916" height="821" fetchpriority="high"><figcaption class="art-caption">${escape(t.artCaption)}</figcaption></figure></section><div class="process-band">${t.workflow.map(([title,desc],i)=>`<article><span class="number">${String(i+1).padStart(2,'0')}</span><div><h3>${escape(title)}</h3><p>${escape(desc)}</p></div></article>`).join('')}</div><section class="section" id="features"><div class="section-head"><h2>${escape(t.productTitle)}</h2><p>${escape(t.productText)}</p></div><div class="product-window"><div class="window-bar"><i></i><i></i><i></i><span>SMT Fusion</span></div><a href="assets/workbench-${language}.png"><img src="assets/workbench-${language}.png" alt="${escape(t.demo)}" width="1560" height="920" loading="lazy"></a></div><div class="caption"><span>${escape(t.demo)}</span><a href="assets/workbench-${language}.png">${escape(t.enlarge)}</a></div><div class="benefits">${t.evidencePoints.map((text,i)=>`<article><h3>${escape(t.featureTitles[i])}</h3><p>${escape(text)}</p></article>`).join('')}</div></section><section class="section split"><div><h2>${escape(t.evidenceTitle)}</h2><p>${escape(t.evidenceText)}</p></div><div><div class="data-box"><table><thead><tr>${t.sampleHeaders.map(x=>`<th scope="col">${escape(x)}</th>`).join('')}</tr></thead><tbody><tr><td>DEMO-R01</td><td><span class="ref pass">R101</span> <span class="ref pass">R102</span></td><td><span class="badge pass">PASS</span></td></tr><tr><td>DEMO-C02</td><td><span class="ref ng">C104</span></td><td><span class="badge ng">NG</span></td></tr><tr><td>DEMO-U03</td><td><span class="ref pass">U1</span></td><td><span class="badge pass">PASS</span></td></tr></tbody></table></div><p class="example-note">${escape(t.sampleNote)}</p></div></section><section class="section split"><div><h2>${escape(t.coordinateTitle)}</h2><p>${escape(t.coordinateText)}</p><p>${escape(t.specialText)}</p></div><div class="coordinate-panel"><div class="tags"><span class="tag">RefDes + Board + Layer</span><span class="tag">±0.001 mm</span><span class="tag">0° ≡ 360°</span></div><p>${escape(t.coordinateNote)}</p></div></section></div><section class="downloads" id="downloads"><div class="container"><div class="section-head"><h2>${escape(t.downloadsTitle)}</h2><p>${escape(t.downloadsText)}</p></div><div class="download-grid">${platforms.map(([platform,note,small,items])=>`<article class="download-card"><h3>${platform}</h3><p>${escape(note)}</p>${items.map(([file,label])=>button(`${releases}/latest/download/${file}`,label)).join('')}<small>${escape(small)}</small></article>`).join('')}</div><p class="download-note">${escape(t.downloadNote)} <a href="${releases}/latest">${escape(t.checksums)}</a></p></div></section><section class="section container faq-layout" id="faq"><div><h2>${escape(t.faqTitle)}</h2><div class="actions">${button(page('guide.html'),t.guide)}</div></div><div class="faq">${t.faq.map(([q,a])=>`<details><summary>${escape(q)}</summary><p>${escape(a)}</p></details>`).join('')}</div></section>`;
    const controller=new AbortController();const timeout=setTimeout(()=>controller.abort(),4000);
    fetch('https://api.github.com/repos/Marginal-Z/SMT-CHECK/releases/latest',{signal:controller.signal})
      .then(r=>r.ok?r.json():null).then(release=>{if(release&&/^v\d+\.\d+\.\d+/.test(release.tag_name))document.getElementById('latest-version').textContent=`${t.release} · ${release.tag_name}`;})
      .catch(()=>{/* Optional version badge does not gate downloads. */}).finally(()=>clearTimeout(timeout));
  }
})();
