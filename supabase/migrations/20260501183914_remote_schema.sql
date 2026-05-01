drop extension if exists "pg_net";


  create table "public"."chat_messages" (
    "id" uuid not null default gen_random_uuid(),
    "session_id" uuid not null,
    "role" text not null,
    "content" text not null,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."chat_messages" enable row level security;


  create table "public"."chat_sessions" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "created_at" timestamp with time zone default now(),
    "session_date" date not null default CURRENT_DATE
      );


alter table "public"."chat_sessions" enable row level security;


  create table "public"."journal_entries" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "summary_text" text not null,
    "initial_mood" text,
    "final_mood" text,
    "is_auto_saved" boolean default false,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."journal_entries" enable row level security;


  create table "public"."shop_catalog" (
    "flower_id" uuid not null default gen_random_uuid(),
    "display_name" text not null,
    "seed_cost" integer not null,
    "asset_url" text not null,
    "is_active" boolean not null default true
      );


alter table "public"."shop_catalog" enable row level security;


  create table "public"."user_garden_items" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "item_id" uuid not null,
    "pos_x" double precision not null,
    "pos_y" double precision not null,
    "planted_at" timestamp with time zone default now()
      );


alter table "public"."user_garden_items" enable row level security;


  create table "public"."user_traits" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "trait_key" text not null,
    "trait_value" text not null,
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."user_traits" enable row level security;


  create table "public"."users" (
    "id" uuid not null,
    "seeds" integer default 0,
    "last_checkin" timestamp with time zone,
    "streak" integer default 0,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "last_entry_date" timestamp with time zone,
    "last_seed_update" date
      );


alter table "public"."users" enable row level security;

CREATE UNIQUE INDEX chat_messages_pkey ON public.chat_messages USING btree (id);

CREATE UNIQUE INDEX chat_sessions_pkey ON public.chat_sessions USING btree (id);

CREATE UNIQUE INDEX journal_entries_pkey ON public.journal_entries USING btree (id);

CREATE UNIQUE INDEX shop_catalog_pkey ON public.shop_catalog USING btree (flower_id);

CREATE UNIQUE INDEX user_garden_items_pkey ON public.user_garden_items USING btree (id);

CREATE UNIQUE INDEX user_traits_pkey ON public.user_traits USING btree (id);

CREATE UNIQUE INDEX users_pkey ON public.users USING btree (id);

alter table "public"."chat_messages" add constraint "chat_messages_pkey" PRIMARY KEY using index "chat_messages_pkey";

alter table "public"."chat_sessions" add constraint "chat_sessions_pkey" PRIMARY KEY using index "chat_sessions_pkey";

alter table "public"."journal_entries" add constraint "journal_entries_pkey" PRIMARY KEY using index "journal_entries_pkey";

alter table "public"."shop_catalog" add constraint "shop_catalog_pkey" PRIMARY KEY using index "shop_catalog_pkey";

alter table "public"."user_garden_items" add constraint "user_garden_items_pkey" PRIMARY KEY using index "user_garden_items_pkey";

alter table "public"."user_traits" add constraint "user_traits_pkey" PRIMARY KEY using index "user_traits_pkey";

alter table "public"."users" add constraint "users_pkey" PRIMARY KEY using index "users_pkey";

alter table "public"."chat_messages" add constraint "chat_messages_role_check" CHECK ((role = ANY (ARRAY['user'::text, 'assistant'::text, 'system'::text]))) not valid;

alter table "public"."chat_messages" validate constraint "chat_messages_role_check";

alter table "public"."chat_messages" add constraint "chat_messages_session_id_fkey" FOREIGN KEY (session_id) REFERENCES public.chat_sessions(id) ON DELETE CASCADE not valid;

alter table "public"."chat_messages" validate constraint "chat_messages_session_id_fkey";

alter table "public"."chat_sessions" add constraint "chat_sessions_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE not valid;

alter table "public"."chat_sessions" validate constraint "chat_sessions_user_id_fkey";

alter table "public"."journal_entries" add constraint "journal_entries_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE not valid;

alter table "public"."journal_entries" validate constraint "journal_entries_user_id_fkey";

alter table "public"."user_garden_items" add constraint "user_garden_items_flower_id_fkey" FOREIGN KEY (item_id) REFERENCES public.shop_catalog(flower_id) ON DELETE CASCADE not valid;

alter table "public"."user_garden_items" validate constraint "user_garden_items_flower_id_fkey";

alter table "public"."user_garden_items" add constraint "user_garden_items_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE not valid;

alter table "public"."user_garden_items" validate constraint "user_garden_items_user_id_fkey";

alter table "public"."user_traits" add constraint "user_traits_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE not valid;

alter table "public"."user_traits" validate constraint "user_traits_user_id_fkey";

alter table "public"."users" add constraint "users_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."users" validate constraint "users_id_fkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
begin
  insert into public.users (id, seeds, streak)
  values (new.id, 0, 0);
  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.handle_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$function$
;

grant delete on table "public"."chat_messages" to "anon";

grant insert on table "public"."chat_messages" to "anon";

grant references on table "public"."chat_messages" to "anon";

grant select on table "public"."chat_messages" to "anon";

grant trigger on table "public"."chat_messages" to "anon";

grant truncate on table "public"."chat_messages" to "anon";

grant update on table "public"."chat_messages" to "anon";

grant delete on table "public"."chat_messages" to "authenticated";

grant insert on table "public"."chat_messages" to "authenticated";

grant references on table "public"."chat_messages" to "authenticated";

grant select on table "public"."chat_messages" to "authenticated";

grant trigger on table "public"."chat_messages" to "authenticated";

grant truncate on table "public"."chat_messages" to "authenticated";

grant update on table "public"."chat_messages" to "authenticated";

grant delete on table "public"."chat_messages" to "service_role";

grant insert on table "public"."chat_messages" to "service_role";

grant references on table "public"."chat_messages" to "service_role";

grant select on table "public"."chat_messages" to "service_role";

grant trigger on table "public"."chat_messages" to "service_role";

grant truncate on table "public"."chat_messages" to "service_role";

grant update on table "public"."chat_messages" to "service_role";

grant delete on table "public"."chat_sessions" to "anon";

grant insert on table "public"."chat_sessions" to "anon";

grant references on table "public"."chat_sessions" to "anon";

grant select on table "public"."chat_sessions" to "anon";

grant trigger on table "public"."chat_sessions" to "anon";

grant truncate on table "public"."chat_sessions" to "anon";

grant update on table "public"."chat_sessions" to "anon";

grant delete on table "public"."chat_sessions" to "authenticated";

grant insert on table "public"."chat_sessions" to "authenticated";

grant references on table "public"."chat_sessions" to "authenticated";

grant select on table "public"."chat_sessions" to "authenticated";

grant trigger on table "public"."chat_sessions" to "authenticated";

grant truncate on table "public"."chat_sessions" to "authenticated";

grant update on table "public"."chat_sessions" to "authenticated";

grant delete on table "public"."chat_sessions" to "service_role";

grant insert on table "public"."chat_sessions" to "service_role";

grant references on table "public"."chat_sessions" to "service_role";

grant select on table "public"."chat_sessions" to "service_role";

grant trigger on table "public"."chat_sessions" to "service_role";

grant truncate on table "public"."chat_sessions" to "service_role";

grant update on table "public"."chat_sessions" to "service_role";

grant delete on table "public"."journal_entries" to "anon";

grant insert on table "public"."journal_entries" to "anon";

grant references on table "public"."journal_entries" to "anon";

grant select on table "public"."journal_entries" to "anon";

grant trigger on table "public"."journal_entries" to "anon";

grant truncate on table "public"."journal_entries" to "anon";

grant update on table "public"."journal_entries" to "anon";

grant delete on table "public"."journal_entries" to "authenticated";

grant insert on table "public"."journal_entries" to "authenticated";

grant references on table "public"."journal_entries" to "authenticated";

grant select on table "public"."journal_entries" to "authenticated";

grant trigger on table "public"."journal_entries" to "authenticated";

grant truncate on table "public"."journal_entries" to "authenticated";

grant update on table "public"."journal_entries" to "authenticated";

grant delete on table "public"."journal_entries" to "service_role";

grant insert on table "public"."journal_entries" to "service_role";

grant references on table "public"."journal_entries" to "service_role";

grant select on table "public"."journal_entries" to "service_role";

grant trigger on table "public"."journal_entries" to "service_role";

grant truncate on table "public"."journal_entries" to "service_role";

grant update on table "public"."journal_entries" to "service_role";

grant delete on table "public"."shop_catalog" to "anon";

grant insert on table "public"."shop_catalog" to "anon";

grant references on table "public"."shop_catalog" to "anon";

grant select on table "public"."shop_catalog" to "anon";

grant trigger on table "public"."shop_catalog" to "anon";

grant truncate on table "public"."shop_catalog" to "anon";

grant update on table "public"."shop_catalog" to "anon";

grant delete on table "public"."shop_catalog" to "authenticated";

grant insert on table "public"."shop_catalog" to "authenticated";

grant references on table "public"."shop_catalog" to "authenticated";

grant select on table "public"."shop_catalog" to "authenticated";

grant trigger on table "public"."shop_catalog" to "authenticated";

grant truncate on table "public"."shop_catalog" to "authenticated";

grant update on table "public"."shop_catalog" to "authenticated";

grant delete on table "public"."shop_catalog" to "service_role";

grant insert on table "public"."shop_catalog" to "service_role";

grant references on table "public"."shop_catalog" to "service_role";

grant select on table "public"."shop_catalog" to "service_role";

grant trigger on table "public"."shop_catalog" to "service_role";

grant truncate on table "public"."shop_catalog" to "service_role";

grant update on table "public"."shop_catalog" to "service_role";

grant delete on table "public"."user_garden_items" to "anon";

grant insert on table "public"."user_garden_items" to "anon";

grant references on table "public"."user_garden_items" to "anon";

grant select on table "public"."user_garden_items" to "anon";

grant trigger on table "public"."user_garden_items" to "anon";

grant truncate on table "public"."user_garden_items" to "anon";

grant update on table "public"."user_garden_items" to "anon";

grant delete on table "public"."user_garden_items" to "authenticated";

grant insert on table "public"."user_garden_items" to "authenticated";

grant references on table "public"."user_garden_items" to "authenticated";

grant select on table "public"."user_garden_items" to "authenticated";

grant trigger on table "public"."user_garden_items" to "authenticated";

grant truncate on table "public"."user_garden_items" to "authenticated";

grant update on table "public"."user_garden_items" to "authenticated";

grant delete on table "public"."user_garden_items" to "service_role";

grant insert on table "public"."user_garden_items" to "service_role";

grant references on table "public"."user_garden_items" to "service_role";

grant select on table "public"."user_garden_items" to "service_role";

grant trigger on table "public"."user_garden_items" to "service_role";

grant truncate on table "public"."user_garden_items" to "service_role";

grant update on table "public"."user_garden_items" to "service_role";

grant delete on table "public"."user_traits" to "anon";

grant insert on table "public"."user_traits" to "anon";

grant references on table "public"."user_traits" to "anon";

grant select on table "public"."user_traits" to "anon";

grant trigger on table "public"."user_traits" to "anon";

grant truncate on table "public"."user_traits" to "anon";

grant update on table "public"."user_traits" to "anon";

grant delete on table "public"."user_traits" to "authenticated";

grant insert on table "public"."user_traits" to "authenticated";

grant references on table "public"."user_traits" to "authenticated";

grant select on table "public"."user_traits" to "authenticated";

grant trigger on table "public"."user_traits" to "authenticated";

grant truncate on table "public"."user_traits" to "authenticated";

grant update on table "public"."user_traits" to "authenticated";

grant delete on table "public"."user_traits" to "service_role";

grant insert on table "public"."user_traits" to "service_role";

grant references on table "public"."user_traits" to "service_role";

grant select on table "public"."user_traits" to "service_role";

grant trigger on table "public"."user_traits" to "service_role";

grant truncate on table "public"."user_traits" to "service_role";

grant update on table "public"."user_traits" to "service_role";

grant delete on table "public"."users" to "anon";

grant insert on table "public"."users" to "anon";

grant references on table "public"."users" to "anon";

grant select on table "public"."users" to "anon";

grant trigger on table "public"."users" to "anon";

grant truncate on table "public"."users" to "anon";

grant update on table "public"."users" to "anon";

grant delete on table "public"."users" to "authenticated";

grant insert on table "public"."users" to "authenticated";

grant references on table "public"."users" to "authenticated";

grant select on table "public"."users" to "authenticated";

grant trigger on table "public"."users" to "authenticated";

grant truncate on table "public"."users" to "authenticated";

grant update on table "public"."users" to "authenticated";

grant delete on table "public"."users" to "service_role";

grant insert on table "public"."users" to "service_role";

grant references on table "public"."users" to "service_role";

grant select on table "public"."users" to "service_role";

grant trigger on table "public"."users" to "service_role";

grant truncate on table "public"."users" to "service_role";

grant update on table "public"."users" to "service_role";


  create policy "Users can CRUD messages in their own sessions"
  on "public"."chat_messages"
  as permissive
  for all
  to public
using ((session_id IN ( SELECT chat_sessions.id
   FROM public.chat_sessions
  WHERE (chat_sessions.user_id = auth.uid()))));



  create policy "Enable read access for all users"
  on "public"."chat_sessions"
  as permissive
  for select
  to public
using (true);



  create policy "Users can CRUD own chat sessions"
  on "public"."chat_sessions"
  as permissive
  for all
  to public
using ((auth.uid() = user_id));



  create policy "Users can CRUD own journal entries"
  on "public"."journal_entries"
  as permissive
  for all
  to public
using ((auth.uid() = user_id));



  create policy "Anyone can view active catalog items"
  on "public"."shop_catalog"
  as permissive
  for select
  to public
using ((is_active = true));



  create policy "Users can CRUD own garden items"
  on "public"."user_garden_items"
  as permissive
  for all
  to public
using ((auth.uid() = user_id));



  create policy "Users can CRUD own traits"
  on "public"."user_traits"
  as permissive
  for all
  to public
using ((auth.uid() = user_id));



  create policy "Users can update own profile"
  on "public"."users"
  as permissive
  for update
  to public
using ((auth.uid() = id));



  create policy "Users can view own profile"
  on "public"."users"
  as permissive
  for select
  to public
using ((auth.uid() = id));


CREATE TRIGGER on_journal_entries_updated BEFORE UPDATE ON public.journal_entries FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER on_user_traits_updated BEFORE UPDATE ON public.user_traits FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER on_users_updated BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


