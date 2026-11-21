import "jsr:@supabase/functions-js/edge-runtime.d.ts";
Deno.serve(async(req:Request)=>{
 if(req.method==="OPTIONS")return new Response("ok",{headers:{"Access-Control-Allow-Origin":"https://archionary.hrmnx.site","Access-Control-Allow-Headers":"authorization, apikey, content-type","Access-Control-Allow-Methods":"POST, OPTIONS"}});
 return new Response(JSON.stringify({error:"Username-based Archionary login is not enabled. Use standard account sign-in."}),{status:410,headers:{"Content-Type":"application/json","Access-Control-Allow-Origin":"https://archionary.hrmnx.site"}});
});