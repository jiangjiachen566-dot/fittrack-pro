-- ============================================================
-- FitTrack Pro · Supabase Schema
-- 一键导入：Supabase 控制台 → SQL Editor → 粘贴 → Run
-- 包含：10 张表 + 行级安全策略（RLS）+ 触发器
-- ============================================================

-- ===== 1. profiles：用户档案 =====
create table if not exists public.profiles (
  id uuid primary key references auth.users on delete cascade,
  phone text unique not null,
  name text not null check (char_length(name) between 2 and 20),
  gender text check (gender in ('male','female')),
  age int check (age between 10 and 100),
  height_cm numeric check (height_cm between 100 and 220),
  start_weight numeric,
  goal_weight numeric,
  activity_level numeric default 1.55,
  start_date date default current_date,
  plan jsonb default '{}'::jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ===== 2. weights：体重记录 =====
create table if not exists public.weights (
  id bigserial primary key,
  user_id uuid not null references auth.users on delete cascade,
  date date not null,
  kg numeric not null check (kg between 20 and 300),
  fat numeric check (fat between 1 and 60),
  muscle numeric,
  note text check (char_length(coalesce(note,'')) <= 100),
  created_at timestamptz default now(),
  unique (user_id, date)
);

-- ===== 3. food_records：饮食记录 =====
create table if not exists public.food_records (
  id bigserial primary key,
  user_id uuid not null references auth.users on delete cascade,
  date date not null,
  meal text check (meal in ('breakfast','lunch','dinner','snack')),
  name text not null,
  emoji text,
  qty numeric default 1,
  cal numeric not null,
  p numeric default 0,
  c numeric default 0,
  f numeric default 0,
  time text,
  created_at timestamptz default now()
);

-- ===== 4. exercise_records：运动记录 =====
create table if not exists public.exercise_records (
  id bigserial primary key,
  user_id uuid not null references auth.users on delete cascade,
  date date not null,
  name text not null,
  type text,
  met numeric,
  min int check (min between 1 and 600),
  cal numeric,
  time text,
  created_at timestamptz default now()
);

-- ===== 5. water_records：饮水（按 ml 累加，每日单条） =====
create table if not exists public.water_records (
  id bigserial primary key,
  user_id uuid not null references auth.users on delete cascade,
  date date not null,
  ml int not null default 0,
  created_at timestamptz default now(),
  unique (user_id, date)
);

-- ===== 6. sleep_records：睡眠 =====
create table if not exists public.sleep_records (
  id bigserial primary key,
  user_id uuid not null references auth.users on delete cascade,
  date date not null,
  bedtime text,
  wake_time text,
  hours numeric,
  unique (user_id, date)
);

-- ===== 7. mood_records：心情 =====
create table if not exists public.mood_records (
  id bigserial primary key,
  user_id uuid not null references auth.users on delete cascade,
  date date not null,
  emoji text,
  label text,
  unique (user_id, date)
);

-- ===== 8. custom_foods：用户自定义食物库 =====
create table if not exists public.custom_foods (
  id bigserial primary key,
  user_id uuid not null references auth.users on delete cascade,
  name text not null,
  emoji text,
  cal numeric not null,
  p numeric default 0,
  c numeric default 0,
  f numeric default 0,
  created_at timestamptz default now()
);

-- ===== 9. achievements：已解锁徽章 =====
create table if not exists public.achievements (
  id bigserial primary key,
  user_id uuid not null references auth.users on delete cascade,
  badge_id text not null,
  unlocked_at timestamptz default now(),
  unique (user_id, badge_id)
);

-- ===== 索引（加速按日期查询） =====
create index if not exists idx_food_user_date on public.food_records (user_id, date desc);
create index if not exists idx_ex_user_date on public.exercise_records (user_id, date desc);
create index if not exists idx_weights_user_date on public.weights (user_id, date desc);

-- ============================================================
-- 行级安全策略（RLS）
-- 每个用户只能读写自己的行
-- ============================================================

alter table public.profiles enable row level security;
alter table public.weights enable row level security;
alter table public.food_records enable row level security;
alter table public.exercise_records enable row level security;
alter table public.water_records enable row level security;
alter table public.sleep_records enable row level security;
alter table public.mood_records enable row level security;
alter table public.custom_foods enable row level security;
alter table public.achievements enable row level security;

-- profiles：用 id 作为 user_id
drop policy if exists "profiles_owner_all" on public.profiles;
create policy "profiles_owner_all" on public.profiles
  for all using (auth.uid() = id) with check (auth.uid() = id);

-- 其余表统一用 user_id
do $$
declare t text;
begin
  foreach t in array array['weights','food_records','exercise_records','water_records',
                           'sleep_records','mood_records','custom_foods','achievements']
  loop
    execute format('drop policy if exists "%s_owner_all" on public.%I;', t, t);
    execute format('create policy "%s_owner_all" on public.%I
                    for all using (auth.uid() = user_id)
                    with check (auth.uid() = user_id);', t, t);
  end loop;
end $$;

-- ============================================================
-- 自动维护 updated_at
-- ============================================================

create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_profiles_updated on public.profiles;
create trigger trg_profiles_updated
before update on public.profiles
for each row execute procedure public.set_updated_at();

-- ============================================================
-- 完成。回到代码即可使用 supabase-js 操作所有表。
-- ============================================================

-- ============================================================
-- v3.1 追加：身体围度记录表
-- ============================================================
create table if not exists public.body_measures (
  id bigserial primary key,
  user_id uuid not null references auth.users on delete cascade,
  date date not null,
  waist numeric, chest numeric, hip numeric, thigh numeric,
  arm numeric, neck numeric, calf numeric,
  note text,
  created_at timestamptz default now(),
  unique (user_id, date)
);
create index if not exists idx_body_user_date on public.body_measures (user_id, date desc);
alter table public.body_measures enable row level security;
drop policy if exists "body_measures_owner_all" on public.body_measures;
create policy "body_measures_owner_all" on public.body_measures
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ============================================================
-- v6 追加：力量训练详细记录（含动作、组数、次数、重量、PR）
-- ============================================================
create table if not exists public.strength_records (
  id bigserial primary key,
  user_id uuid not null references auth.users on delete cascade,
  date date not null,
  body_part text,         -- chest/back/shoulder/leg/glute/arm/core
  exercise_id text,       -- 对应前端动作库 id，如 'bench_press'
  exercise_name text,
  sets int default 1,
  reps int default 8,
  weight numeric default 0,    -- kg；自重动作填 0
  rest_sec int default 90,
  cal numeric,
  time text,
  note text,
  created_at timestamptz default now()
);
create index if not exists idx_strength_user_date on public.strength_records (user_id, date desc);
create index if not exists idx_strength_user_exercise on public.strength_records (user_id, exercise_id);
alter table public.strength_records enable row level security;
drop policy if exists "strength_records_owner_all" on public.strength_records;
create policy "strength_records_owner_all" on public.strength_records
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ============================================================
-- v7.1 追加：用户状态（正常/旅游/生病/高强度/生理期/调整期）
-- ============================================================
create table if not exists public.user_status (
  id bigserial primary key,
  user_id uuid not null references auth.users on delete cascade,
  status text not null,        -- normal/travel/sick/intense/period/refeed
  start_date date not null,
  end_date date,               -- null = 进行中
  note text,
  created_at timestamptz default now()
);
create index if not exists idx_status_user_date on public.user_status (user_id, start_date desc);
alter table public.user_status enable row level security;
drop policy if exists "user_status_owner_all" on public.user_status;
create policy "user_status_owner_all" on public.user_status
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ============================================================
-- v13 追加：饮食模块大改造
-- favorite_foods 收藏的食物
-- meal_combos    用户自建套餐（items_json 存 [{name,emoji,cal,p,c,f,qty}]）
-- ============================================================
create table if not exists public.favorite_foods (
  id bigserial primary key,
  user_id uuid not null references auth.users on delete cascade,
  name text not null,
  emoji text,
  cal numeric not null,
  p numeric default 0,
  c numeric default 0,
  f numeric default 0,
  created_at timestamptz default now(),
  unique (user_id, name)
);
create index if not exists idx_fav_user on public.favorite_foods (user_id);
alter table public.favorite_foods enable row level security;
drop policy if exists "favorite_foods_owner_all" on public.favorite_foods;
create policy "favorite_foods_owner_all" on public.favorite_foods
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create table if not exists public.meal_combos (
  id bigserial primary key,
  user_id uuid not null references auth.users on delete cascade,
  name text not null,
  items_json jsonb not null default '[]'::jsonb,
  created_at timestamptz default now()
);
create index if not exists idx_combo_user on public.meal_combos (user_id);
alter table public.meal_combos enable row level security;
drop policy if exists "meal_combos_owner_all" on public.meal_combos;
create policy "meal_combos_owner_all" on public.meal_combos
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
