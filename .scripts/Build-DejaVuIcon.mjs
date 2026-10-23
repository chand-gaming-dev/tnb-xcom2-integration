// Deterministic vector rendering, not AI artwork. Requires existing sharp installation.
import { createRequire } from 'node:module';
import { readFile, writeFile } from 'node:fs/promises';
import { resolve, join } from 'node:path';
import { fileURLToPath } from 'node:url';
const require = createRequire(join(resolve(process.argv[2] ?? process.cwd()), 'package.json'));
const sharp = require('sharp');
const root = new URL('../Assets/DejaVu/', import.meta.url);
const source = await readFile(new URL('deja-vu-ability-white.svg', root));
const raw = await sharp(source).resize(512, 512).ensureAlpha().raw().toBuffer();
await sharp(raw, { raw: { width: 512, height: 512, channels: 4 } }).png().toFile(fileURLToPath(new URL('deja-vu-ability-white.png', root)));
// Uncompressed BGRA TGA, top-left origin; accepted by the UE3 texture importer.
const header = Buffer.alloc(18);
header[2] = 2; header.writeUInt16LE(512, 12); header.writeUInt16LE(512, 14);
header[16] = 32; header[17] = 0x28;
const bgra = Buffer.from(raw);
for (let i = 0; i < bgra.length; i += 4) [bgra[i], bgra[i + 2]] = [bgra[i + 2], bgra[i]];
await writeFile(new URL('deja-vu-ability-white.tga', root), Buffer.concat([header, bgra]));
console.log('Rendered 512x512 white/alpha PNG and importable TGA from the supplied SVG geometry.');
