const http=require('node:http'),fs=require('node:fs'),path=require('node:path');
const root=path.resolve('assets/weapons');
http.createServer((req,res)=>{
  const file=path.resolve(root,'.'+decodeURIComponent(req.url));
  if(!file.startsWith(root+path.sep)||!file.endsWith('.png')){res.writeHead(404);return res.end();}
  fs.readFile(file,(err,data)=>{if(err){res.writeHead(404);return res.end();}res.writeHead(200,{'Content-Type':'image/png'});res.end(data);});
}).listen(62788,'127.0.0.1',()=>console.log('Weapon images ready on 62788'));
