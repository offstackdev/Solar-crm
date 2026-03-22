create extension if not exists "pgcrypto";

create table organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table app_users (
  id uuid primary key,
  org_id uuid not null references organizations(id) on delete cascade,
  full_name text not null,
  email text not null unique,
  phone_number text not null,
  role text not null check (role in ('door_knocker', 'closer', 'manager')),
  assigned_closer_id uuid references app_users(id),
  created_at timestamptz not null default now()
);

create table leads (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references organizations(id) on delete cascade,
  homeowner_full_name text not null,
  phone_number text not null,
  email text not null default '',
  property_address text not null,
  city text not null,
  state text not null,
  zip_code text not null,
  utility_company text not null default '',
  notes text not null default '',
  appointment_at timestamptz,
  lead_source text not null,
  homeowner_type text not null default 'Homeowner',
  average_electric_bill text not null default '',
  roof_type text not null default '',
  shading_notes text not null default '',
  decision_maker_present boolean not null default true,
  spouse_present_required boolean not null default false,
  language_preference text not null default 'English',
  created_by_door_knocker_id uuid not null references app_users(id),
  assigned_closer_id uuid references app_users(id),
  current_status text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table lead_status_history (
  id uuid primary key default gen_random_uuid(),
  lead_id uuid not null references leads(id) on delete cascade,
  status text not null,
  note text not null default '',
  changed_by_user_id uuid not null references app_users(id),
  changed_at timestamptz not null default now()
);

create table app_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references app_users(id) on delete cascade,
  lead_id uuid references leads(id) on delete cascade,
  kind text not null,
  title text not null,
  message text not null,
  created_at timestamptz not null default now(),
  is_read boolean not null default false
);

create index leads_org_status_idx on leads(org_id, current_status);
create index leads_assigned_closer_idx on leads(assigned_closer_id);
create index leads_created_by_idx on leads(created_by_door_knocker_id);
create index notifications_user_idx on app_notifications(user_id, created_at desc);

alter table leads enable row level security;
alter table app_users enable row level security;
alter table lead_status_history enable row level security;
alter table app_notifications enable row level security;

create policy "Managers can read org leads"
on leads for select
using (
  exists (
    select 1 from app_users u
    where u.id = auth.uid()
      and u.org_id = leads.org_id
      and u.role = 'manager'
  )
);

create policy "Door knockers can read own leads"
on leads for select
using (
  created_by_door_knocker_id = auth.uid()
);

create policy "Closers can read assigned leads"
on leads for select
using (
  assigned_closer_id = auth.uid()
);

create policy "Door knockers can insert org leads"
on leads for insert
with check (
  created_by_door_knocker_id = auth.uid()
);

create policy "Managers can update all leads"
on leads for update
using (
  exists (
    select 1 from app_users u
    where u.id = auth.uid()
      and u.org_id = leads.org_id
      and u.role = 'manager'
  )
);

create policy "Door knockers can update own leads"
on leads for update
using (
  created_by_door_knocker_id = auth.uid()
)
with check (
  created_by_door_knocker_id = auth.uid()
);

create policy "Assigned closers can update assigned leads"
on leads for update
using (
  assigned_closer_id = auth.uid()
);

create policy "Users can read related lead status history"
on lead_status_history for select
using (
  exists (
    select 1
    from leads l
    where l.id = lead_status_history.lead_id
      and (
        l.created_by_door_knocker_id = auth.uid()
        or l.assigned_closer_id = auth.uid()
        or exists (
          select 1
          from app_users u
          where u.id = auth.uid()
            and u.org_id = l.org_id
            and u.role = 'manager'
        )
      )
  )
);

create policy "Users can insert related lead status history"
on lead_status_history for insert
with check (
  changed_by_user_id = auth.uid()
  and exists (
    select 1
    from leads l
    where l.id = lead_status_history.lead_id
      and (
        l.created_by_door_knocker_id = auth.uid()
        or l.assigned_closer_id = auth.uid()
        or exists (
          select 1
          from app_users u
          where u.id = auth.uid()
            and u.org_id = l.org_id
            and u.role = 'manager'
        )
      )
  )
);

create policy "Users can read own notifications"
on app_notifications for select
using (
  user_id = auth.uid()
);

create policy "Managers can create org notifications"
on app_notifications for insert
with check (
  exists (
    select 1
    from app_users actor
    join app_users target on target.id = app_notifications.user_id
    where actor.id = auth.uid()
      and actor.role = 'manager'
      and actor.org_id = target.org_id
  )
);

create policy "Users can create notifications for themselves"
on app_notifications for insert
with check (
  user_id = auth.uid()
);

create policy "Users can mark own notifications read"
on app_notifications for update
using (
  user_id = auth.uid()
)
with check (
  user_id = auth.uid()
);
