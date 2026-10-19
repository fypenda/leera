// Renders the iOS app icon and launch images from assets/brand.
//
//   node scripts/render_brand.mjs
//
// Needs Playwright with Chromium (npm i -g playwright && npx playwright
// install chromium). Run from the project root.
import { chromium } from 'playwright';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = process.cwd();
const assets = `${root}/ios/Runner/Assets.xcassets`;
// Inlined: a page set from a string may not load file:// fonts.
const font = (file) =>
  `url(data:font/ttf;base64,${readFileSync(resolve(root, 'assets/fonts', file)).toString('base64')})`;
const icon = readFileSync(`${root}/assets/brand/app_icon.svg`, 'utf8');
const logo = readFileSync(`${root}/assets/brand/logo.svg`, 'utf8');

const page = (body, w, h) => `<!doctype html><html><head><style>
@font-face{font-family:Bricolage;src:${font('BricolageGrotesque-ExtraBold.ttf')};font-weight:800}
@font-face{font-family:Nunito;src:${font('Nunito-Bold.ttf')};font-weight:700}
html,body{margin:0;background:transparent}
#c{width:${w}px;height:${h}px;display:flex;flex-direction:column;align-items:center;justify-content:center}
svg{display:block}
</style></head><body><div id="c">${body}</div></body></html>`;

const browser = await chromium.launch();

async function shoot(html, w, h, scale, out, { opaque = false } = {}) {
  const p = await browser.newPage({ viewport: { width: w, height: h }, deviceScaleFactor: scale });
  await p.setContent(html);
  await p.evaluate(() => document.fonts.ready);
  await p.locator('#c').screenshot({ path: out, omitBackground: !opaque });
  await p.close();
}

// App icon: opaque square, every size the asset catalog lists.
const sizes = [
  ['20x20', [1, 2, 3]], ['29x29', [1, 2, 3]], ['40x40', [1, 2, 3]],
  ['60x60', [2, 3]], ['76x76', [1, 2]], ['83.5x83.5', [2]], ['1024x1024', [1]],
];
for (const [size, scales] of sizes) {
  const pt = parseFloat(size);
  for (const s of scales) {
    const px = Math.round(pt * s);
    const svg = icon.replace('<svg ', `<svg width="${px}" height="${px}" `);
    await shoot(page(svg, px, px), px, px, 1,
      `${assets}/AppIcon.appiconset/Icon-App-${size}@${s}x.png`, { opaque: true });
  }
}
await shoot(page(icon.replace('<svg ', '<svg width="1024" height="1024" '), 1024, 1024), 1024, 1024, 1,
  `${root}/assets/brand/app_icon_1024.png`, { opaque: true });

// Launch: the logo, the wordmark and the tagline, as on the Splash artboard.
const launch = `
<div style="filter:drop-shadow(0 18px 30px rgba(36,50,58,0.18))">${logo.replace('<svg ', '<svg width="148" height="148" ')}</div>
<div style="height:22px"></div>
<div style="font-family:Bricolage;font-weight:800;font-size:52px;letter-spacing:-0.03em;line-height:1;color:#24323A">leera</div>
<div style="height:6px"></div>
<div style="font-family:Nunito;font-weight:700;font-size:16px;color:#5E6A70">Your English, elevated.</div>`;
for (const [s, suffix] of [[1, ''], [2, '@2x'], [3, '@3x']]) {
  await shoot(page(launch, 260, 300), 260, 300, s,
    `${assets}/LaunchImage.imageset/LaunchImage${suffix}.png`);
}

// Three bars that rise, in place of the dots.
const bars = `<div style="height:26px;display:flex;align-items:flex-end;gap:5px">
<div style="width:7px;height:14px;border-radius:4px;background:#F09669"></div>
<div style="width:7px;height:20px;border-radius:4px;background:#D96266"></div>
<div style="width:7px;height:26px;border-radius:4px;background:#24323A"></div></div>`;
for (const [s, suffix] of [[1, ''], [2, '@2x'], [3, '@3x']]) {
  await shoot(page(bars, 31, 26), 31, 26, s,
    `${assets}/LaunchDots.imageset/LaunchDots${suffix}.png`);
}

await browser.close();
console.log('Brand images rendered.');
