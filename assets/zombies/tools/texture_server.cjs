const http = require('http');
const fs = require('fs');
const path = require('path');
const png = path.resolve(__dirname, '../textures/world_people_colors.png');
const server = http.createServer((req, res) => {
  if (req.url !== '/world_people_colors.png') { res.writeHead(404).end(); return; }
  res.writeHead(200, { 'Content-Type': 'image/png' });
  fs.createReadStream(png).pipe(res);
});
server.listen(0, '127.0.0.1', () => console.log(`http://127.0.0.1:${server.address().port}/world_people_colors.png`));
