-- O QUE É: cria a aba PROMOÇÕES do app (o cliente vê, a loja cadastra).
-- COMO USAR: Supabase > SQL Editor > New query > cole tudo > Run. (Pode rodar mais de uma vez sem problema.)

create table if not exists public.pdv_promocoes (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  descricao text,
  preco_de numeric(10,2),          -- preço normal (aparece riscado)
  preco_por numeric(10,2) not null, -- preço da promoção
  ate date,                         -- vale até (vazio = sem data)
  ativa boolean not null default true,
  criado_em timestamptz not null default now()
);
alter table public.pdv_promocoes enable row level security;  -- ninguém mexe direto; só pelas funções abaixo

-- CLIENTE (app aberto, sem senha): só enxerga o que está ativo e dentro da validade
create or replace function public.pdv_promocoes_listar()
returns json language sql security definer set search_path to 'public' as $$
  select coalesce(json_agg(json_build_object('id',id,'nome',nome,'descricao',descricao,
           'preco_de',preco_de,'preco_por',preco_por,'ate',ate) order by criado_em desc),'[]'::json)
    from public.pdv_promocoes
   where ativa and (ate is null or ate >= (now() at time zone 'America/Bahia')::date);
$$;
grant execute on function public.pdv_promocoes_listar() to anon, authenticated;

-- LOJA (com senha do funcionário): ver todas, salvar e excluir
create or replace function public.pdv_promocao_adm_listar(p_func uuid, p_pin text)
returns json language plpgsql security definer set search_path to 'public' as $$
begin
  if not coalesce((public.verificar_acesso(p_func,p_pin,null)->>'ok')::boolean,false) then raise exception 'Senha incorreta'; end if;
  return (select coalesce(json_agg(to_json(p) order by p.criado_em desc),'[]'::json) from public.pdv_promocoes p);
end $$;

create or replace function public.pdv_promocao_salvar(p_func uuid, p_pin text, p_id uuid, p_nome text,
  p_descricao text, p_de numeric, p_por numeric, p_ate date, p_ativa boolean)
returns uuid language plpgsql security definer set search_path to 'public' as $$
declare r uuid;
begin
  if not coalesce((public.verificar_acesso(p_func,p_pin,null)->>'ok')::boolean,false) then raise exception 'Senha incorreta'; end if;
  if coalesce(trim(p_nome),'')='' then raise exception 'Digite o nome do produto.'; end if;
  if p_por is null or p_por <= 0 then raise exception 'Digite o preço da promoção.'; end if;
  if p_id is null then
    insert into public.pdv_promocoes(nome,descricao,preco_de,preco_por,ate,ativa)
    values (trim(p_nome),nullif(trim(p_descricao),''),p_de,p_por,p_ate,coalesce(p_ativa,true)) returning id into r;
  else
    update public.pdv_promocoes set nome=trim(p_nome),descricao=nullif(trim(p_descricao),''),preco_de=p_de,
      preco_por=p_por,ate=p_ate,ativa=coalesce(p_ativa,true) where id=p_id returning id into r;
  end if;
  return r;
end $$;

create or replace function public.pdv_promocao_excluir(p_func uuid, p_pin text, p_id uuid)
returns void language plpgsql security definer set search_path to 'public' as $$
begin
  if not coalesce((public.verificar_acesso(p_func,p_pin,null)->>'ok')::boolean,false) then raise exception 'Senha incorreta'; end if;
  delete from public.pdv_promocoes where id=p_id;
end $$;

grant execute on function public.pdv_promocao_adm_listar(uuid,text), public.pdv_promocao_salvar(uuid,text,uuid,text,text,numeric,numeric,date,boolean),
  public.pdv_promocao_excluir(uuid,text,uuid) to anon, authenticated;
