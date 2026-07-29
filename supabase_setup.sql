-- ================================================================
-- PROPEL MENTORSHIP PLATFORM - FULL SUPABASE DATABASE SCHEMA
-- ================================================================

-- 1. ENUMS & TYPES
CREATE TYPE public.user_role AS ENUM ('mentor', 'mentee');
CREATE TYPE public.connection_status AS ENUM ('pending', 'active', 'rejected', 'ended');
CREATE TYPE public.message_type AS ENUM ('dm', 'group');
CREATE TYPE public.invite_type AS ENUM ('group', 'private');
CREATE TYPE public.rsvp_status AS ENUM ('going', 'maybe', 'declined');

-- 2. PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT NOT NULL,
  first_name TEXT DEFAULT '',
  last_name TEXT DEFAULT '',
  username TEXT UNIQUE,
  gender TEXT,
  role public.user_role DEFAULT 'mentee'::public.user_role,
  avatar_url TEXT,
  onboarding_complete BOOLEAN DEFAULT false,
  calendly_url TEXT,
  notification_prefs JSONB DEFAULT '{"in_app_connections": true, "in_app_messages": true, "in_app_events": true, "in_app_reviews": true}'::jsonb,
  field_visibility JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. MENTOR PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.mentor_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  bio TEXT NOT NULL DEFAULT '',
  expertise_tags TEXT[] DEFAULT '{}',
  work_history JSONB DEFAULT '[]'::jsonb,
  mentorship_style TEXT DEFAULT '',
  max_capacity INT DEFAULT 5,
  current_count INT DEFAULT 0,
  is_at_capacity BOOLEAN DEFAULT false,
  area_of_mentorship TEXT NOT NULL DEFAULT '',
  years_of_experience INT DEFAULT 0,
  portfolio TEXT,
  total_requests INT DEFAULT 0,
  total_responded INT DEFAULT 0,
  total_accepted INT DEFAULT 0,
  response_rate NUMERIC DEFAULT 0.0,
  acceptance_ratio NUMERIC DEFAULT 0.0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. MENTEE PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.mentee_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  bio TEXT NOT NULL DEFAULT '',
  area_of_interest TEXT NOT NULL DEFAULT '',
  aspirations TEXT DEFAULT '',
  learning_goals TEXT[] DEFAULT '{}',
  desired_skills TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. CONNECTIONS TABLE
CREATE TABLE IF NOT EXISTS public.connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mentor_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  mentee_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  status public.connection_status DEFAULT 'pending'::public.connection_status,
  request_message TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. MESSAGES TABLE
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  connection_id UUID REFERENCES public.connections(id) ON DELETE CASCADE,
  group_id UUID,
  content TEXT NOT NULL,
  type public.message_type DEFAULT 'dm'::public.message_type,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. CURRICULA TABLE
CREATE TABLE IF NOT EXISTS public.curricula (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  connection_id UUID UNIQUE REFERENCES public.connections(id) ON DELETE CASCADE,
  goals JSONB DEFAULT '[]'::jsonb,
  milestones JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. EVENTS & RSVPS TABLES
CREATE TABLE IF NOT EXISTS public.events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mentor_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  event_date TIMESTAMPTZ NOT NULL,
  zoom_link TEXT,
  invite_type public.invite_type DEFAULT 'group'::public.invite_type,
  invitee_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.event_rsvps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  status public.rsvp_status DEFAULT 'going'::public.rsvp_status,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(event_id, user_id)
);

-- 9. RATINGS TABLE
CREATE TABLE IF NOT EXISTS public.ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reviewer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  reviewee_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  connection_id UUID REFERENCES public.connections(id) ON DELETE CASCADE,
  score NUMERIC NOT NULL CHECK (score >= 1 AND score <= 5),
  comment TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  link TEXT,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. ROW-LEVEL SECURITY (RLS) POLICIES
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mentor_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mentee_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.curricula ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_rsvps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Allow read for authenticated users on public data
CREATE POLICY "Profiles viewable by authenticated users" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Mentor profiles viewable by all" ON public.mentor_profiles FOR SELECT USING (true);
CREATE POLICY "Mentors can manage own mentor profile" ON public.mentor_profiles FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Mentee profiles viewable by authenticated users" ON public.mentee_profiles FOR SELECT USING (true);
CREATE POLICY "Mentees can manage own mentee profile" ON public.mentee_profiles FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Connections viewable by involved users" ON public.connections FOR SELECT USING (auth.uid() = mentor_id OR auth.uid() = mentee_id);
CREATE POLICY "Users can insert connection request" ON public.connections FOR INSERT WITH CHECK (auth.uid() = mentee_id OR auth.uid() = mentor_id);
CREATE POLICY "Users can update connection status" ON public.connections FOR UPDATE USING (auth.uid() = mentor_id OR auth.uid() = mentee_id);

CREATE POLICY "Messages viewable by channel participants" ON public.messages FOR SELECT USING (true);
CREATE POLICY "Users can insert message" ON public.messages FOR INSERT WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Curricula viewable by connection participants" ON public.curricula FOR SELECT USING (true);
CREATE POLICY "Curricula editable by connection participants" ON public.curricula FOR ALL USING (true);

CREATE POLICY "Events viewable by users" ON public.events FOR SELECT USING (true);
CREATE POLICY "Mentors can manage events" ON public.events FOR ALL USING (auth.uid() = mentor_id);

CREATE POLICY "RSVPs viewable by all" ON public.event_rsvps FOR SELECT USING (true);
CREATE POLICY "Users can manage own RSVP" ON public.event_rsvps FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Ratings viewable by all" ON public.ratings FOR SELECT USING (true);
CREATE POLICY "Reviewer can insert rating" ON public.ratings FOR INSERT WITH CHECK (auth.uid() = reviewer_id);

CREATE POLICY "Notifications viewable by owner" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Owner can update notification read status" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);

-- 12. AUTOMATIC PROFILE CREATION TRIGGER ON SIGNUP
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, first_name, last_name, role)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'full_name', 'User'),
    COALESCE(new.raw_user_meta_data->>'first_name', ''),
    COALESCE(new.raw_user_meta_data->>'last_name', ''),
    COALESCE((new.raw_user_meta_data->>'role')::public.user_role, 'mentee'::public.user_role)
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
