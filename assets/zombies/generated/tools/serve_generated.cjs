const http = require('node:http'), fs = require('node:fs'), path = require('node:path');
const root = path.resolve(__dirname, '..');
http.createServer((req, res) => {
  const file = path.resolve(root, '.' + decodeURIComponent(req.url));
  if (!file.startsWith(root + path.sep) || !/\.(json|png)$/.test(file)) { res.writeHead(404); return res.end(); }
  fs.readFile(file, (error, data) => {
    if (error) { res.writeHead(404); return res.end(); }
    res.writeHead(200, {'Content-Type': file.endsWith('.png') ? 'image/png' : 'application/json'}); res.end(data);
  });
}).listen(62789, '127.0.0.1', () => console.log('Generated zombie assets ready on 62789'));
