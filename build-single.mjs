// Regenerate Eva_single_file.html from index.html by inlining the local
// stylesheet (styles.css) and the src/*.js modules. CDN libs and the
// manifest link are left as external references (matches prior convention).
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = process.argv[2] || '.';
const p = (f) => resolve(ROOT, f);

let html = readFileSync(p('index.html'), 'utf8');

const SRC = ['bus','store','selectors','migrate','bridge','flags','roles','sync'];
for (const name of SRC) {
  const tag = `<script src="/src/${name}.js"></script>`;
  if (!html.includes(tag)) throw new Error(`missing script tag for src/${name}.js`);
  const code = readFileSync(p(`src/${name}.js`), 'utf8').replace(/\s+$/, '');
  html = html.replace(tag, `<script>\n${code}\n</script>`);
}

const cssTag = `<link rel="stylesheet" href="/styles.css">`;
if (!html.includes(cssTag)) throw new Error('missing styles.css link');
const css = readFileSync(p('styles.css'), 'utf8').replace(/\s+$/, '');
html = html.replace(cssTag, `<style>\n${css}\n</style>`);

// sanity: no local references should remain inlined-away
for (const leftover of ['src="/src/', 'href="/styles.css"']) {
  if (html.includes(leftover)) throw new Error(`leftover local ref: ${leftover}`);
}

writeFileSync(p('Eva_single_file.html'), html);
console.log('wrote Eva_single_file.html —', html.length, 'bytes');
