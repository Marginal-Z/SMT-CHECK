import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root = path.dirname(fileURLToPath(import.meta.url));
const context = {window:{}};
vm.runInNewContext(fs.readFileSync(path.join(root,'content.js'),'utf8'),context);
const content = context.window.FUSION_CONTENT;
test('all three languages contain the same complete tutorial and FAQ',()=>{
  const ids = ['start','install','files','check','rules','review','cad','compare','ai','exports','updates','shortcuts','troubleshooting'];
  for(const language of ['zh','en','th']) {
    const item=content[language];
    assert.deepEqual(Array.from(item.sections,s=>s.id),ids);
    assert.equal(item.faq.length,5);
    assert.equal(item.fieldHeaders.length,2);
    for(const section of item.sections) {
      assert.ok(section.title);assert.ok(section.intro);assert.ok(section.expected);
      assert.ok(section.steps.length>=3,`${language}/${section.id}`);
      if(section.table) for(const row of section.table.rows) assert.equal(row.length,section.table.heads.length);
    }
    assert.ok(!/图标|\bicons?\b|ไอคอน/i.test(JSON.stringify(item.sections)));
    assert.ok(item.guideLabels.clear);
  }
});
test('every local runtime asset exists and source syntax is valid',()=>{
  for(const asset of ['index.html','guide.html','styles.css','site.js','assets/app-icon.png','assets/hero-production.png','assets/Manrope.ttf','assets/OFL-Manrope.txt','assets/NotoSansThai.ttf',...['zh','en','th'].flatMap(l=>[`assets/workbench-${l}.png`,`assets/merge-${l}.png`])]) assert.ok(fs.statSync(path.join(root,asset)).size>0,asset);
  new vm.Script(fs.readFileSync(path.join(root,'site.js'),'utf8'));
});
test('dedicated campaign artwork replaces the enlarged icon; Pages links remain relative',()=>{
  const js=fs.readFileSync(path.join(root,'site.js'),'utf8');
  assert.equal((js.match(/assets\/app-icon\.png/g)||[]).length,1,'icon belongs only in header');
  assert.ok(js.includes('assets/hero-production.png'));
  assert.ok(!/(?:href|src)="\/(?!\/)/.test(js),'project-site URLs must retain the repository prefix');
  for(const file of ['index.html','guide.html']){
    const html=fs.readFileSync(path.join(root,file),'utf8');
    assert.ok(html.includes('https://marginal-z.github.io/SMT-CHECK/'));
    assert.ok(!html.includes('chatgpt.site'));
  }
});
test('six direct installer links and safe local-only tutorial search are retained',()=>{
  const js=fs.readFileSync(path.join(root,'site.js'),'utf8');
  for(const file of ['SMT-CHECK-Setup-x64.exe','SMT-CHECK-Setup-arm64.exe','SMT-CHECK-linux-amd64.deb','SMT-CHECK-linux-arm64.deb','SMT-Fusion-macos-universal.pkg','SMT-CHECK-macos-universal.dmg']) assert.ok(js.includes(file));
  assert.ok(js.includes('textContent.toLocaleLowerCase().includes(term)'));
  assert.ok(!/eval\(|document\.write\(|type=["']file/.test(js));
  const css=fs.readFileSync(path.join(root,'styles.css'),'utf8');
  assert.ok(css.includes('[hidden]{display:none!important}'));
  assert.ok(css.includes('prefers-reduced-motion'));
  assert.ok(!/gradient\(/i.test(css));
});
