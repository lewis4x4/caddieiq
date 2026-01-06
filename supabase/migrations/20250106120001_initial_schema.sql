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
