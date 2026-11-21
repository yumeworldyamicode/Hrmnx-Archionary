import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
const ORIGIN="https://archionary.hrmnx.site";
const headers=(origin:string)=>({"Access-Control-Allow-Origin":origin===ORIGIN?ORIGIN:ORIGIN,"Access-Control-Allow-Headers":"authorization, apikey, content-type","Access-Control-Allow-Methods":"POST, OPTIONS","Vary":"Origin"});
const reply=(data:unknown,status:number,origin:string)=>new Response(JSON.stringify(data),{status,headers:{...headers(origin),"Content-Type":"application/json"}});
Deno.serve(async(req:Request)=>{
 const origin=req.headers.get("origin")||"";
 if(req.method==="OPTIONS")return new Response("ok",{headers:headers(origin)});
 if(req.method!=="POST")return reply({error:"Method not allowed"},405,origin);
 if(origin&&origin!==ORIGIN)return reply({error:"Origin not allowed"},403,origin);
 let body:{email?:string,password?:string,bootstrapCode?:string};try{body=await req.json()}catch{return reply({error:"Invalid request."},400,origin);}
 const email=String(body.email||"").trim().toLowerCase(),password=String(body.password||""),code=String(body.bootstrapCode||"");
 const expected=Deno.env.get("ARCHIONARY_BOOTSTRAP_SECRET")||"";
 if(!expected||code.length<20||code!==expected)return reply({error:"Bootstrap code is incorrect or not configured."},403,origin);
 if(email!=="001@nemo")return reply({error:"Only the designated 001@nemo administrator account can be created."},400,origin);
 if(password.length<12)return reply({error:"Choose a password with at least 12 characters."},400,origin);
 const supabase=createClient(Deno.env.get("SUPABASE_URL")!,Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,{auth:{persistSession:false}});
 const {data:users,error:listError}=await supabase.auth.admin.listUsers({page:1,perPage:1000});
 if(listError)return reply({error:"Unable to check account availability."},503,origin);
 if(users.users.some(u=>u.email?.toLowerCase()===email))return reply({error:"The 001@nemo administrator account has already been created. Sign in instead."},409,origin);
 const {data,error}=await supabase.auth.admin.createUser({email,password,email_confirm:true});
 if(error||!data.user)return reply({error:error?.message||"Account creation failed."},400,origin);
 const {error:grantError}=await supabase.schema("private").from("archionary_admins").insert({user_id:data.user.id});
 if(grantError){await supabase.auth.admin.deleteUser(data.user.id);return reply({error:"Account created but administrator assignment failed; creation was rolled back."},500,origin);}
 return reply({success:true,message:"Administrator account created. You can now sign in."},200,origin);
});