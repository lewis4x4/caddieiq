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
