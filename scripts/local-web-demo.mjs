// Loopback-only static host and same-origin API proxy. No public deployment.
import http from 'node:http';
import {readFile} from 'node:fs/promises';
import {resolve,extname,sep} from 'node:path';
import {translateDemoLogin} from './demo-login-alias.mjs';
const root=resolve(process.env.DEMO_WEB_ROOT??'build/web');
const port=Number(process.env.DEMO_WEB_PORT??4335);
if(![4335,4337,4339].includes(port))throw Error('INVALID_DEMO_PORT');
const aliasFile=process.env.DEMO_LOGIN_ALIASES_FILE;
const attempts=new Map();
const allowedOrigins=new Set([`http://127.0.0.1:${port}`,...(process.env.DEMO_PUBLIC_ORIGIN?[process.env.DEMO_PUBLIC_ORIGIN]:[])]);
const mime={'.html':'text/html','.js':'text/javascript','.json':'application/json','.css':'text/css','.wasm':'application/wasm','.png':'image/png','.ttf':'font/ttf','.woff2':'font/woff2','.svg':'image/svg+xml'};
http.createServer(async(req,res)=>{
 if(req.headers.origin && !allowedOrigins.has(req.headers.origin)){res.writeHead(403).end();return;}
 if(req.url.startsWith('/api/')||req.url==='/health'){
  const headers={...req.headers,host:'127.0.0.1:4334'};delete headers.origin;
  let loginBody;
  if(aliasFile && req.method==='POST' && req.url==='/api/auth/login'){
   res.setHeader('Cache-Control','no-store');
   const address=req.socket.remoteAddress??'local';const now=Date.now();let rate=attempts.get(address);if(!rate||rate.until<now){rate={count:0,until:now+60000};attempts.set(address,rate);}if(++rate.count>30){res.writeHead(429,{'Content-Type':'application/json'}).end(JSON.stringify({error:{code:'RATE_LIMITED'}}));return;}
   try{let size=0;const chunks=[];for await(const chunk of req){size+=chunk.length;if(size>8192){res.writeHead(413).end();return;}chunks.push(chunk);}const input=JSON.parse(Buffer.concat(chunks).toString('utf8'));const rows=JSON.parse(await readFile(aliasFile,'utf8'));const translated=translateDemoLogin(input,rows);if(!translated){res.writeHead(401,{'Content-Type':'application/json'}).end(JSON.stringify({error:{code:'UNAUTHENTICATED'}}));return;}loginBody=JSON.stringify(translated);headers['content-length']=String(Buffer.byteLength(loginBody));delete headers['transfer-encoding'];}
   catch{res.writeHead(503,{'Content-Type':'application/json'}).end(JSON.stringify({error:{code:'DEMO_LOGIN_UNAVAILABLE'}}));return;}
  }
  const upstream=http.request({hostname:'127.0.0.1',port:4334,path:req.url,method:req.method,headers},r=>{res.writeHead(r.statusCode,r.headers);r.pipe(res);});
  upstream.on('error',()=>{if(!res.headersSent)res.writeHead(502);res.end();});if(loginBody)upstream.end(loginBody);else req.pipe(upstream);return;
 }
 try{const pathname=decodeURIComponent(new URL(req.url,'http://127.0.0.1').pathname);const file=resolve(root,'.'+(pathname==='/'?'/index.html':pathname));if(!file.startsWith(root+sep)){res.writeHead(403).end();return;}const data=await readFile(file);res.writeHead(200,{'Content-Type':mime[extname(file)]??'application/octet-stream','Cache-Control':'no-store'});res.end(data);}catch{res.writeHead(404).end();}
}).listen(port,'127.0.0.1',()=>console.log(`Flutter demo: http://127.0.0.1:${port} (API proxy -> 4334)`));
