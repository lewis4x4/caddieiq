# CLAUDE.md - CaddieIQ

## Project Identity

**Name:** CaddieIQ  
**Type:** React Native (Expo) mobile app + Supabase backend  
**Purpose:** Golf scoring, analytics, and AI caddie for avid golfers  
**Targets:** iOS + Android

---

## Development Rules

### 1. Investigation First
- **Never speculate about code you haven't opened.** If a file is referenced, read it before answering.
- Before making changes, scan relevant files and understand the current implementation.
- Give grounded, hallucination-free answers based on actual code.

### 2. Check In Before Major Changes
- Before architectural changes, refactors, or multi-file modifications, explain the plan and wait for approval.
- High-level explanation only — no code until confirmed.

### 3. Simplicity Over Complexity
- Every change should impact as little code as possible.
- Avoid massive or complex changes.
- Prefer small, focused commits.
- If a simple solution exists, use it.

### 4. Keep Documentation Updated
- After making changes, update this file's **Architecture** and **Key Files** sections if structure changes.
- Document new patterns or conventions introduced.

### 5. Change Summaries
- After each change, provide a one-line high-level explanation of what changed.
- No verbose explanations unless asked.

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Mobile Framework | React Native + Expo SDK 52+ |
| Language | TypeScript (strict mode) |
| Navigation | Expo Router (file-based) |
| Server State | TanStack Query v5 |
| Local State | Zustand |
| Local DB | expo-sqlite (offline scoring) |
| Charts | Victory Native |
| Backend | Supabase (Auth, Postgres, Realtime, Edge Functions, Storage) |
| External API | GolfCourseAPI (proxied via Edge Functions) |
| AI | Claude API via Edge Functions |

---

## Architecture Principles

1. **Offline-first scoring** — Round scoring works without connectivity. Sync when available.
2. **Course cache required** — Can only start offline if course is already cached locally.
3. **Edge Functions as proxy** — All external API calls (GolfCourseAPI, Claude) go through Supabase Edge Functions. No API keys in client.
4. **Snapshot immutability** — Tee data, bag configuration frozen at round start. Analytics remain consistent forever.
5. **Self-scoring in groups** — Each player scores themselves. No conflicts.
6. **Deterministic AI layer** — Club recommendations from user's own distance data, not LLM invention.

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
│       ├── course-search/index.ts
│       ├── course-detail/index.ts
│       ├── caddie-recommend/index.ts
│       └── caddie-chat/index.ts
├── assets/
├── app.json
├── package.json
├── tsconfig.json
└── .env.local
```

---

## Database Schema

### Core Tables

| Table | Purpose |
|-------|---------|
| `profiles` | User identity, linked to auth.users |
| `groups` | Friend groups with invite codes |
| `group_members` | Group membership + roles |
| `courses` | Cached course data from GolfCourseAPI |
| `tees` | Tee boxes per course (rating, slope, holes) |
| `balls` | User's ball collection |
| `clubs` | Individual clubs |
| `bags` | Bag configurations (set of clubs) |
| `bag_clubs` | Junction: bags ↔ clubs |
| `rounds` | Round records with frozen snapshots |
| `round_holes` | Hole-by-hole scores and metadata |
| `round_participants` | Group round members |
| `distance_observations` | Club distance data for AI caddie |

### Analytics Views

| View | Purpose |
|------|---------|
| `user_rolling_stats` | Handicap index, avg differential, volatility |
| `user_strokes_leak` | Putting, penalties, GIR breakdown |
| `club_distance_profiles` | Median/avg/stddev per club |
| `ball_performance` | Scoring averages by ball model |
| `course_performance` | User stats per course |

---

## Edge Functions

| Function | Purpose |
|----------|---------|
| `course-search` | Proxy GolfCourseAPI search, cache results |
| `course-detail` | Fetch full course + tee data, cache |
| `caddie-recommend` | Deterministic club recommendation from user data |
| `caddie-chat` | Claude-powered conversational caddie |

---

## Key Patterns

### Tee Snapshot (JSONB in rounds table)
```typescript
interface TeeSnapshot {
  tee_id: string;
  tee_name: string;
  course_rating: number;
  slope_rating: number;
  par_total: number;
  total_yards: number;
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

### Differential Calculation
```typescript
const differential = ((adjustedScore - courseRating) * 113) / slopeRating;
```

### Offline Sync Queue
- Store pending operations in SQLite
- Each operation: `{ entity_type, entity_id, action, payload, created_at }`
- Sync on app foreground + connectivity change
- Conflict resolution: last-write-wins with server timestamp

---

## Build Phases

| Phase | Focus | Key Deliverables |
|-------|-------|------------------|
| 1 | Foundation | Auth, course search, course caching |
| 2 | Scoring | Round creation, hole-by-hole UI, offline sync |
| 3 | Analytics | Differential charts, strokes leak, round history |
| 4 | AI Caddie | Distance logging, club recs, chat interface |
| 5 | Groups | Invites, group rounds, realtime leaderboard |
| 6 | Equipment Lab | Ball comparison, club analytics |

---

## Commands

```bash
# Development
npx expo start

# Supabase
supabase db push
supabase functions deploy course-search
supabase functions deploy course-detail
supabase functions deploy caddie-recommend
supabase functions deploy caddie-chat

# Generate types
supabase gen types typescript --local > types/database.ts
```

---

## Success Metrics

- < 2 taps per hole for basic score entry
- 99%+ sync reliability
- < 200ms for local operations
- Full offline scoring capability
