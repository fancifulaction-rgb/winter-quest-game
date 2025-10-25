-- Winter Quest Game Database Schema
-- Выполните этот скрипт в SQL Editor панели Supabase
-- Ссылка: https://supabase.com/dashboard/project/YOUR_PROJECT_ID/sql

-- Включаем необходимые расширения
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ================================
-- 1. ТАБЛИЦЫ ИГР
-- ================================

-- Основная таблица игр
CREATE TABLE games (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    title TEXT NOT NULL,
    access_code VARCHAR(6) UNIQUE NOT NULL,
    max_players INTEGER DEFAULT 200,
    total_time INTEGER NOT NULL, -- в минутах
    question_time INTEGER NOT NULL, -- в минутах на вопрос
    scoring_formula JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Настройки игры
CREATE TABLE game_settings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    game_id UUID REFERENCES games(id) ON DELETE CASCADE,
    theme VARCHAR(50) DEFAULT 'christmas',
    company_logo TEXT,
    primary_color VARCHAR(7) DEFAULT '#4A6CFD',
    secondary_color VARCHAR(7) DEFAULT '#FBBF24',
    bonus_correct_streak INTEGER DEFAULT 10,
    bonus_fast_answer INTEGER DEFAULT 5,
    skip_penalty_multiplier DECIMAL(3,1) DEFAULT 1.5,
    max_skips_without_penalty INTEGER DEFAULT 2,
    show_leaderboard_masks BOOLEAN DEFAULT false,
    max_lives INTEGER, -- NULL для бесконечно
    lives_enabled BOOLEAN DEFAULT true,
    file_size_limits JSONB DEFAULT '{"image": 10, "video": 10, "audio": 10}',
    supported_formats JSONB DEFAULT '{"image": ["jpg","jpeg","png","webp","gif","bmp"], "video": ["mp4","mov","avi","mkv","webm","3gp","m4v"], "audio": ["mp3","wav","ogg","aac","m4a","flac"]}',
    global_leaderboard BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ================================
-- 2. ТАБЛИЦЫ ВОПРОСОВ
-- ================================

-- Вопросы
CREATE TABLE questions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    game_id UUID REFERENCES games(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    question_type VARCHAR(20) NOT NULL, -- 'text', 'image', 'video', 'audio', 'text_image', 'text_video', 'text_audio', 'video_audio'
    media_url TEXT,
    answer TEXT NOT NULL,
    difficulty VARCHAR(10) DEFAULT 'medium', -- 'easy', 'medium', 'hard'
    base_score INTEGER DEFAULT 100,
    hint_penalty INTEGER DEFAULT 10,
    order_index INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Подсказки к вопросам
CREATE TABLE hints (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    question_id UUID REFERENCES questions(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    media_url TEXT,
    penalty INTEGER DEFAULT 10,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ================================
-- 3. ТАБЛИЦЫ ИГРОКОВ
-- ================================

-- Игроки
CREATE TABLE players (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    game_id UUID REFERENCES games(id) ON DELETE CASCADE,
    team_name TEXT NOT NULL,
    captain_name TEXT NOT NULL,
    avatar_url TEXT,
    access_code VARCHAR(6) NOT NULL,
    join_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Система жизней игроков
CREATE TABLE player_lives (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    player_id UUID REFERENCES players(id) ON DELETE CASCADE,
    game_id UUID REFERENCES games(id) ON DELETE CASCADE,
    lives_remaining INTEGER NOT NULL DEFAULT 3,
    max_lives INTEGER, -- NULL для бесконечно
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(player_id, game_id)
);

-- Ответы игроков
CREATE TABLE player_answers (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    player_id UUID REFERENCES players(id) ON DELETE CASCADE,
    question_id UUID REFERENCES questions(id) ON DELETE CASCADE,
    answer TEXT NOT NULL,
    media_url TEXT,
    is_correct BOOLEAN DEFAULT false,
    time_taken INTEGER NOT NULL, -- в секундах
    hints_used INTEGER DEFAULT 0,
    points_earned INTEGER DEFAULT 0,
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_skipped BOOLEAN DEFAULT false,
    lives_remaining INTEGER,
    UNIQUE(player_id, question_id)
);

-- Игровые сессии (для отслеживания прогресса)
CREATE TABLE game_sessions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    player_id UUID REFERENCES players(id) ON DELETE CASCADE,
    game_id UUID REFERENCES games(id) ON DELETE CASCADE,
    current_question INTEGER DEFAULT 1,
    total_score INTEGER DEFAULT 0,
    completed_questions INTEGER DEFAULT 0,
    start_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_time TIMESTAMP WITH TIME ZONE,
    is_completed BOOLEAN DEFAULT false,
    UNIQUE(player_id, game_id)
);

-- ================================
-- 4. ТАБЛИЦЫ УВЕДОМЛЕНИЙ И ЧАТА
-- ================================

-- Push-уведомления
CREATE TABLE push_notifications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    game_id UUID REFERENCES games(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL, -- 'game_pause', 'game_resume', 'game_start', 'game_end', 'custom'
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    target_players TEXT[], -- массив player_id, пусто = всем
    is_sent BOOLEAN DEFAULT false,
    sent_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Комнаты чата
CREATE TABLE chat_rooms (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    game_id UUID REFERENCES games(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    allowed_players TEXT[] NOT NULL, -- массив player_id
    is_active BOOLEAN DEFAULT true,
    created_by TEXT NOT NULL, -- admin ID
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Сообщения чата
CREATE TABLE chat_messages (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    room_id UUID REFERENCES chat_rooms(id) ON DELETE CASCADE,
    sender_id TEXT NOT NULL, -- player_id или admin_id
    sender_name TEXT NOT NULL,
    message TEXT NOT NULL,
    message_type VARCHAR(10) DEFAULT 'text', -- 'text', 'image', 'file'
    media_url TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_read BOOLEAN DEFAULT false
);

-- Участники чата
CREATE TABLE chat_participants (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    room_id UUID REFERENCES chat_rooms(id) ON DELETE CASCADE,
    player_id TEXT NOT NULL, -- player_id
    player_name TEXT NOT NULL,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_online BOOLEAN DEFAULT false,
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(room_id, player_id)
);

-- ================================
-- 5. ТАБЛИЦЫ АДМИНИСТРИРОВАНИЯ
-- ================================

-- Административные действия
CREATE TABLE admin_actions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    type VARCHAR(30) NOT NULL, -- 'pause_game', 'resume_game', 'force_refresh', 'send_notification', 'kick_player'
    target TEXT, -- player_id или тип действия
    data JSONB,
    performed_by TEXT NOT NULL, -- admin ID
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    description TEXT NOT NULL
);

-- Настройки администратора (пароль и другие настройки)
CREATE TABLE admin_settings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    setting_key VARCHAR(50) UNIQUE NOT NULL,
    setting_value TEXT NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Вставка пароля администратора по умолчанию
INSERT INTO admin_settings (setting_key, setting_value) 
VALUES ('admin_password', 'winter-quest-2025');

-- ================================
-- 6. ИНДЕКСЫ ДЛЯ ПРОИЗВОДИТЕЛЬНОСТИ
-- ================================

-- Индексы для игр
CREATE INDEX idx_games_access_code ON games(access_code);
CREATE INDEX idx_games_is_active ON games(is_active);

-- Индексы для игроков
CREATE INDEX idx_players_game_id ON players(game_id);
CREATE INDEX idx_players_access_code ON players(access_code);
CREATE INDEX idx_players_is_active ON players(is_active);
CREATE INDEX idx_players_last_activity ON players(last_activity);

-- Индексы для вопросов
CREATE INDEX idx_questions_game_id ON questions(game_id);
CREATE INDEX idx_questions_order ON questions(game_id, order_index);

-- Индексы для ответов
CREATE INDEX idx_player_answers_player_id ON player_answers(player_id);
CREATE INDEX idx_player_answers_question_id ON player_answers(question_id);
CREATE INDEX idx_player_answers_is_correct ON player_answers(is_correct);
CREATE INDEX idx_player_answers_submitted_at ON player_answers(submitted_at);

-- Индексы для сессий
CREATE INDEX idx_game_sessions_player_id ON game_sessions(player_id);
CREATE INDEX idx_game_sessions_game_id ON game_sessions(game_id);
CREATE INDEX idx_game_sessions_is_completed ON game_sessions(is_completed);

-- Индексы для уведомлений
CREATE INDEX idx_push_notifications_game_id ON push_notifications(game_id);
CREATE INDEX idx_push_notifications_is_sent ON push_notifications(is_sent);

-- Индексы для чата
CREATE INDEX idx_chat_rooms_game_id ON chat_rooms(game_id);
CREATE INDEX idx_chat_messages_room_id ON chat_messages(room_id);
CREATE INDEX idx_chat_messages_timestamp ON chat_messages(timestamp);

-- ================================
-- 7. RLS (ROW LEVEL SECURITY) ПОЛИТИКИ
-- ================================

-- Включаем RLS для всех таблиц
ALTER TABLE games ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE hints ENABLE ROW LEVEL SECURITY;
ALTER TABLE players ENABLE ROW LEVEL SECURITY;
ALTER TABLE player_lives ENABLE ROW LEVEL SECURITY;
ALTER TABLE player_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_settings ENABLE ROW LEVEL SECURITY;

-- Политики для публичного доступа (игроки могут читать/писать свои данные)
CREATE POLICY "Players can read own data" ON players FOR SELECT USING (true);
CREATE POLICY "Players can insert own data" ON players FOR INSERT WITH CHECK (true);
CREATE POLICY "Players can update own data" ON players FOR UPDATE USING (true);

CREATE POLICY "Questions are readable by all" ON questions FOR SELECT USING (true);
CREATE POLICY "Hints are readable by all" ON hints FOR SELECT USING (true);

CREATE POLICY "Players can read own answers" ON player_answers FOR SELECT USING (true);
CREATE POLICY "Players can insert own answers" ON player_answers FOR INSERT WITH CHECK (true);
CREATE POLICY "Players can update own answers" ON player_answers FOR UPDATE USING (true);

CREATE POLICY "Players can read own lives" ON player_lives FOR SELECT USING (true);
CREATE POLICY "Players can update own lives" ON player_lives FOR UPDATE USING (true);

CREATE POLICY "Players can read own sessions" ON game_sessions FOR SELECT USING (true);
CREATE POLICY "Players can insert own sessions" ON game_sessions FOR INSERT WITH CHECK (true);
CREATE POLICY "Players can update own sessions" ON game_sessions FOR UPDATE USING (true);

-- Политики для администраторов (полный доступ)
CREATE POLICY "Admin full access games" ON games FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Admin full access game_settings" ON game_settings FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Admin full access questions" ON questions FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Admin full access hints" ON hints FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Admin full access players" ON players FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Admin full access player_lives" ON player_lives FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Admin full access player_answers" ON player_answers FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Admin full access game_sessions" ON game_sessions FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Admin full access push_notifications" ON push_notifications FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Admin full access chat_rooms" ON chat_rooms FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Admin full access chat_messages" ON chat_messages FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Admin full access chat_participants" ON chat_participants FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Admin full access admin_actions" ON admin_actions FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Admin full access admin_settings" ON admin_settings FOR ALL USING (auth.role() = 'service_role');

-- ================================
-- 8. ФУНКЦИИ И ТРИГГЕРЫ
-- ================================

-- Функция для обновления updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Триггеры для автоматического обновления updated_at
CREATE TRIGGER update_games_updated_at BEFORE UPDATE ON games
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_game_settings_updated_at BEFORE UPDATE ON game_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_players_last_activity AFTER UPDATE ON players
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Функция для автоматического создания записи жизней при добавлении игрока
CREATE OR REPLACE FUNCTION create_player_lives()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO player_lives (player_id, game_id, lives_remaining, max_lives)
    VALUES (NEW.id, NEW.game_id, 3, 3); -- По умолчанию 3 жизни
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Триггер для создания жизней при добавлении игрока
CREATE TRIGGER create_player_lives_trigger AFTER INSERT ON players
    FOR EACH ROW EXECUTE FUNCTION create_player_lives();

-- Функция для автоматического создания игровой сессии
CREATE OR REPLACE FUNCTION create_game_session()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO game_sessions (player_id, game_id)
    VALUES (NEW.id, NEW.game_id);
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Триггер для создания сессии при добавлении игрока
CREATE TRIGGER create_game_session_trigger AFTER INSERT ON players
    FOR EACH ROW EXECUTE FUNCTION create_game_session();

-- ================================
-- 9. НАЧАЛЬНЫЕ ДАННЫЕ
-- ================================

-- Пример игры для тестирования
INSERT INTO games (id, title, access_code, total_time, question_time) 
VALUES (
    uuid_generate_v4(),
    'Winter Quest 2025',
    'WINTER',
    60,
    5
);

-- Получаем ID созданной игры для настроек
WITH game_id AS (
    SELECT id FROM games WHERE access_code = 'WINTER' LIMIT 1
)
INSERT INTO game_settings (game_id, theme, max_lives)
SELECT id, 'christmas', 3 FROM game_id;

-- ================================
-- 10. STORAGE BUCKET (создайте вручную в интерфейсе Supabase)
-- ================================
/*
Создайте следующие Storage buckets в Supabase Dashboard:
1. avatars - для аватаров игроков
2. questions - для медиафайлов вопросов  
3. hints - для медиафайлов подсказок
4. chat-files - для файлов в чате

Настройте политики доступа:
- Public: avatars, questions, hints, chat-files (для чтения)
- Service Role: все buckets (для записи)

Bucket policies:
CREATE POLICY "Public can view avatars" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
CREATE POLICY "Authenticated can upload avatars" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.role() = 'authenticated');
*/

-- ================================
-- ГОТОВО! 
-- ================================
/*
После выполнения этого скрипта у вас будет полностью настроенная база данных для Winter Quest.
Не забудьте:

1. Создать Storage buckets в интерфейсе Supabase
2. Настроить политики доступа для Storage
3. Скопировать URL проекта и anon key из панели Supabase
4. Обновить файл .env с вашими ключами
5. Установить пароль администратора: UPDATE admin_settings SET setting_value = 'your_password' WHERE setting_key = 'admin_password';

База данных готова к использованию!
*/