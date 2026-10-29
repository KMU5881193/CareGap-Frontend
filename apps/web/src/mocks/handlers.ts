import {http,HttpResponse} from 'msw';
export const handlers=[http.get('/health',()=>HttpResponse.json({data:{status:'ok'}}))];
