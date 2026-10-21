// Optional asset generation only. The checked-in ICO keeps normal .NET builds independent of Node/sharp.
import { createRequire } from 'node:module';
import { readFile, writeFile } from 'node:fs/promises';
import { resolve, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const require = createRequire(join(resolve(process.argv[2] ?? process.cwd()), 'package.json'));
const sharp = require('sharp');
const source = fileURLToPath(new URL('../Companion/TheNameBeneathCompanion/Assets/PortalFavicon.svg', import.meta.url));
const destination = fileURLToPath(new URL('../Companion/TheNameBeneathCompanion/Assets/Companion.ico', import.meta.url));
const sizes = [16, 32, 48, 64, 128, 256];
const svg = await readFile(source);
const frames = await Promise.all(sizes.map(size => sharp(svg, { density: 576 }).resize(size, size).png().toBuffer()));
const directory = Buffer.alloc(6 + 16 * frames.length);
directory.writeUInt16LE(1, 2); // ICO rather than CUR.
directory.writeUInt16LE(frames.length, 4);
let offset = directory.length;
for (let i = 0; i < frames.length; i++) {
  const entry = 6 + i * 16;
  directory[entry] = sizes[i] === 256 ? 0 : sizes[i];
  directory[entry + 1] = directory[entry];
  directory.writeUInt16LE(1, entry + 4);
  directory.writeUInt16LE(32, entry + 6);
  directory.writeUInt32LE(frames[i].length, entry + 8);
  directory.writeUInt32LE(offset, entry + 12);
  offset += frames[i].length;
}
await writeFile(destination, Buffer.concat([directory, ...frames]));
console.log(`Generated companion ICO from the unmodified portal favicon: ${sizes.join(', ')} px.`);
