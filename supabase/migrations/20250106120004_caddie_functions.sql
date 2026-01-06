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
