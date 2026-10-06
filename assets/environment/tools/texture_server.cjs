const http=require('http'),fs=require('fs'),path=require('path');
const png=path.resolve(__dirname,'../ArenaPalette.png');
http.createServer((req,res)=>{
 if(req.url!='/ArenaPalette.png'){res.writeHead(404).end();return;}
 res.writeHead(200,{'Content-Type':'image/png'});fs.createReadStream(png).pipe(res);
}).listen(8189,'127.0.0.1');
