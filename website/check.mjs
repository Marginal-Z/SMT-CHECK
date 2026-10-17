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
  const ids = ['start','files','review','cad','compare','ai','exports','updates','shortcuts'];
  for(const language of ['zh','en','th']) {
    const item=content[language];
    assert.deepEqual(Array.from(item.sections,s=>s.id),ids);
    assert.equal(item.faq.length,6);
    assert.equal(item.fieldHeaders.length,2);
    for(const section of item.sections) {assert.ok(section.title);assert.ok(section.note);assert.ok(section.steps.length>=3);}
  }
});
test('every local runtime asset exists and source syntax is valid',()=>{
  for(const asset of ['index.html','guide.html','styles.css','site.js','assets/app-icon.png','assets/NotoSansThai.ttf',...['zh','en','th'].map(l=>`assets/workbench-${l}.png`)]) assert.ok(fs.statSync(path.join(root,asset)).size>0,asset);
  new vm.Script(fs.readFileSync(path.join(root,'site.js'),'utf8'));
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
