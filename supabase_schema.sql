-- =====================================================
-- Health Insight Pro - Supabase Database Schema
-- Run this in your Supabase SQL Editor
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- USER PROFILES
-- =====================================================
CREATE TABLE IF NOT EXISTS user_profiles (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    apple_user_id   TEXT UNIQUE NOT NULL,
    email           TEXT,
    full_name       TEXT,
    avatar_url      TEXT,
    date_of_birth   DATE,
    biological_sex  TEXT DEFAULT 'other',
    height_cm       DOUBLE PRECISION DEFAULT 170,
    weight_kg       DOUBLE PRECISION DEFAULT 70,
    target_weight_kg DOUBLE PRECISION,
    activity_level  TEXT DEFAULT 'moderately_active',
    goals           JSONB DEFAULT '["general_health"]',
    daily_calorie_goal   DOUBLE PRECISION DEFAULT 2000,
    daily_protein_goal   DOUBLE PRECISION DEFAULT 150,
    daily_carb_goal      DOUBLE PRECISION DEFAULT 250,
    daily_fat_goal       DOUBLE PRECISION DEFAULT 65,
    daily_water_goal     DOUBLE PRECISION DEFAULT 2500,
    daily_step_goal      INTEGER DEFAULT 10000,
    nightly_sleep_goal   DOUBLE PRECISION DEFAULT 8.0,
    weekly_workout_goal  INTEGER DEFAULT 4,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- FOOD ITEMS (shared nutrition database)
-- =====================================================
CREATE TABLE IF NOT EXISTS food_items (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name            TEXT NOT NULL,
    brand           TEXT,
    barcode         TEXT,
    serving_size    DOUBLE PRECISION NOT NULL DEFAULT 100,
    serving_unit    TEXT NOT NULL DEFAULT 'g',
    serving_description TEXT,
    is_custom       BOOLEAN DEFAULT FALSE,
    user_id         UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    -- Macros per serving
    calories        DOUBLE PRECISION DEFAULT 0,
    protein         DOUBLE PRECISION DEFAULT 0,
    carbs           DOUBLE PRECISION DEFAULT 0,
    fat             DOUBLE PRECISION DEFAULT 0,
    fiber           DOUBLE PRECISION DEFAULT 0,
    sugar           DOUBLE PRECISION DEFAULT 0,
    sodium          DOUBLE PRECISION DEFAULT 0,
    cholesterol     DOUBLE PRECISION DEFAULT 0,
    saturated_fat   DOUBLE PRECISION DEFAULT 0,
    trans_fat       DOUBLE PRECISION DEFAULT 0,
    potassium       DOUBLE PRECISION DEFAULT 0,
    vitamin_a       DOUBLE PRECISION,
    vitamin_c       DOUBLE PRECISION,
    calcium         DOUBLE PRECISION,
    iron            DOUBLE PRECISION,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS food_items_name_idx ON food_items USING gin(to_tsvector('english', name));
CREATE INDEX IF NOT EXISTS food_items_barcode_idx ON food_items (barcode) WHERE barcode IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS food_items_barcode_unique_idx ON food_items (barcode) WHERE barcode IS NOT NULL;

-- =====================================================
-- MEAL ENTRIES
-- =====================================================
CREATE TABLE IF NOT EXISTS meal_entries (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    meal_type       TEXT NOT NULL,
    logged_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes           TEXT,
    image_url       TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS meal_entry_items (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    meal_entry_id   UUID NOT NULL REFERENCES meal_entries(id) ON DELETE CASCADE,
    food_item_id    UUID NOT NULL REFERENCES food_items(id),
    servings        DOUBLE PRECISION NOT NULL DEFAULT 1,
    serving_size    DOUBLE PRECISION
);

CREATE INDEX IF NOT EXISTS meal_entries_user_date_idx ON meal_entries (user_id, logged_at);

-- =====================================================
-- SLEEP ENTRIES
-- =====================================================
CREATE TABLE IF NOT EXISTS sleep_entries (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id                 UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    start_time              TIMESTAMPTZ NOT NULL,
    end_time                TIMESTAMPTZ NOT NULL,
    source                  TEXT DEFAULT 'manual',
    notes                   TEXT,
    avg_heart_rate          DOUBLE PRECISION,
    min_heart_rate          DOUBLE PRECISION,
    max_heart_rate          DOUBLE PRECISION,
    avg_hrv                 DOUBLE PRECISION,
    avg_oxygen_saturation   DOUBLE PRECISION,
    min_oxygen_saturation   DOUBLE PRECISION,
    avg_respiratory_rate    DOUBLE PRECISION,
    sleep_score             INTEGER,
    deep_sleep_score        INTEGER,
    rem_sleep_score         INTEGER,
    efficiency_score        INTEGER,
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sleep_stage_segments (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sleep_entry_id      UUID NOT NULL REFERENCES sleep_entries(id) ON DELETE CASCADE,
    stage               TEXT NOT NULL,
    start_time          TIMESTAMPTZ NOT NULL,
    duration_minutes    DOUBLE PRECISION NOT NULL
);

CREATE INDEX IF NOT EXISTS sleep_entries_user_idx ON sleep_entries (user_id, start_time DESC);

-- =====================================================
-- ACTIVITY ENTRIES (individual workouts)
-- =====================================================
CREATE TABLE IF NOT EXISTS activity_entries (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    activity_type       TEXT NOT NULL,
    name                TEXT,
    start_time          TIMESTAMPTZ NOT NULL,
    end_time            TIMESTAMPTZ NOT NULL,
    duration_minutes    DOUBLE PRECISION NOT NULL,
    calories_burned     DOUBLE PRECISION DEFAULT 0,
    distance_km         DOUBLE PRECISION,
    avg_heart_rate      DOUBLE PRECISION,
    max_heart_rate      DOUBLE PRECISION,
    steps               INTEGER,
    elevation_gain_m    DOUBLE PRECISION,
    avg_pace_min_per_km DOUBLE PRECISION,
    avg_cadence         DOUBLE PRECISION,
    avg_power           DOUBLE PRECISION,
    vo2max              DOUBLE PRECISION,
    strain_score        INTEGER,
    source              TEXT DEFAULT 'manual',
    notes               TEXT,
    route               JSONB,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- DAILY ACTIVITY SUMMARY (aggregated per day)
-- =====================================================
CREATE TABLE IF NOT EXISTS daily_activities (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    date                DATE NOT NULL,
    steps               INTEGER DEFAULT 0,
    distance_km         DOUBLE PRECISION DEFAULT 0,
    active_calories     DOUBLE PRECISION DEFAULT 0,
    resting_calories    DOUBLE PRECISION DEFAULT 0,
    total_calories      DOUBLE PRECISION DEFAULT 0,
    active_minutes      INTEGER DEFAULT 0,
    standing_hours      INTEGER DEFAULT 0,
    avg_heart_rate      DOUBLE PRECISION,
    resting_heart_rate  DOUBLE PRECISION,
    max_heart_rate      DOUBLE PRECISION,
    vo2max              DOUBLE PRECISION,
    UNIQUE (user_id, date)
);

-- =====================================================
-- WATER ENTRIES
-- =====================================================
CREATE TABLE IF NOT EXISTS water_entries (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    amount_ml       DOUBLE PRECISION NOT NULL,
    logged_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    container_type  TEXT
);

CREATE INDEX IF NOT EXISTS water_entries_user_date_idx ON water_entries (user_id, logged_at);

-- =====================================================
-- WEIGHT ENTRIES
-- =====================================================
CREATE TABLE IF NOT EXISTS weight_entries (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    weight_kg           DOUBLE PRECISION NOT NULL,
    body_fat_percent    DOUBLE PRECISION,
    muscle_mass_kg      DOUBLE PRECISION,
    bone_mass_kg        DOUBLE PRECISION,
    water_percent       DOUBLE PRECISION,
    bmi                 DOUBLE PRECISION,
    visceral_fat        DOUBLE PRECISION,
    logged_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes               TEXT,
    source              TEXT DEFAULT 'manual'
);

-- =====================================================
-- JOURNAL ENTRIES
-- =====================================================
CREATE TABLE IF NOT EXISTS journal_entries (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id                     UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    date                        DATE NOT NULL,
    mood                        TEXT NOT NULL DEFAULT 'good',
    energy_level                INTEGER DEFAULT 5,
    stress_level                INTEGER DEFAULT 5,
    anxiety_level               INTEGER DEFAULT 5,
    notes                       TEXT,
    meditated_today             BOOLEAN DEFAULT FALSE,
    exercised_today             BOOLEAN DEFAULT FALSE,
    alcohol_consumed            BOOLEAN DEFAULT FALSE,
    alcohol_servings            INTEGER,
    smoking_today               BOOLEAN DEFAULT FALSE,
    medication_taken            BOOLEAN DEFAULT FALSE,
    medication_notes            TEXT,
    sunlight_exposure_minutes   INTEGER,
    social_interaction          BOOLEAN DEFAULT TRUE,
    gratitude_notes             TEXT,
    symptoms_reported           JSONB DEFAULT '[]',
    tags                        JSONB DEFAULT '[]',
    UNIQUE (user_id, date)
);

-- =====================================================
-- INSIGHT SCORES
-- =====================================================
CREATE TABLE IF NOT EXISTS insight_scores (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    date                DATE NOT NULL,
    recovery_score      INTEGER DEFAULT 50,
    stress_score        INTEGER DEFAULT 50,
    strain_score        INTEGER DEFAULT 50,
    readiness_score     INTEGER DEFAULT 50,
    sleep_score         INTEGER DEFAULT 50,
    nutrition_score     INTEGER DEFAULT 50,
    hydration_score     INTEGER DEFAULT 50,
    UNIQUE (user_id, date)
);

-- =====================================================
-- RECIPES
-- =====================================================
CREATE TABLE IF NOT EXISTS recipes (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    name                TEXT NOT NULL,
    description         TEXT,
    servings            INTEGER DEFAULT 1,
    ingredients         JSONB DEFAULT '[]',
    image_url           TEXT,
    tags                JSONB DEFAULT '[]',
    prep_time_minutes   INTEGER,
    cook_time_minutes   INTEGER,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- BLOOD METRICS
-- =====================================================
CREATE TABLE IF NOT EXISTS blood_metrics (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id                 UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    recorded_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    oxygen_saturation       DOUBLE PRECISION,
    respiratory_rate        DOUBLE PRECISION,
    systolic_bp             DOUBLE PRECISION,
    diastolic_bp            DOUBLE PRECISION,
    blood_glucose           DOUBLE PRECISION,
    hrv                     DOUBLE PRECISION
);

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_entry_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE sleep_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE sleep_stage_segments ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE water_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE weight_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE insight_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE blood_metrics ENABLE ROW LEVEL SECURITY;

-- RLS Policies: users can only access their own data
CREATE POLICY "Users own their profile" ON user_profiles FOR ALL USING (auth.uid() = id);
CREATE POLICY "Users own meals" ON meal_entries FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users own meal items" ON meal_entry_items FOR ALL USING (
    meal_entry_id IN (SELECT id FROM meal_entries WHERE user_id = auth.uid())
);
CREATE POLICY "Users own sleep" ON sleep_entries FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users own sleep stages" ON sleep_stage_segments FOR ALL USING (
    sleep_entry_id IN (SELECT id FROM sleep_entries WHERE user_id = auth.uid())
);
CREATE POLICY "Users own activities" ON activity_entries FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users own daily activity" ON daily_activities FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users own water" ON water_entries FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users own weight" ON weight_entries FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users own journal" ON journal_entries FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users own insights" ON insight_scores FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users own recipes" ON recipes FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users own blood metrics" ON blood_metrics FOR ALL USING (auth.uid() = user_id);

-- Food items: public read, users write their own custom items
ALTER TABLE food_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read food items" ON food_items FOR SELECT USING (TRUE);
CREATE POLICY "Users create custom food" ON food_items FOR INSERT WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

-- =====================================================
-- SEED: Sample food items (USDA basics)
-- =====================================================
INSERT INTO food_items (name, brand, serving_size, serving_unit, serving_description, calories, protein, carbs, fat, fiber, sugar, sodium, cholesterol, saturated_fat, potassium) VALUES
('Chicken Breast (cooked)', NULL, 100, 'g', '100g', 165, 31, 0, 3.6, 0, 0, 74, 85, 1, 256),
('Brown Rice (cooked)', NULL, 100, 'g', '100g', 111, 2.6, 23, 0.9, 1.8, 0, 5, 0, 0.2, 43),
('Whole Egg (large)', NULL, 50, 'g', '1 large egg', 70, 6, 0.4, 5, 0, 0.2, 70, 185, 1.5, 69),
('Greek Yogurt (plain, 0% fat)', NULL, 170, 'g', '1 container (170g)', 100, 17, 6, 0, 0, 6, 65, 10, 0, 240),
('Banana (medium)', NULL, 118, 'g', '1 medium banana', 105, 1.3, 27, 0.4, 3.1, 14.4, 1, 0, 0.1, 422),
('Almonds (raw)', NULL, 28, 'g', '1 oz (28g)', 164, 6, 6, 14, 3.5, 1.2, 0, 0, 1.1, 200),
('Salmon (Atlantic, cooked)', NULL, 100, 'g', '100g', 206, 20, 0, 13, 0, 0, 59, 63, 3.2, 363),
('Sweet Potato (cooked)', NULL, 130, 'g', '1 medium', 103, 2.3, 24, 0.1, 3.8, 7.4, 41, 0, 0, 542),
('Oats (dry)', NULL, 40, 'g', '1/2 cup dry', 154, 5.5, 27, 2.6, 4, 0.5, 2, 0, 0.5, 147),
('Broccoli (cooked)', NULL, 91, 'g', '1 cup', 55, 3.7, 11, 0.6, 5.1, 1.7, 64, 0, 0.1, 457),
('Whole Milk (3.25%)', NULL, 244, 'ml', '1 cup', 149, 8, 12, 8, 0, 12, 105, 24, 4.6, 322),
('White Rice (cooked)', NULL, 186, 'g', '1 cup cooked', 242, 4.4, 53, 0.4, 0.6, 0, 0, 0, 0.1, 55),
('Avocado', NULL, 150, 'g', '1 medium', 240, 3, 13, 22, 10, 0.9, 11, 0, 3.2, 727),
('Whey Protein Powder', NULL, 30, 'g', '1 scoop', 120, 25, 3, 1.5, 0, 2, 130, 5, 0.5, 150),
('Olive Oil', NULL, 14, 'ml', '1 tbsp', 119, 0, 0, 13.5, 0, 0, 0, 0, 1.9, 0),
('Blueberries', NULL, 148, 'g', '1 cup', 84, 1.1, 21, 0.5, 3.6, 14.7, 1, 0, 0, 114),
('Coffee (black)', NULL, 240, 'ml', '1 cup', 2, 0.3, 0, 0, 0, 0, 5, 0, 0, 116),
('Apple (medium)', NULL, 182, 'g', '1 medium apple', 95, 0.5, 25, 0.3, 4.4, 18.9, 2, 0, 0, 195),
('Tuna (canned in water)', NULL, 85, 'g', '3 oz', 73, 17, 0, 0.5, 0, 0, 197, 26, 0.1, 139),
('Spinach (raw)', NULL, 30, 'g', '1 cup', 7, 0.9, 1.1, 0.1, 0.7, 0.1, 24, 0, 0, 167)
ON CONFLICT DO NOTHING;
