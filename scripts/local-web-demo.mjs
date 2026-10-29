// Loopback-only static host and same-origin API proxy. No public deployment.
import http from 'node:http';
import {readFile} from 'node:fs/promises';
import {resolve,extname,sep} from 'node:path';
const root=resolve('build/web');
const mime={'.html':'text/html','.js':'text/javascript','.json':'application/json','.css':'text/css','.wasm':'application/wasm','.png':'image/png','.ttf':'font/ttf','.woff2':'font/woff2','.svg':'image/svg+xml'};
http.createServer(async(req,res)=>{
 if(req.headers.origin && req.headers.origin!=='http://127.0.0.1:4335'){res.writeHead(403).end();return;}
 if(req.url.startsWith('/api/')||req.url==='/health'){
  const headers={...req.headers,host:'127.0.0.1:4334'};delete headers.origin;
  const upstream=http.request({hostname:'127.0.0.1',port:4334,path:req.url,method:req.method,headers},r=>{res.writeHead(r.statusCode,r.headers);r.pipe(res);});
  upstream.on('error',()=>{if(!res.headersSent)res.writeHead(502);res.end();});req.pipe(upstream);return;
 }
 try{const pathname=decodeURIComponent(new URL(req.url,'http://127.0.0.1').pathname);const file=resolve(root,'.'+(pathname==='/'?'/index.html':pathname));if(!file.startsWith(root+sep)){res.writeHead(403).end();return;}const data=await readFile(file);res.writeHead(200,{'Content-Type':mime[extname(file)]??'application/octet-stream','Cache-Control':'no-store'});res.end(data);}catch{res.writeHead(404).end();}
}).listen(4335,'127.0.0.1',()=>console.log('Flutter demo: http://127.0.0.1:4335 (API proxy -> 4334)'));
