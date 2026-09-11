import {createClient} from 'npm:@supabase/supabase-js@2';

Deno.serve(async req=>{
 const origin=Deno.env.get('APP_ORIGIN')||'';
 const headers={'Access-Control-Allow-Origin':origin,'Access-Control-Allow-Headers':'authorization, x-client-info, apikey, content-type','Access-Control-Allow-Methods':'POST, OPTIONS','Vary':'Origin','Content-Type':'application/json'};
 const reply=(status:number,message:string)=>new Response(JSON.stringify({message}),{status,headers});
 if(!origin||req.headers.get('origin')!==origin)return reply(403,'Origem não autorizada.');
 if(req.method==='OPTIONS')return new Response(null,{status:204,headers});
 if(req.method!=='POST')return reply(405,'Método não permitido.');
 const authorization=req.headers.get('Authorization');if(!authorization)return reply(401,'Autenticação necessária.');
 const url=Deno.env.get('SUPABASE_URL')!,anon=Deno.env.get('SUPABASE_ANON_KEY')!;
 const caller=createClient(url,anon,{global:{headers:{Authorization:authorization}},auth:{persistSession:false}});
 const {data:{user},error:authError}=await caller.auth.getUser();if(authError||!user)return reply(401,'Sessão inválida.');
 // RLS enforces AAL2 and active membership; role is read from the database, never user metadata.
 const {data:profile,error:profileError}=await caller.from('operators').select('role,active').eq('id',user.id).single();
 if(profileError||!profile?.active||profile.role!=='admin')return reply(403,'Somente o administrador pode criar usuários.');
 let body;try{const raw=await req.text();if(raw.length>4096)return reply(413,'Requisição muito grande.');body=JSON.parse(raw)}catch{return reply(400,'Requisição inválida.');}
 const {email,name,redirectTo}=body;if(typeof email!=='string'||!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)||email.length>254||typeof name!=='string'||!name.trim()||name.length>120||redirectTo!==origin)return reply(400,'Confira nome e e-mail.');
 const admin=createClient(url,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,{auth:{persistSession:false,autoRefreshToken:false}});
 const {data:invite,error}=await admin.auth.admin.inviteUserByEmail(email.trim(),{redirectTo:origin});
 if(error||!invite.user)return reply(400,'Convite não enviado. Confira o endereço e as configurações de e-mail.');
 const {error:insertError}=await admin.from('operators').insert({id:invite.user.id,name:name.trim(),role:'operator',active:true});
 if(insertError){await admin.auth.admin.deleteUser(invite.user.id);return reply(500,'Não foi possível autorizar a conta. Convite cancelado.');}
 await admin.from('audit_events').insert({actor:user.id,action:'INVITE',entity:'operators',record_id:invite.user.id});
 return reply(200,'Convite enviado.');
});
