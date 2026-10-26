-- O QUE É: libera o cliente a entrar no app pela PLACA da moto.
-- PARA QUE SERVE: o app do cliente passa a pedir só a placa; este comando devolve o link (token) da moto dessa placa.
-- COMO USAR: Supabase > SQL Editor > New query > cole tudo > Run. (Pode rodar mais de uma vez sem problema.)
-- Se a placa tiver mais de uma entrada, mostra primeiro a que ainda NÃO foi entregue; se todas já foram entregues, a mais recente.

create or replace function public.pdv_acompanhar_placa(p_placa text)
returns text
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  k text := regexp_replace(upper(coalesce(p_placa, '')), '[^A-Z0-9]', '', 'g');
  t text;
begin
  if length(k) <> 7 then raise exception 'Digite a placa completa (7 caracteres).'; end if;
  select token into t
    from public.pdv_ordens
   where token is not null
     and regexp_replace(upper(coalesce(placa, '')), '[^A-Z0-9]', '', 'g') = k
   order by (status = 'entregue'), coalesce(atualizado_em, criado_em) desc, criado_em desc
   limit 1;
  if t is null then raise exception 'Não encontramos essa placa. Confira se digitou certo ou fale com a loja.'; end if;
  return t;
end $$;

grant execute on function public.pdv_acompanhar_placa(text) to anon, authenticated;
