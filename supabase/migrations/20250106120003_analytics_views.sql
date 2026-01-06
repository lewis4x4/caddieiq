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
