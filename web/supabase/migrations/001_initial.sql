-- Run once in a new Supabase project. No personal data is seeded.
create extension if not exists btree_gist with schema extensions;
create table public.operators(id uuid primary key references auth.users(id) on delete cascade, name text not null, role text not null default 'operator' check(role in ('admin','operator')), active boolean not null default true);
alter table public.operators enable row level security;
create function public.is_operator() returns boolean language sql stable security definer set search_path='' as $$ select coalesce((select active from public.operators where id=auth.uid()),false) and coalesce(auth.jwt()->>'aal'='aal2',false) $$;
create function public.is_admin() returns boolean language sql stable security definer set search_path='' as $$ select public.is_operator() and exists(select 1 from public.operators where id=auth.uid() and role='admin') $$;
revoke all on function public.is_operator(),public.is_admin() from public;
grant execute on function public.is_operator(),public.is_admin() to authenticated;
create policy operator_read on public.operators for select to authenticated using(public.is_operator() and (id=auth.uid() or public.is_admin()));
-- No browser INSERT/UPDATE/DELETE policy for operators. Admin Edge Function owns invitations.
grant select on public.operators to authenticated;
revoke insert,update,delete on public.operators from anon,authenticated;

create table public.patients(
 id uuid primary key default gen_random_uuid(),name text not null check(length(trim(name))>0),age int not null check(age between 0 and 125),
 status text not null default 'Aguardando contato' check(status in ('Aguardando contato','Triagem agendada','Triagem realizada','Aguardando vaga','Em atendimento','Encerrado','Desistência','Encaminhado')),
 availability jsonb not null default '[]' check(jsonb_typeof(availability)='array'),details jsonb not null default '{}' check(jsonb_typeof(details)='object'),
 check(details->>'members' is null or ((details->>'members')::numeric>=1 and (details->>'members')::numeric=trunc((details->>'members')::numeric))),
 check(details->>'income' is null or (details->>'income')::numeric>=0)
);
create table public.students(
 id uuid primary key default gen_random_uuid(),name text not null check(length(trim(name))>0),supervisor text not null check(length(trim(supervisor))>0),semester text not null check(semester in ('Clínico 1','Clínico 2')),
 availability jsonb not null default '[]' check(jsonb_typeof(availability)='array'),institution_verified boolean not null default false,declared_count int not null default 0 check(declared_count>=0),reconciled boolean not null default false
);
create table public.assignments(
 id uuid primary key default gen_random_uuid(),patient_id uuid not null references public.patients(id),student_id uuid not null references public.students(id),started_on date not null default current_date,ended_on date,reason text not null default '',check(ended_on is null or (ended_on>=started_on and length(trim(reason))>0))
);
create unique index one_active_assignment_per_patient on public.assignments(patient_id) where ended_on is null;
create index assignments_student on public.assignments(student_id) where ended_on is null;
create table public.appointments(
 id uuid primary key default gen_random_uuid(),patient_id uuid not null references public.patients(id),student_id uuid references public.students(id),start timestamptz not null,"end" timestamptz not null,
 kind text not null check(kind in ('Triagem','Sessão')),status text not null default 'Agendado' check(status in ('Agendado','Realizado','Faltou','Cancelado')),room text not null default '',check("end">start),
 exclude using gist(patient_id with =,tstzrange(start,"end",'[)') with &&) where(status<>'Cancelado'),
 exclude using gist(student_id with =,tstzrange(start,"end",'[)') with &&) where(status<>'Cancelado' and student_id is not null),
 exclude using gist(room with =,tstzrange(start,"end",'[)') with &&) where(status<>'Cancelado' and room<>'')
);
create table public.audit_events(id bigint generated always as identity primary key,actor uuid references auth.users(id),occurred_at timestamptz not null default now(),action text not null,entity text not null,record_id uuid, row_count int);
alter table public.audit_events enable row level security;
create policy audit_admin_read on public.audit_events for select to authenticated using(public.is_admin());
grant select on public.audit_events to authenticated;
revoke insert,update,delete on public.audit_events from anon,authenticated;

do $$ declare t text; begin foreach t in array array['patients','students','assignments','appointments'] loop
 execute format('alter table public.%I enable row level security',t);
 execute format('create policy operator_select on public.%I for select to authenticated using(public.is_operator())',t);
 execute format('create policy operator_insert on public.%I for insert to authenticated with check(public.is_operator())',t);
 execute format('create policy operator_update on public.%I for update to authenticated using(public.is_operator()) with check(public.is_operator())',t);
 execute format('grant select,insert,update on public.%I to authenticated',t);
 execute format('revoke all on public.%I from anon',t);
 execute format('revoke delete on public.%I from authenticated',t);
 end loop;end $$;

create function public.audit_mutation() returns trigger language plpgsql security definer set search_path='' as $$ begin
 insert into public.audit_events(actor,action,entity,record_id) values(auth.uid(),TG_OP,TG_TABLE_NAME,new.id);return new;end $$;
revoke all on function public.audit_mutation() from public;
do $$ declare t text;begin foreach t in array array['patients','students','assignments','appointments','operators'] loop
 execute format('create trigger audit_change after insert or update on public.%I for each row execute function public.audit_mutation()',t);end loop;end $$;

create function public.check_assignment() returns trigger language plpgsql set search_path='' as $$ declare p public.patients;begin
 if TG_OP='UPDATE' and (old.patient_id<>new.patient_id or old.student_id<>new.student_id or old.ended_on is not null) then raise exception 'Encerre o vínculo e crie outro; histórico é imutável.';end if;
 if new.ended_on is null then
 select * into p from public.patients where id=new.patient_id for update;
 if p.age<7 or (p.details->>'atitus_student') is distinct from 'false' or (p.details->>'employee') is distinct from 'false' or (p.details->>'psychology_relative') is distinct from 'false' then raise exception 'Confira idade e vínculos institucionais do paciente.';end if;
 if not exists(select 1 from public.students where id=new.student_id and institution_verified) then raise exception 'Aluno sem vínculo Atitus confirmado.';end if;
 end if;return new;end $$;
create trigger check_assignment before insert or update on public.assignments for each row execute function public.check_assignment();
create function public.sync_assignment() returns trigger language plpgsql set search_path='' as $$ begin
 update public.patients set status=case when new.ended_on is null then 'Em atendimento' else 'Encerrado' end where id=new.patient_id;
 if new.ended_on is not null then update public.appointments set status='Cancelado' where patient_id=new.patient_id and student_id=new.student_id and kind='Sessão' and status='Agendado' and start>now();end if;
 return new;end $$;
create trigger sync_assignment after insert or update on public.assignments for each row execute function public.sync_assignment();
create function public.check_appointment() returns trigger language plpgsql set search_path='' as $$ begin
 if new.student_id is not null and not exists(select 1 from public.students where id=new.student_id and institution_verified) then raise exception 'Aluno sem vínculo Atitus confirmado.';end if;return new;end $$;
create trigger check_appointment before insert or update on public.appointments for each row execute function public.check_appointment();

create function public.check_patient_update() returns trigger language plpgsql set search_path='' as $$ begin
 if exists(select 1 from public.assignments where patient_id=new.id and ended_on is null) and (new.status<>'Em atendimento' or new.age<7 or (new.details->>'atitus_student') is distinct from 'false' or (new.details->>'employee') is distinct from 'false' or (new.details->>'psychology_relative') is distinct from 'false') then raise exception 'Encerre o vínculo ativo antes de alterar situação ou impedimentos.';end if;return new;end $$;
create trigger check_patient_update before update on public.patients for each row execute function public.check_patient_update();
create function public.sync_triage() returns trigger language plpgsql set search_path='' as $$ begin
 if new.kind='Triagem' and new.status in ('Agendado','Realizado') then
 update public.patients set status=case when new.status='Realizado' then 'Triagem realizada' else 'Triagem agendada' end where id=new.patient_id and status in ('Aguardando contato','Triagem agendada','Triagem realizada');
 end if;return new;end $$;
create trigger sync_triage after insert or update on public.appointments for each row execute function public.sync_triage();

-- Atomic import and manual saves share RLS and constraints. Table names are explicitly whitelisted.
create function public.save_batch(entity text,rows jsonb) returns void language plpgsql security invoker set search_path='' as $$ declare item jsonb;begin
 if not public.is_operator() then raise exception 'Acesso negado';end if;
 if jsonb_typeof(rows)<>'array' or jsonb_array_length(rows)>500 then raise exception 'Lote inválido (máximo 500).';end if;
 for item in select value from jsonb_array_elements(rows) loop
 case entity
 when 'patients' then insert into public.patients select * from jsonb_populate_record(null::public.patients,item) on conflict(id) do update set name=excluded.name,age=excluded.age,status=excluded.status,availability=excluded.availability,details=excluded.details;
 when 'students' then insert into public.students select * from jsonb_populate_record(null::public.students,item) on conflict(id) do update set name=excluded.name,supervisor=excluded.supervisor,semester=excluded.semester,availability=excluded.availability,institution_verified=excluded.institution_verified,declared_count=excluded.declared_count,reconciled=excluded.reconciled;
 when 'appointments' then insert into public.appointments select * from jsonb_populate_record(null::public.appointments,item) on conflict(id) do update set patient_id=excluded.patient_id,student_id=excluded.student_id,start=excluded.start,"end"=excluded."end",kind=excluded.kind,status=excluded.status,room=excluded.room;
 when 'assignments' then insert into public.assignments select * from jsonb_populate_record(null::public.assignments,item) on conflict(id) do update set ended_on=excluded.ended_on,reason=excluded.reason;
 else raise exception 'Entidade inválida';end case;
 end loop;end $$;
revoke all on function public.save_batch(text,jsonb) from public;
grant execute on function public.save_batch(text,jsonb) to authenticated;
create function public.log_export(entity text,total int) returns void language plpgsql security definer set search_path='' as $$ begin
 if not public.is_operator() or total<0 or entity not in ('patients','students','assignments','appointments','overview') then raise exception 'Acesso negado';end if;
 insert into public.audit_events(actor,action,entity,row_count) values(auth.uid(),'EXPORT',entity,total);end $$;
revoke all on function public.log_export(text,int) from public;
grant execute on function public.log_export(text,int) to authenticated;
