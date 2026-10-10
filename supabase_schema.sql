-- Schema opcional para registrar partidas do jogo "Palpite".
-- O jogo atual funciona inteiramente no navegador e não coleta dados pessoais.

create table if not exists public.partidas (
  identificador uuid primary key default gen_random_uuid(),
  iniciada_em timestamptz not null default now(),
  finalizada_em timestamptz,
  situacao text not null default 'em_andamento'
    check (situacao in ('em_andamento', 'acertou', 'respostas_inconsistentes', 'abandonada')),
  quantidade_tentativas smallint not null default 0
    check (quantidade_tentativas between 0 and 7),
  numero_acertado smallint
    check (numero_acertado between 1 and 100),
  constraint partidas_situacao_resultado_check check (
    (situacao = 'acertou' and numero_acertado is not null and finalizada_em is not null)
    or (situacao <> 'acertou' and numero_acertado is null)
  )
);

create table if not exists public.tentativas_partida (
  identificador bigint generated always as identity primary key,
  partida_identificador uuid not null references public.partidas(identificador) on delete cascade,
  numero_tentativa smallint not null check (numero_tentativa between 1 and 7),
  palpite smallint not null check (palpite between 1 and 100),
  resposta text not null check (resposta in ('menor', 'acertou', 'maior')),
  respondida_em timestamptz not null default now(),
  constraint tentativas_partida_numero_unique unique (partida_identificador, numero_tentativa)
);

create index if not exists tentativas_partida_identificador_idx
  on public.tentativas_partida (partida_identificador);

-- RLS sem políticas deixa os dados inacessíveis via Data API para anon/authenticated
-- até que exista um fluxo de acesso definido (por exemplo, autenticação ou backend).
alter table public.partidas enable row level security;
alter table public.tentativas_partida enable row level security;

revoke all on table public.partidas from anon, authenticated;
revoke all on table public.tentativas_partida from anon, authenticated;
revoke all on sequence public.tentativas_partida_identificador_seq from anon, authenticated;