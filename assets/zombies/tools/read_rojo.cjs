const fs = require('node:fs');
function decode(buffer) {
  let offset = 0;
  const string = n => { const s = buffer.toString('utf8', offset, offset+n); offset += n; return s; };
  const array = n => Array.from({length:n}, read);
  const map = n => { const value = {}; while(n--) value[read()] = read(); return value; };
  function read() {
    const tag = buffer[offset++];
    if (tag < 0x80) return tag;
    if (tag >= 0xe0) return tag-256;
    if ((tag & 0xe0) === 0xa0) return string(tag & 31);
    if ((tag & 0xf0) === 0x90) return array(tag & 15);
    if ((tag & 0xf0) === 0x80) return map(tag & 15);
    if (tag === 0xc0) return null;
    if (tag === 0xc2 || tag === 0xc3) return tag === 0xc3;
    if (tag === 0xca) { const n=buffer.readFloatBE(offset); offset+=4; return n; }
    if (tag === 0xcb) { const n=buffer.readDoubleBE(offset); offset+=8; return n; }
    const sizes = {0xcc:1,0xcd:2,0xce:4,0xcf:8,0xd0:1,0xd1:2,0xd2:4,0xd3:8};
    if (sizes[tag]) { const size=sizes[tag]; const n=size===8 ? Number(tag<0xd0?buffer.readBigUInt64BE(offset):buffer.readBigInt64BE(offset)) : (tag<0xd0?buffer.readUIntBE(offset,size):buffer.readIntBE(offset,size)); offset+=size; return n; }
    const lengthSizes={0xd9:1,0xda:2,0xdb:4,0xdc:2,0xdd:4,0xde:2,0xdf:4};
    if (lengthSizes[tag]) { const size=lengthSizes[tag],n=buffer.readUIntBE(offset,size); offset+=size; return tag<=0xdb ? string(n) : tag<=0xdd ? array(n) : map(n); }
    throw new Error('Unsupported MessagePack tag: '+tag.toString(16));
  }
  return read();
}
(async()=>{
  const get = async path => decode(Buffer.from(await (await fetch('http://localhost:34873'+path)).arrayBuffer()));
  const info = await get('/api/rojo');
  const snapshot = await get('/api/read/'+info.rootInstanceId);
  fs.writeFileSync('assets/zombies/rojo_snapshot.json', JSON.stringify(snapshot));
  const instances=snapshot.instances;
  console.log(JSON.stringify({info,keys:Object.keys(snapshot),instanceCount:Object.keys(instances).length,example:Object.values(instances).find(i=>i.className==='MeshPart')}));
})();
