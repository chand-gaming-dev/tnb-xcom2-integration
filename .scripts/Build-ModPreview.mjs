// Deterministic layout of the existing vector logo, not a redesigned favicon.
// Run from the mod solution: node .scripts/Build-ModPreview.mjs <Node tooling checkout containing sharp>
import { createRequire } from 'node:module';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const require = createRequire(join(resolve(process.argv[2] ?? process.cwd()), 'package.json'));
const sharp = require('sharp');
const source = fileURLToPath(new URL('../Companion/TheNameBeneathCompanion/Assets/PortalFavicon.svg', import.meta.url));
const destination = fileURLToPath(new URL('../TheNameBeneath/ModPreview.jpg', import.meta.url));
const favicon = await readFile(source);
const layout = Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <rect width="512" height="512" fill="#132B26"/>
  <image x="128" y="56" width="256" height="256" href="data:image/svg+xml;base64,${favicon.toString('base64')}"/>
  <text x="256" y="390" text-anchor="middle" font-family="Georgia, serif" font-size="43" font-weight="400" fill="#F3F0E7">The Name Beneath</text>
</svg>`);
await mkdir(dirname(destination), { recursive: true });
const jpeg = await sharp(layout, { density: 288 }).resize(512, 512).jpeg({ quality: 96, chromaSubsampling: '4:4:4' }).toBuffer();
const metadata = await sharp(jpeg).metadata();
if (metadata.width !== 512 || metadata.height !== 512 || metadata.format !== 'jpeg') throw new Error('Unexpected mod preview format');
await writeFile(destination, jpeg);
console.log('Generated 512 x 512 ModPreview.jpg from the original portal favicon and The Name Beneath title.');
