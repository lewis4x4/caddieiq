# CaddieIQ - Claude Code System Prompt

## Project Identity

**Name:** CaddieIQ  
**Type:** React Native (Expo) mobile app + Supabase backend  
**Purpose:** World-class golf scoring, analytics, and AI caddie for avid golfers  
**Targets:** iOS + Android (iOS first release)

---

## Tech Stack (Locked)

| Layer | Technology |
|-------|------------|
| Mobile Framework | React Native + Expo SDK 52+ |
| Language | TypeScript (strict mode) |
| Styling | NativeWind v4 (Tailwind CSS) |
| UI Components | Radix Primitives / Custom (No heavy UI kit) |
| Icons | Lucide React Native |
| Navigation | Expo Router (file-based) |
| Server State | TanStack Query v5 |
| Local State | Zustand |
| Forms | react-hook-form + zod |
| Local DB | expo-sqlite (offline scoring) |
| Maps | react-native-maps |
| Location | expo-location |
| Charts | Victory Native |
| Backend | Supabase (Auth, Postgres, Realtime, Edge Functions, Storage) |
| External API | GolfCourseAPI (proxied via Edge Functions) |
| AI | Claude API via Edge Functions (hybrid caddie) |

---

## Architecture Principles

1. **Offline-first scoring** - Round scoring works without connectivity. Sync when available.
2. **Course cache required** - Can only start offline if course is already cached locally.
3. **Edge Functions as proxy** - All external API calls (GolfCourseAPI, Claude) go through Supabase Edge Functions. No API keys in client.
4. **Snapshot immutability** - Tee data, bag configuration frozen at round start. Analytics remain consistent forever.
5. **Self-scoring in groups** - Each player scores themselves. No conflicts.
6. **Deterministic AI layer** - Club recommendations come from user's own distance data, not LLM invention.
7. **Premium UI/UX** - "Wow" factor strictly required. NativeWind for styling, smooth animations, dark-mode first.

---

## File Structure

```
caddieiq/
├── app/                          # Expo Router screens
│   ├── (auth)/
│   │   ├── login.tsx
│   │   └── _layout.tsx
│   ├── (tabs)/
│   │   ├── home.tsx
│   │   ├── rounds.tsx
│   │   ├── analytics.tsx
│   │   ├── caddie.tsx
│   │   └── _layout.tsx
│   ├── round/
│   │   ├── [id]/
│   │   │   ├── index.tsx         # Active round scoring
│   │   │   ├── hole/[hole].tsx   # Individual hole detail
│   │   │   └── recap.tsx         # Post-round summary
│   │   └── new.tsx               # Round setup
│   ├── course/
│   │   ├── search.tsx
│   │   └── [id].tsx              # Course detail + tee selection
│   ├── equipment/
│   │   ├── index.tsx
│   │   ├── bag.tsx
│   │   └── balls.tsx
│   ├── groups/
│   │   ├── index.tsx
│   │   ├── [id].tsx
│   │   └── invite.tsx
│   ├── settings.tsx
│   ├── index.tsx                 # Entry redirect
│   └── _layout.tsx               # Root layout
├── components/
│   ├── scoring/
│   │   ├── HoleCard.tsx
│   │   ├── QuickScore.tsx
│   │   ├── PenaltyPicker.tsx
│   │   ├── ClubPicker.tsx
│   │   ├── BallSwitcher.tsx
│   │   └── Scorecard.tsx
│   ├── analytics/
│   │   ├── DifferentialChart.tsx
│   │   ├── StrokesLeakChart.tsx
│   │   ├── EquipmentLab.tsx
│   │   └── InsightCard.tsx
│   ├── caddie/
│   │   ├── CaddieChat.tsx
│   │   ├── ClubRecommendation.tsx
│   │   └── DistanceInput.tsx
│   ├── course/
│   │   ├── CourseSearchResult.tsx
│   │   ├── TeeSelector.tsx
│   │   └── HoleInfo.tsx
│   ├── equipment/
│   │   ├── BagEditor.tsx
│   │   ├── ClubCard.tsx
│   │   └── BallCard.tsx
│   ├── groups/
│   │   ├── GroupCard.tsx
│   │   ├── MemberList.tsx
│   │   └── LiveLeaderboard.tsx
│   └── ui/
│       ├── Button.tsx
│       ├── Card.tsx
│       ├── Input.tsx
│       ├── Modal.tsx
│       ├── Chip.tsx
│       └── Loading.tsx
├── hooks/
│   ├── useAuth.ts
│   ├── useRound.ts
│   ├── useCourseSearch.ts
│   ├── useEquipment.ts
│   ├── useAnalytics.ts
│   ├── useCaddie.ts
│   ├── useOfflineSync.ts
│   └── useRealtimeLeaderboard.ts
├── stores/
│   ├── roundStore.ts             # Active round state (Zustand)
│   ├── syncQueueStore.ts         # Offline sync queue
│   └── uiStore.ts                # UI preferences
├── lib/
│   ├── supabase.ts               # Supabase client init
│   ├── sqlite.ts                 # Local SQLite setup
│   ├── sync.ts                   # Sync engine
│   ├── analytics.ts              # Client-side calculations
│   └── constants.ts
├── types/
│   ├── database.ts               # Supabase generated types
│   ├── golfcourse.ts             # GolfCourseAPI types
│   ├── round.ts
│   ├── equipment.ts
│   └── caddie.ts
├── supabase/
│   ├── migrations/
│   │   ├── 00001_initial_schema.sql
│   │   ├── 00002_rls_policies.sql
│   │   ├── 00003_analytics_views.sql
│   │   └── 00004_caddie_functions.sql
│   └── functions/
│       ├── course-search/
│       │   └── index.ts
│       ├── course-detail/
│       │   └── index.ts
│       ├── caddie-recommend/
│       │   └── index.ts
│       └── caddie-chat/
│           └── index.ts
├── assets/
├── app.json
├── package.json
├── tsconfig.json
└── .env.local
```

---

## Database Schema

### Migration 00001: Initial Schema

```sql
-- =============================================================================
-- CADDIEIQ DATABASE SCHEMA
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- IDENTITY & SOCIAL
-- =============================================================================

CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    display_name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    invite_code TEXT UNIQUE DEFAULT SUBSTR(MD5(RANDOM()::TEXT), 1, 8),
    created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE group_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member')),
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(group_id, user_id)
);

-- =============================================================================
-- COURSES (from GolfCourseAPI)
-- =============================================================================

CREATE TABLE courses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    external_course_id TEXT UNIQUE NOT NULL,
    club_name TEXT,
    course_name TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    country TEXT,
    postal_code TEXT,
    phone TEXT,
    website TEXT,
    latitude DECIMAL(10, 7),
    longitude DECIMAL(10, 7),
    raw_data JSONB,
    fetched_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE tees (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
    tee_name TEXT NOT NULL,
    tee_gender_category TEXT NOT NULL CHECK (tee_gender_category IN ('male', 'female')),
    course_rating DECIMAL(4, 1),
    slope_rating INTEGER,
    bogey_rating DECIMAL(4, 1),
    par_total INTEGER,
    total_yards INTEGER,
    total_meters INTEGER,
    number_of_holes INTEGER DEFAULT 18,
    front_course_rating DECIMAL(4, 1),
    front_slope_rating INTEGER,
    front_bogey_rating DECIMAL(4, 1),
    front_par INTEGER,
    front_yards INTEGER,
    back_course_rating DECIMAL(4, 1),
    back_slope_rating INTEGER,
    back_bogey_rating DECIMAL(4, 1),
    back_par INTEGER,
    back_yards INTEGER,
    raw_data JSONB,
    fetched_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(course_id, tee_name, tee_gender_category)
);

CREATE TABLE tee_holes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tee_id UUID REFERENCES tees(id) ON DELETE CASCADE,
    hole_number INTEGER NOT NULL CHECK (hole_number BETWEEN 1 AND 18),
    par INTEGER NOT NULL CHECK (par BETWEEN 3 AND 6),
    yardage INTEGER,
    meters INTEGER,
    handicap INTEGER CHECK (handicap BETWEEN 1 AND 18),
    UNIQUE(tee_id, hole_number)
);

-- Index for course search
CREATE INDEX idx_courses_external_id ON courses(external_course_id);
CREATE INDEX idx_courses_location ON courses(state, city);

-- =============================================================================
-- EQUIPMENT
-- =============================================================================

CREATE TABLE balls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    brand TEXT NOT NULL,
    model TEXT NOT NULL,
    compression INTEGER,
    color TEXT DEFAULT 'white',
    notes TEXT,
    is_preset BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, brand, model, color)
);

CREATE TABLE clubs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    club_type TEXT NOT NULL CHECK (club_type IN (
        'driver', '3_wood', '5_wood', '7_wood',
        'hybrid', '2_iron', '3_iron', '4_iron', '5_iron', '6_iron', '7_iron', '8_iron', '9_iron',
        'pw', 'gw', 'sw', 'lw',
        'putter', 'chipper', 'other'
    )),
    brand TEXT,
    model TEXT,
    loft DECIMAL(4, 1),
    shaft_type TEXT CHECK (shaft_type IN ('steel', 'graphite', 'other')),
    shaft_flex TEXT CHECK (shaft_flex IN ('L', 'A', 'R', 'S', 'X')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE bags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    name TEXT DEFAULT 'My Bag',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE bag_clubs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bag_id UUID REFERENCES bags(id) ON DELETE CASCADE,
    club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
    slot_order INTEGER,
    UNIQUE(bag_id, club_id)
);

-- Bag snapshots (immutable at round start)
CREATE TABLE bag_snapshots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bag_id UUID REFERENCES bags(id) ON DELETE SET NULL,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    snapshot_data JSONB NOT NULL, -- Full bag + clubs at time of snapshot
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- ROUNDS
-- =============================================================================

CREATE TYPE nine_type AS ENUM ('full', 'front', 'back');
CREATE TYPE penalty_type AS ENUM ('ob', 'hazard', 'lost', 'unplayable', 'other');
CREATE TYPE miss_direction AS ENUM ('L', 'C', 'R', 'U');
CREATE TYPE approach_miss AS ENUM ('short', 'long', 'left', 'right', 'center', 'unknown');
CREATE TYPE round_status AS ENUM ('in_progress', 'completed', 'abandoned');

CREATE TABLE rounds (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    group_id UUID REFERENCES groups(id) ON DELETE SET NULL,
    
    -- Course reference
    course_id UUID REFERENCES courses(id) ON DELETE SET NULL,
    tee_id UUID REFERENCES tees(id) ON DELETE SET NULL,
    
    -- Tee snapshot (immutable)
    tee_snapshot JSONB NOT NULL,
    
    -- Round config
    holes_played INTEGER DEFAULT 18 CHECK (holes_played IN (9, 18)),
    nine_type nine_type DEFAULT 'full',
    starting_hole INTEGER DEFAULT 1 CHECK (starting_hole BETWEEN 1 AND 18),
    
    -- Equipment links
    starting_ball_id UUID REFERENCES balls(id) ON DELETE SET NULL,
    bag_snapshot_id UUID REFERENCES bag_snapshots(id) ON DELETE SET NULL,
    
    -- Dates
    played_at DATE NOT NULL DEFAULT CURRENT_DATE,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    
    -- Status
    status round_status DEFAULT 'in_progress',
    
    -- Aggregates (computed on completion)
    total_score INTEGER,
    total_putts INTEGER,
    total_penalties INTEGER,
    score_to_par INTEGER,
    differential DECIMAL(4, 1),
    
    -- Conditions (optional)
    weather_conditions TEXT,
    temperature_f INTEGER,
    wind_conditions TEXT,
    notes TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE hole_scores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    round_id UUID REFERENCES rounds(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    hole_number INTEGER NOT NULL CHECK (hole_number BETWEEN 1 AND 18),
    
    -- Core scoring (required)
    strokes INTEGER CHECK (strokes BETWEEN 1 AND 20),
    putts INTEGER DEFAULT 0 CHECK (putts BETWEEN 0 AND 10),
    penalty_strokes INTEGER DEFAULT 0 CHECK (penalty_strokes BETWEEN 0 AND 10),
    
    -- Stats (optional but valuable)
    fairway_hit BOOLEAN, -- NULL for par 3s
    gir BOOLEAN,
    
    -- Penalty detail (optional)
    primary_penalty_type penalty_type,
    
    -- Club tracking (optional)
    tee_club_id UUID REFERENCES clubs(id) ON DELETE SET NULL,
    approach_club_id UUID REFERENCES clubs(id) ON DELETE SET NULL,
    
    -- Miss patterns (optional)
    tee_miss miss_direction,
    approach_miss approach_miss,
    
    -- Short game (optional)
    up_and_down_attempt BOOLEAN,
    up_and_down_success BOOLEAN,
    sand_attempt BOOLEAN,
    sand_success BOOLEAN,
    
    -- Ball used this hole (if switched)
    ball_id UUID REFERENCES balls(id) ON DELETE SET NULL,
    
    notes TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(round_id, user_id, hole_number)
);

-- Ball switch events
CREATE TABLE round_ball_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    round_id UUID REFERENCES rounds(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    hole_number INTEGER NOT NULL CHECK (hole_number BETWEEN 1 AND 18),
    ball_id UUID REFERENCES balls(id) ON DELETE SET NULL,
    reason TEXT CHECK (reason IN ('lost', 'scuffed', 'changed', 'other')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for round queries
CREATE INDEX idx_rounds_user ON rounds(user_id);
CREATE INDEX idx_rounds_played_at ON rounds(played_at DESC);
CREATE INDEX idx_rounds_status ON rounds(status);
CREATE INDEX idx_hole_scores_round ON hole_scores(round_id);

-- =============================================================================
-- AI CADDIE - DISTANCE PROFILES
-- =============================================================================

CREATE TABLE distance_observations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
    round_id UUID REFERENCES rounds(id) ON DELETE SET NULL,
    hole_number INTEGER,
    
    distance_yards INTEGER NOT NULL,
    lie TEXT DEFAULT 'fairway' CHECK (lie IN ('tee', 'fairway', 'rough', 'sand', 'other')),
    shot_type TEXT DEFAULT 'full' CHECK (shot_type IN ('full', 'partial', 'punch', 'flop')),
    
    -- Outcome relative to target
    result TEXT CHECK (result IN ('short', 'pin_high', 'long', 'unknown')),
    
    -- Optional: actual carry/total if known
    carry_yards INTEGER,
    total_yards INTEGER,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Materialized view for club distance profiles (refresh after round completion)
CREATE MATERIALIZED VIEW club_distance_profiles AS
SELECT 
    user_id,
    club_id,
    lie,
    shot_type,
    COUNT(*) as sample_size,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY distance_yards) as median_yards,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY distance_yards) as p25_yards,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY distance_yards) as p75_yards,
    AVG(distance_yards) as avg_yards,
    STDDEV(distance_yards) as stddev_yards
FROM distance_observations
GROUP BY user_id, club_id, lie, shot_type;

CREATE UNIQUE INDEX idx_club_distance_profiles ON club_distance_profiles(user_id, club_id, lie, shot_type);

-- =============================================================================
-- ANALYTICS SUMMARIES
-- =============================================================================

-- Per-round summary (computed on round completion)
CREATE TABLE round_summaries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    round_id UUID UNIQUE REFERENCES rounds(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    
    -- Scoring
    gross_score INTEGER,
    score_to_par INTEGER,
    differential DECIMAL(4, 1),
    
    -- Hole counts
    eagles INTEGER DEFAULT 0,
    birdies INTEGER DEFAULT 0,
    pars INTEGER DEFAULT 0,
    bogeys INTEGER DEFAULT 0,
    double_plus INTEGER DEFAULT 0,
    
    -- Stats
    fairways_hit INTEGER,
    fairways_possible INTEGER,
    greens_hit INTEGER,
    greens_possible INTEGER,
    total_putts INTEGER,
    putts_per_gir DECIMAL(3, 1),
    three_putts INTEGER DEFAULT 0,
    
    -- Penalties
    penalty_strokes INTEGER DEFAULT 0,
    ob_count INTEGER DEFAULT 0,
    hazard_count INTEGER DEFAULT 0,
    
    -- Short game
    up_and_down_attempts INTEGER DEFAULT 0,
    up_and_down_successes INTEGER DEFAULT 0,
    sand_attempts INTEGER DEFAULT 0,
    sand_successes INTEGER DEFAULT 0,
    
    -- By nine
    front_score INTEGER,
    back_score INTEGER,
    
    computed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_round_summaries_user ON round_summaries(user_id);

-- =============================================================================
-- CACHED COURSES (for offline access)
-- =============================================================================

CREATE TABLE user_course_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
    last_played TIMESTAMPTZ,
    times_played INTEGER DEFAULT 0,
    is_favorite BOOLEAN DEFAULT FALSE,
    cached_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, course_id)
);

-- =============================================================================
-- SYNC TRACKING
-- =============================================================================

CREATE TABLE sync_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    entity_type TEXT NOT NULL,
    entity_id UUID NOT NULL,
    action TEXT NOT NULL CHECK (action IN ('create', 'update', 'delete')),
    payload JSONB,
    synced_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_sync_log_pending ON sync_log(user_id, synced_at) WHERE synced_at IS NULL;
```

### Migration 00002: RLS Policies

```sql
-- =============================================================================
-- ROW LEVEL SECURITY POLICIES
-- =============================================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE tees ENABLE ROW LEVEL SECURITY;
ALTER TABLE tee_holes ENABLE ROW LEVEL SECURITY;
ALTER TABLE balls ENABLE ROW LEVEL SECURITY;
ALTER TABLE clubs ENABLE ROW LEVEL SECURITY;
ALTER TABLE bags ENABLE ROW LEVEL SECURITY;
ALTER TABLE bag_clubs ENABLE ROW LEVEL SECURITY;
ALTER TABLE bag_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE rounds ENABLE ROW LEVEL SECURITY;
ALTER TABLE hole_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE round_ball_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE distance_observations ENABLE ROW LEVEL SECURITY;
ALTER TABLE round_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_course_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_log ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- PROFILES
-- =============================================================================

CREATE POLICY "Users can view own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can view profiles of group members"
    ON profiles FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM group_members gm1
            JOIN group_members gm2 ON gm1.group_id = gm2.group_id
            WHERE gm1.user_id = auth.uid() AND gm2.user_id = profiles.id
        )
    );

-- =============================================================================
-- GROUPS
-- =============================================================================

CREATE POLICY "Users can view groups they belong to"
    ON groups FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM group_members
            WHERE group_id = groups.id AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create groups"
    ON groups FOR INSERT
    WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Group owners can update groups"
    ON groups FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM group_members
            WHERE group_id = groups.id AND user_id = auth.uid() AND role = 'owner'
        )
    );

-- =============================================================================
-- GROUP MEMBERS
-- =============================================================================

CREATE POLICY "Users can view members of their groups"
    ON group_members FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM group_members gm
            WHERE gm.group_id = group_members.group_id AND gm.user_id = auth.uid()
        )
    );

CREATE POLICY "Group admins can manage members"
    ON group_members FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM group_members gm
            WHERE gm.group_id = group_members.group_id 
            AND gm.user_id = auth.uid() 
            AND gm.role IN ('owner', 'admin')
        )
    );

-- =============================================================================
-- COURSES (public read, authenticated write via functions)
-- =============================================================================

CREATE POLICY "Anyone can view courses"
    ON courses FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Anyone can view tees"
    ON tees FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Anyone can view tee holes"
    ON tee_holes FOR SELECT
    TO authenticated
    USING (true);

-- =============================================================================
-- EQUIPMENT
-- =============================================================================

CREATE POLICY "Users can manage own balls"
    ON balls FOR ALL
    USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own clubs"
    ON clubs FOR ALL
    USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own bags"
    ON bags FOR ALL
    USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own bag clubs"
    ON bag_clubs FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM bags WHERE bags.id = bag_clubs.bag_id AND bags.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can manage own bag snapshots"
    ON bag_snapshots FOR ALL
    USING (auth.uid() = user_id);

-- =============================================================================
-- ROUNDS
-- =============================================================================

-- Own rounds
CREATE POLICY "Users can manage own rounds"
    ON rounds FOR ALL
    USING (auth.uid() = user_id);

-- View group rounds
CREATE POLICY "Users can view group rounds"
    ON rounds FOR SELECT
    USING (
        group_id IS NOT NULL AND EXISTS (
            SELECT 1 FROM group_members
            WHERE group_id = rounds.group_id AND user_id = auth.uid()
        )
    );

-- =============================================================================
-- HOLE SCORES
-- =============================================================================

CREATE POLICY "Users can manage own hole scores"
    ON hole_scores FOR ALL
    USING (auth.uid() = user_id);

CREATE POLICY "Users can view group hole scores"
    ON hole_scores FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM rounds r
            JOIN group_members gm ON r.group_id = gm.group_id
            WHERE r.id = hole_scores.round_id AND gm.user_id = auth.uid()
        )
    );

-- =============================================================================
-- BALL EVENTS
-- =============================================================================

CREATE POLICY "Users can manage own ball events"
    ON round_ball_events FOR ALL
    USING (auth.uid() = user_id);

-- =============================================================================
-- DISTANCE OBSERVATIONS
-- =============================================================================

CREATE POLICY "Users can manage own distance observations"
    ON distance_observations FOR ALL
    USING (auth.uid() = user_id);

-- =============================================================================
-- ROUND SUMMARIES
-- =============================================================================

CREATE POLICY "Users can view own summaries"
    ON round_summaries FOR SELECT
    USING (auth.uid() = user_id);

-- =============================================================================
-- USER COURSE CACHE
-- =============================================================================

CREATE POLICY "Users can manage own course cache"
    ON user_course_cache FOR ALL
    USING (auth.uid() = user_id);

-- =============================================================================
-- SYNC LOG
-- =============================================================================

CREATE POLICY "Users can manage own sync log"
    ON sync_log FOR ALL
    USING (auth.uid() = user_id);
```

### Migration 00003: Analytics Views

```sql
-- =============================================================================
-- ANALYTICS VIEWS
-- =============================================================================

-- Rolling differential (last N rounds)
CREATE OR REPLACE VIEW user_rolling_stats AS
SELECT 
    user_id,
    COUNT(*) FILTER (WHERE rn <= 20) as rounds_last_20,
    AVG(differential) FILTER (WHERE rn <= 20) as avg_differential_20,
    AVG(differential) FILTER (WHERE rn <= 10) as avg_differential_10,
    AVG(differential) FILTER (WHERE rn <= 5) as avg_differential_5,
    STDDEV(differential) FILTER (WHERE rn <= 20) as volatility_20,
    -- Handicap-style: best 8 of last 20
    (
        SELECT AVG(diff) FROM (
            SELECT differential as diff
            FROM (
                SELECT differential, ROW_NUMBER() OVER (ORDER BY differential ASC) as best_rn
                FROM rounds r2
                WHERE r2.user_id = rounds.user_id 
                AND r2.status = 'completed'
                AND r2.differential IS NOT NULL
                ORDER BY played_at DESC
                LIMIT 20
            ) best20
            ORDER BY diff ASC
            LIMIT 8
        ) best8
    ) as handicap_index
FROM (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY played_at DESC) as rn
    FROM rounds
    WHERE status = 'completed' AND differential IS NOT NULL
) rounds
GROUP BY user_id;

-- Strokes leak analysis
CREATE OR REPLACE VIEW user_strokes_leak AS
SELECT 
    rs.user_id,
    COUNT(*) as rounds_analyzed,
    
    -- Putting
    AVG(rs.total_putts::DECIMAL / NULLIF(rs.greens_possible, 0)) as avg_putts_per_hole,
    AVG(rs.putts_per_gir) as avg_putts_per_gir,
    SUM(rs.three_putts)::DECIMAL / NULLIF(SUM(rs.greens_hit), 0) as three_putt_rate,
    
    -- Penalties
    AVG(rs.penalty_strokes) as avg_penalties_per_round,
    SUM(rs.ob_count)::DECIMAL / COUNT(*) as ob_per_round,
    
    -- Accuracy
    SUM(rs.fairways_hit)::DECIMAL / NULLIF(SUM(rs.fairways_possible), 0) as fir_pct,
    SUM(rs.greens_hit)::DECIMAL / NULLIF(SUM(rs.greens_possible), 0) as gir_pct,
    
    -- Short game
    SUM(rs.up_and_down_successes)::DECIMAL / NULLIF(SUM(rs.up_and_down_attempts), 0) as up_and_down_pct,
    SUM(rs.sand_successes)::DECIMAL / NULLIF(SUM(rs.sand_attempts), 0) as sand_save_pct,
    
    -- Scoring distribution
    AVG(rs.double_plus) as avg_blowup_holes
    
FROM round_summaries rs
JOIN rounds r ON rs.round_id = r.id
WHERE r.status = 'completed'
AND r.played_at >= NOW() - INTERVAL '90 days'
GROUP BY rs.user_id;

-- Equipment performance
CREATE OR REPLACE VIEW equipment_performance AS
SELECT 
    hs.user_id,
    hs.tee_club_id as club_id,
    c.club_type,
    c.brand,
    c.model,
    'tee' as usage_type,
    COUNT(*) as uses,
    SUM(CASE WHEN hs.fairway_hit THEN 1 ELSE 0 END)::DECIMAL / 
        NULLIF(COUNT(*) FILTER (WHERE hs.fairway_hit IS NOT NULL), 0) as success_rate,
    SUM(hs.penalty_strokes)::DECIMAL / COUNT(*) as penalty_rate,
    AVG(hs.strokes) as avg_strokes_when_used
FROM hole_scores hs
JOIN clubs c ON hs.tee_club_id = c.id
WHERE hs.tee_club_id IS NOT NULL
GROUP BY hs.user_id, hs.tee_club_id, c.club_type, c.brand, c.model

UNION ALL

SELECT 
    hs.user_id,
    hs.approach_club_id as club_id,
    c.club_type,
    c.brand,
    c.model,
    'approach' as usage_type,
    COUNT(*) as uses,
    SUM(CASE WHEN hs.gir THEN 1 ELSE 0 END)::DECIMAL / 
        NULLIF(COUNT(*), 0) as success_rate,
    0 as penalty_rate,
    AVG(hs.strokes) as avg_strokes_when_used
FROM hole_scores hs
JOIN clubs c ON hs.approach_club_id = c.id
WHERE hs.approach_club_id IS NOT NULL
GROUP BY hs.user_id, hs.approach_club_id, c.club_type, c.brand, c.model;

-- Ball performance
CREATE OR REPLACE VIEW ball_performance AS
WITH round_balls AS (
    SELECT 
        r.id as round_id,
        r.user_id,
        COALESCE(
            (SELECT ball_id FROM round_ball_events rbe 
             WHERE rbe.round_id = r.id ORDER BY hole_number DESC LIMIT 1),
            r.starting_ball_id
        ) as primary_ball_id,
        r.differential,
        r.total_score,
        r.total_penalties
    FROM rounds r
    WHERE r.status = 'completed'
)
SELECT 
    rb.user_id,
    rb.primary_ball_id as ball_id,
    b.brand,
    b.model,
    COUNT(*) as rounds_played,
    AVG(rb.differential) as avg_differential,
    AVG(rb.total_score) as avg_score,
    AVG(rb.total_penalties) as avg_penalties
FROM round_balls rb
JOIN balls b ON rb.primary_ball_id = b.id
GROUP BY rb.user_id, rb.primary_ball_id, b.brand, b.model
HAVING COUNT(*) >= 3;

-- Course performance
CREATE OR REPLACE VIEW course_performance AS
SELECT 
    r.user_id,
    r.course_id,
    c.club_name,
    c.course_name,
    COUNT(*) as times_played,
    AVG(r.differential) as avg_differential,
    MIN(r.total_score) as best_score,
    AVG(r.total_score) as avg_score,
    MAX(r.played_at) as last_played
FROM rounds r
JOIN courses c ON r.course_id = c.id
WHERE r.status = 'completed'
GROUP BY r.user_id, r.course_id, c.club_name, c.course_name;
```

### Migration 00004: Caddie Functions

```sql
-- =============================================================================
-- AI CADDIE FUNCTIONS
-- =============================================================================

-- Get club recommendation for a given distance
CREATE OR REPLACE FUNCTION get_club_recommendation(
    p_user_id UUID,
    p_distance_yards INTEGER,
    p_lie TEXT DEFAULT 'fairway',
    p_shot_type TEXT DEFAULT 'full'
)
RETURNS TABLE (
    club_id UUID,
    club_type TEXT,
    brand TEXT,
    model TEXT,
    median_yards DECIMAL,
    confidence TEXT,
    sample_size BIGINT,
    recommendation_type TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH user_clubs AS (
        SELECT 
            cdp.club_id,
            c.club_type,
            c.brand,
            c.model,
            cdp.median_yards,
            cdp.p25_yards,
            cdp.p75_yards,
            cdp.sample_size,
            ABS(cdp.median_yards - p_distance_yards) as distance_diff
        FROM club_distance_profiles cdp
        JOIN clubs c ON cdp.club_id = c.id
        WHERE cdp.user_id = p_user_id
        AND cdp.lie = p_lie
        AND cdp.shot_type = p_shot_type
        AND cdp.sample_size >= 3
    )
    SELECT 
        uc.club_id,
        uc.club_type,
        uc.brand,
        uc.model,
        uc.median_yards,
        CASE 
            WHEN uc.sample_size >= 10 THEN 'high'
            WHEN uc.sample_size >= 5 THEN 'medium'
            ELSE 'low'
        END as confidence,
        uc.sample_size,
        CASE 
            WHEN rank_asc = 1 THEN 'recommended'
            WHEN rank_asc = 2 AND uc.median_yards > p_distance_yards THEN 'safe'
            WHEN rank_desc = 2 AND uc.median_yards < p_distance_yards THEN 'aggressive'
            ELSE 'alternative'
        END as recommendation_type
    FROM (
        SELECT 
            *,
            ROW_NUMBER() OVER (ORDER BY distance_diff ASC) as rank_asc,
            ROW_NUMBER() OVER (ORDER BY distance_diff DESC) as rank_desc
        FROM user_clubs
    ) uc
    WHERE uc.rank_asc <= 3
    ORDER BY uc.distance_diff ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Compute round summary after completion
CREATE OR REPLACE FUNCTION compute_round_summary(p_round_id UUID)
RETURNS void AS $$
DECLARE
    v_user_id UUID;
    v_course_rating DECIMAL;
    v_slope_rating INTEGER;
    v_par_total INTEGER;
BEGIN
    -- Get round info
    SELECT 
        user_id,
        (tee_snapshot->>'course_rating')::DECIMAL,
        (tee_snapshot->>'slope_rating')::INTEGER,
        (tee_snapshot->>'par_total')::INTEGER
    INTO v_user_id, v_course_rating, v_slope_rating, v_par_total
    FROM rounds
    WHERE id = p_round_id;
    
    -- Upsert summary
    INSERT INTO round_summaries (
        round_id, user_id, gross_score, score_to_par, differential,
        eagles, birdies, pars, bogeys, double_plus,
        fairways_hit, fairways_possible, greens_hit, greens_possible,
        total_putts, putts_per_gir, three_putts,
        penalty_strokes, ob_count, hazard_count,
        up_and_down_attempts, up_and_down_successes,
        sand_attempts, sand_successes,
        front_score, back_score
    )
    SELECT 
        p_round_id,
        v_user_id,
        SUM(strokes) as gross_score,
        SUM(strokes) - v_par_total as score_to_par,
        ROUND(((SUM(strokes) - v_course_rating) * 113.0 / v_slope_rating)::DECIMAL, 1) as differential,
        COUNT(*) FILTER (WHERE strokes <= th.par - 2) as eagles,
        COUNT(*) FILTER (WHERE strokes = th.par - 1) as birdies,
        COUNT(*) FILTER (WHERE strokes = th.par) as pars,
        COUNT(*) FILTER (WHERE strokes = th.par + 1) as bogeys,
        COUNT(*) FILTER (WHERE strokes >= th.par + 2) as double_plus,
        COUNT(*) FILTER (WHERE fairway_hit = true) as fairways_hit,
        COUNT(*) FILTER (WHERE fairway_hit IS NOT NULL) as fairways_possible,
        COUNT(*) FILTER (WHERE gir = true) as greens_hit,
        COUNT(*) as greens_possible,
        SUM(putts) as total_putts,
        ROUND(SUM(putts)::DECIMAL / NULLIF(COUNT(*) FILTER (WHERE gir = true), 0), 1) as putts_per_gir,
        COUNT(*) FILTER (WHERE putts >= 3) as three_putts,
        SUM(penalty_strokes) as penalty_strokes,
        COUNT(*) FILTER (WHERE primary_penalty_type = 'ob') as ob_count,
        COUNT(*) FILTER (WHERE primary_penalty_type = 'hazard') as hazard_count,
        COUNT(*) FILTER (WHERE up_and_down_attempt = true) as up_and_down_attempts,
        COUNT(*) FILTER (WHERE up_and_down_success = true) as up_and_down_successes,
        COUNT(*) FILTER (WHERE sand_attempt = true) as sand_attempts,
        COUNT(*) FILTER (WHERE sand_success = true) as sand_successes,
        SUM(strokes) FILTER (WHERE hole_number <= 9) as front_score,
        SUM(strokes) FILTER (WHERE hole_number >= 10) as back_score
    FROM hole_scores hs
    JOIN (
        SELECT 
            (h->>'hole_number')::INTEGER as hole_number,
            (h->>'par')::INTEGER as par
        FROM rounds r, jsonb_array_elements(r.tee_snapshot->'holes') as h
        WHERE r.id = p_round_id
    ) th ON hs.hole_number = th.hole_number
    WHERE hs.round_id = p_round_id
    GROUP BY hs.round_id
    ON CONFLICT (round_id) DO UPDATE SET
        gross_score = EXCLUDED.gross_score,
        score_to_par = EXCLUDED.score_to_par,
        differential = EXCLUDED.differential,
        eagles = EXCLUDED.eagles,
        birdies = EXCLUDED.birdies,
        pars = EXCLUDED.pars,
        bogeys = EXCLUDED.bogeys,
        double_plus = EXCLUDED.double_plus,
        fairways_hit = EXCLUDED.fairways_hit,
        fairways_possible = EXCLUDED.fairways_possible,
        greens_hit = EXCLUDED.greens_hit,
        greens_possible = EXCLUDED.greens_possible,
        total_putts = EXCLUDED.total_putts,
        putts_per_gir = EXCLUDED.putts_per_gir,
        three_putts = EXCLUDED.three_putts,
        penalty_strokes = EXCLUDED.penalty_strokes,
        ob_count = EXCLUDED.ob_count,
        hazard_count = EXCLUDED.hazard_count,
        up_and_down_attempts = EXCLUDED.up_and_down_attempts,
        up_and_down_successes = EXCLUDED.up_and_down_successes,
        sand_attempts = EXCLUDED.sand_attempts,
        sand_successes = EXCLUDED.sand_successes,
        front_score = EXCLUDED.front_score,
        back_score = EXCLUDED.back_score,
        computed_at = NOW();
    
    -- Update round aggregates
    UPDATE rounds SET
        total_score = (SELECT gross_score FROM round_summaries WHERE round_id = p_round_id),
        score_to_par = (SELECT rs.score_to_par FROM round_summaries rs WHERE rs.round_id = p_round_id),
        differential = (SELECT rs.differential FROM round_summaries rs WHERE rs.round_id = p_round_id),
        total_putts = (SELECT rs.total_putts FROM round_summaries rs WHERE rs.round_id = p_round_id),
        total_penalties = (SELECT rs.penalty_strokes FROM round_summaries rs WHERE rs.round_id = p_round_id),
        updated_at = NOW()
    WHERE id = p_round_id;
    
    -- Refresh distance profiles
    REFRESH MATERIALIZED VIEW CONCURRENTLY club_distance_profiles;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to compute summary on round completion
CREATE OR REPLACE FUNCTION on_round_completed()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
        PERFORM compute_round_summary(NEW.id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_round_completed
    AFTER UPDATE OF status ON rounds
    FOR EACH ROW
    EXECUTE FUNCTION on_round_completed();
```

---

## Edge Functions

### course-search/index.ts

```typescript
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const GOLF_API_BASE = "https://api.golfcourseapi.com/v1";
const GOLF_API_KEY = Deno.env.get("GOLF_COURSE_API_KEY")!;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface CourseSearchResult {
  id: string;
  club_name: string;
  course_name: string;
  location: {
    address: string;
    city: string;
    state: string;
    country: string;
    latitude: number;
    longitude: number;
  };
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { query } = await req.json();

    if (!query || query.length < 2) {
      return new Response(
        JSON.stringify({ error: "Query must be at least 2 characters" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Call GolfCourseAPI
    const apiUrl = `${GOLF_API_BASE}/search?search_query=${encodeURIComponent(query)}`;
    const apiResponse = await fetch(apiUrl, {
      headers: {
        Authorization: `Key ${GOLF_API_KEY}`,
      },
    });

    if (!apiResponse.ok) {
      throw new Error(`GolfCourseAPI error: ${apiResponse.status}`);
    }

    const data = await apiResponse.json();
    const courses: CourseSearchResult[] = data.courses || [];

    // Optionally cache course stubs in Supabase
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Upsert course stubs (non-blocking)
    const courseStubs = courses.map((c) => ({
      external_course_id: c.id,
      club_name: c.club_name,
      course_name: c.course_name,
      address: c.location?.address,
      city: c.location?.city,
      state: c.location?.state,
      country: c.location?.country,
      latitude: c.location?.latitude,
      longitude: c.location?.longitude,
      fetched_at: new Date().toISOString(),
    }));

    if (courseStubs.length > 0) {
      supabase
        .from("courses")
        .upsert(courseStubs, { onConflict: "external_course_id", ignoreDuplicates: false })
        .then(() => {});
    }

    return new Response(JSON.stringify({ courses }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Course search error:", error);
    return new Response(
      JSON.stringify({ error: "Failed to search courses" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
```

### course-detail/index.ts

```typescript
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const GOLF_API_BASE = "https://api.golfcourseapi.com/v1";
const GOLF_API_KEY = Deno.env.get("GOLF_COURSE_API_KEY")!;
const CACHE_DAYS = 30;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { courseId, forceRefresh } = await req.json();

    if (!courseId) {
      return new Response(
        JSON.stringify({ error: "courseId is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Check cache first
    if (!forceRefresh) {
      const { data: cached } = await supabase
        .from("courses")
        .select(`
          *,
          tees (
            *,
            tee_holes (*)
          )
        `)
        .eq("external_course_id", courseId)
        .single();

      if (cached && cached.tees?.length > 0) {
        const cacheAge = Date.now() - new Date(cached.fetched_at).getTime();
        if (cacheAge < CACHE_DAYS * 24 * 60 * 60 * 1000) {
          return new Response(JSON.stringify({ course: cached, fromCache: true }), {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          });
        }
      }
    }

    // Fetch from GolfCourseAPI
    const apiUrl = `${GOLF_API_BASE}/courses/${courseId}`;
    const apiResponse = await fetch(apiUrl, {
      headers: {
        Authorization: `Key ${GOLF_API_KEY}`,
      },
    });

    if (!apiResponse.ok) {
      throw new Error(`GolfCourseAPI error: ${apiResponse.status}`);
    }

    const courseData = await apiResponse.json();

    // Upsert course
    const { data: course, error: courseError } = await supabase
      .from("courses")
      .upsert(
        {
          external_course_id: courseData.id,
          club_name: courseData.club_name,
          course_name: courseData.course_name,
          address: courseData.location?.address,
          city: courseData.location?.city,
          state: courseData.location?.state,
          country: courseData.location?.country,
          postal_code: courseData.location?.postal_code,
          phone: courseData.contact?.phone,
          website: courseData.contact?.website,
          latitude: courseData.location?.coordinates?.latitude,
          longitude: courseData.location?.coordinates?.longitude,
          raw_data: courseData,
          fetched_at: new Date().toISOString(),
        },
        { onConflict: "external_course_id" }
      )
      .select()
      .single();

    if (courseError) throw courseError;

    // Process tees (male + female)
    const allTees = [
      ...(courseData.tees?.male || []).map((t: any) => ({ ...t, gender: "male" })),
      ...(courseData.tees?.female || []).map((t: any) => ({ ...t, gender: "female" })),
    ];

    for (const tee of allTees) {
      const { data: teeRow, error: teeError } = await supabase
        .from("tees")
        .upsert(
          {
            course_id: course.id,
            tee_name: tee.tee_name,
            tee_gender_category: tee.gender,
            course_rating: tee.course_rating,
            slope_rating: tee.slope_rating,
            bogey_rating: tee.bogey_rating,
            par_total: tee.par_total,
            total_yards: tee.total_yards,
            total_meters: tee.total_meters,
            number_of_holes: tee.number_of_holes || 18,
            front_course_rating: tee.front_course_rating,
            front_slope_rating: tee.front_slope_rating,
            front_bogey_rating: tee.front_bogey_rating,
            front_par: tee.front_par,
            front_yards: tee.front_yards,
            back_course_rating: tee.back_course_rating,
            back_slope_rating: tee.back_slope_rating,
            back_bogey_rating: tee.back_bogey_rating,
            back_par: tee.back_par,
            back_yards: tee.back_yards,
            raw_data: tee,
            fetched_at: new Date().toISOString(),
          },
          { onConflict: "course_id,tee_name,tee_gender_category" }
        )
        .select()
        .single();

      if (teeError) {
        console.error("Tee upsert error:", teeError);
        continue;
      }

      // Delete existing holes for this tee, then insert fresh
      await supabase.from("tee_holes").delete().eq("tee_id", teeRow.id);

      const holes = (tee.holes || []).map((h: any, idx: number) => ({
        tee_id: teeRow.id,
        hole_number: h.hole_number || idx + 1,
        par: h.par,
        yardage: h.yardage,
        meters: h.meters,
        handicap: h.handicap,
      }));

      if (holes.length > 0) {
        await supabase.from("tee_holes").insert(holes);
      }
    }

    // Fetch complete course with tees
    const { data: fullCourse } = await supabase
      .from("courses")
      .select(`
        *,
        tees (
          *,
          tee_holes (*)
        )
      `)
      .eq("id", course.id)
      .single();

    return new Response(JSON.stringify({ course: fullCourse, fromCache: false }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Course detail error:", error);
    return new Response(
      JSON.stringify({ error: "Failed to fetch course details" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
```

### caddie-recommend/index.ts

```typescript
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    );

    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { distance, lie = "fairway", shotType = "full" } = await req.json();

    if (!distance || distance < 1 || distance > 400) {
      return new Response(
        JSON.stringify({ error: "Invalid distance" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Call the Postgres function
    const { data: recommendations, error } = await supabase.rpc("get_club_recommendation", {
      p_user_id: user.id,
      p_distance_yards: distance,
      p_lie: lie,
      p_shot_type: shotType,
    });

    if (error) throw error;

    // If no recommendations (new user), return default guidance
    if (!recommendations || recommendations.length === 0) {
      return new Response(
        JSON.stringify({
          recommendations: [],
          message: "Not enough data yet. Keep logging your shots to build your distance profile.",
          fallback: {
            distance,
            suggestedClub: estimateClubFromDistance(distance),
          },
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({
        recommendations,
        distance,
        lie,
        shotType,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Caddie recommend error:", error);
    return new Response(
      JSON.stringify({ error: "Failed to get recommendation" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

// Fallback for new users without data
function estimateClubFromDistance(distance: number): string {
  if (distance >= 200) return "3_wood or driver";
  if (distance >= 180) return "5_wood or hybrid";
  if (distance >= 170) return "4_iron or hybrid";
  if (distance >= 160) return "5_iron";
  if (distance >= 150) return "6_iron";
  if (distance >= 140) return "7_iron";
  if (distance >= 130) return "8_iron";
  if (distance >= 120) return "9_iron";
  if (distance >= 100) return "pw";
  if (distance >= 80) return "gw";
  return "sw or lw";
}
```

### caddie-chat/index.ts

```typescript
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import Anthropic from "https://esm.sh/@anthropic-ai/sdk@0.24.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const anthropic = new Anthropic({
  apiKey: Deno.env.get("ANTHROPIC_API_KEY")!,
});

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    );

    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { message, context } = await req.json();

    // Fetch user's recent stats for context
    const { data: stats } = await supabase
      .from("user_strokes_leak")
      .select("*")
      .eq("user_id", user.id)
      .single();

    const { data: rollingStats } = await supabase
      .from("user_rolling_stats")
      .select("*")
      .eq("user_id", user.id)
      .single();

    // Fetch club distance profiles
    const { data: clubProfiles } = await supabase
      .from("club_distance_profiles")
      .select("*")
      .eq("user_id", user.id);

    // Build system prompt with user's data
    const systemPrompt = `You are CaddieIQ, an AI golf caddie assistant. You help golfers make better decisions on the course and understand their game.

USER'S GOLF PROFILE:
${rollingStats ? `
- Handicap-style index: ${rollingStats.handicap_index?.toFixed(1) || "Not enough data"}
- Avg differential (last 10): ${rollingStats.avg_differential_10?.toFixed(1) || "N/A"}
- Volatility: ${rollingStats.volatility_20?.toFixed(1) || "N/A"}
` : "New user - not enough rounds yet."}

${stats ? `
RECENT PERFORMANCE (last 90 days):
- Rounds analyzed: ${stats.rounds_analyzed}
- Fairways hit: ${(stats.fir_pct * 100)?.toFixed(0)}%
- Greens in regulation: ${(stats.gir_pct * 100)?.toFixed(0)}%
- Putts per GIR: ${stats.avg_putts_per_gir?.toFixed(1)}
- 3-putt rate: ${(stats.three_putt_rate * 100)?.toFixed(0)}%
- Penalties per round: ${stats.avg_penalties_per_round?.toFixed(1)}
- Up-and-down: ${(stats.up_and_down_pct * 100)?.toFixed(0)}%
- Avg blowup holes per round: ${stats.avg_blowup_holes?.toFixed(1)}
` : ""}

${clubProfiles?.length ? `
CLUB DISTANCES (from user's logged shots):
${clubProfiles.map(p => `- ${p.club_id}: median ${p.median_yards}y (${p.sample_size} shots)`).join("\n")}
` : "No club distance data yet."}

RULES:
1. When asked about club selection, you MUST base recommendations on the user's actual club distance data above. Never invent distances.
2. Be conversational but concise. Golfers are often on the course.
3. When analyzing the user's game, focus on actionable insights based on their actual stats.
4. If you don't have enough data for a specific recommendation, say so clearly.
5. Keep responses under 150 words unless the user asks for detailed analysis.`;

    const response = await anthropic.messages.create({
      model: "claude-sonnet-4-20250514",
      max_tokens: 500,
      system: systemPrompt,
      messages: [
        ...(context?.previousMessages || []),
        { role: "user", content: message },
      ],
    });

    const assistantMessage =
      response.content[0].type === "text" ? response.content[0].text : "";

    return new Response(
      JSON.stringify({
        message: assistantMessage,
        usage: response.usage,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Caddie chat error:", error);
    return new Response(
      JSON.stringify({ error: "Failed to process chat" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
```

---

## Build Sequence

### Phase 0: Design System & Foundation (Week 1)

**Deliverables:**
1.  Expo project initialized with TypeScript & NativeWind v4
2.  Tailwind config set up (colors, fonts, spacing)
3.  Core UI Primitives implemented (Text, Button, Card, Input)
4.  Layout wrapper with Safe Area handling
5.  Icon set configured (Lucide React Native)

**Commands:**
```bash
npx create-expo-app caddieiq -t expo-template-blank-typescript
cd caddieiq
npx expo install nativewind tailwindcss react-native-reanimated
npx expo install lucide-react-native
```

**Acceptance criteria:**
-   NativeWind working (apply `className="bg-red-500"` works)
-   Custom fonts loaded
-   Base components visually verified in a "Kitchen Sink" screen

---

### Phase 1: Core Foundation (Week 1-2)

**Deliverables:**
1. Expo project initialized with TypeScript
2. Supabase project created with all migrations applied
3. Edge Functions deployed (course-search, course-detail)
4. Auth flow (email OTP)
5. Course search + detail screens working
6. Local SQLite schema for offline cache

**Commands:**
```bash
# Initialize
npx create-expo-app caddieiq -t expo-template-blank-typescript
cd caddieiq
npx expo install expo-router expo-sqlite @supabase/supabase-js @tanstack/react-query zustand
npx expo install react-hook-form zod expo-location react-native-maps

# Supabase
supabase init
supabase db push
supabase functions deploy course-search
supabase functions deploy course-detail
supabase secrets set GOLF_COURSE_API_KEY=your_key_here
```

**Acceptance criteria:**
- Can search courses via GolfCourseAPI
- Can view course detail with tees and holes
- Courses cache in Supabase
- Auth working with magic link

---

### Phase 2: Round Scoring (Week 3-4)

**Deliverables:**
1. Equipment setup (bags, clubs, balls)
2. Round creation flow
3. Hole-by-hole scoring UI
4. Scorecard view
5. Offline scoring with sync queue
6. Round completion + summary computation

**Key screens:**
- `/equipment/bag.tsx` - Bag editor
- `/round/new.tsx` - Start round
- `/round/[id]/index.tsx` - Active scoring
- `/round/[id]/recap.tsx` - Post-round summary

**Acceptance criteria:**
- Can create bag with clubs
- Can start round (course + tee + ball + bag snapshot)
- Can score holes offline
- Round syncs when online
- Summary computes on completion

---

### Phase 3: Analytics V1 (Week 5-6)

**Deliverables:**
1. Rolling differential chart
2. Strokes leak dashboard
3. Round history list
4. Course performance view
5. Handicap-style index display

**Key components:**
- `DifferentialChart.tsx` - Victory Native line chart
- `StrokesLeakChart.tsx` - Bar chart of leak categories
- `InsightCard.tsx` - Auto-generated recommendations

**Acceptance criteria:**
- Dashboard shows rolling differential trend
- Leak analysis shows putting/penalties/accuracy breakdown
- Can view any past round detail
- Insights generated based on stats

---

### Phase 4: AI Caddie (Week 7-8)

**Deliverables:**
1. Distance observation logging (post-round flow)
2. Club recommendation engine
3. Caddie chat interface
4. Edge Functions deployed (caddie-recommend, caddie-chat)

**Key screens:**
- `/caddie.tsx` - Chat interface
- Distance input component for quick club recs

**Acceptance criteria:**
- Can log distance observations after round
- Club profiles build from observations
- Can ask "What club for 154?" and get personalized answer
- Chat works with full context

---

### Phase 5: Groups + Realtime (Week 9-10)

**Deliverables:**
1. Group creation + invite flow
2. Group round creation
3. Live leaderboard (Supabase Realtime)
4. Member scoring views

**Key screens:**
- `/groups/index.tsx` - Group list
- `/groups/[id].tsx` - Group detail + leaderboard
- `/groups/invite.tsx` - Join via code

**Acceptance criteria:**
- Can create group and invite friends
- Can start group round
- Each player scores themselves
- Leaderboard updates live

---

### Phase 6: Equipment Lab (Week 11-12)

**Deliverables:**
1. Ball performance analytics
2. Club performance analytics (tee + approach)
3. Bag version comparisons
4. Equipment recommendations

**Key components:**
- `EquipmentLab.tsx` - Main dashboard
- Ball vs ball comparison
- Driver vs 3W decision support

**Acceptance criteria:**
- Can see differential by ball
- Can see FIR% by tee club
- Can see GIR% by approach club
- Recommendations based on data

---

## Environment Variables

### Supabase Secrets (set via CLI)

```bash
supabase secrets set GOLF_COURSE_API_KEY=your_golf_api_key
supabase secrets set ANTHROPIC_API_KEY=your_anthropic_key
```

### App .env.local

```
EXPO_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=your_anon_key
```

---

## Testing Checklist

### Phase 1
- [ ] Course search returns results
- [ ] Course detail loads tees and holes
- [ ] Auth flow completes
- [ ] Courses persist in Supabase

### Phase 2
- [ ] Can add/remove clubs from bag
- [ ] Bag snapshot created on round start
- [ ] Score updates persist locally
- [ ] Scores sync when online
- [ ] Round summary computes correctly
- [ ] Differential calculates correctly

### Phase 3
- [ ] Charts render with sample data
- [ ] Rolling stats update after round
- [ ] Leak analysis shows correct percentages
- [ ] Insights generate based on thresholds

### Phase 4
- [ ] Distance observations save
- [ ] Club profiles build correctly
- [ ] Recommendations return for known distances
- [ ] Chat responds with user context
- [ ] Chat respects club distance data

### Phase 5
- [ ] Group invite code works
- [ ] Group round shows all players
- [ ] Realtime updates on score entry
- [ ] Leaderboard sorts correctly

### Phase 6
- [ ] Ball comparison shows differential
- [ ] Club comparison shows success rates
- [ ] Sample size gating works
- [ ] Recommendations are actionable

---

## Critical Implementation Notes

1. **Tee snapshot JSONB structure:**
```typescript
interface TeeSnapshot {
  tee_id: string;
  tee_name: string;
  tee_gender_category: "male" | "female";
  course_rating: number;
  slope_rating: number;
  bogey_rating: number;
  par_total: number;
  total_yards: number;
  front_course_rating?: number;
  front_slope_rating?: number;
  back_course_rating?: number;
  back_slope_rating?: number;
  holes: Array<{
    hole_number: number;
    par: number;
    yardage: number;
    handicap: number;
  }>;
  course: {
    external_course_id: string;
    club_name: string;
    course_name: string;
  };
}
```

2. **Offline sync queue strategy:**
- Store pending operations in SQLite
- Each operation has: entity_type, entity_id, action, payload, created_at
- Sync worker runs on app foreground + connectivity change
- Conflict resolution: last-write-wins with server timestamp

3. **Differential calculation:**
```typescript
const differential = ((adjustedScore - courseRating) * 113) / slopeRating;
```

4. **9-hole differential adjustment:**
```typescript
// For 9-hole rounds, use front/back ratings
const nineHoleDifferential = ((score - nineHoleCourseRating) * 113) / nineHoleSlope;
// Note: WHS technically doubles 9-hole differentials and combines them
// For V1, just track separately
```

5. **Sample size gating for equipment analytics:**
- Minimum 3 rounds for ball comparison
- Minimum 5 uses for club stats
- Display confidence level based on sample size

---

## Success Metrics

- **During round:** < 2 taps per hole for basic score
- **Sync reliability:** 99%+ successful syncs
- **Insight accuracy:** Recommendations match actual data
- **Performance:** < 200ms for local operations
- **Offline:** Full scoring works without network
