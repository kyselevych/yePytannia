-- єПитання (ePytannia) Database Setup Script
-- Run this in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create user role enum
CREATE TYPE user_role AS ENUM ('teacher', 'student');

-- Create quiz status enum
CREATE TYPE quiz_status AS ENUM ('draft', 'active', 'completed');

-- Create question type enum
CREATE TYPE question_type AS ENUM ('multiple_choice', 'true_false', 'open_text');

-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR UNIQUE NOT NULL,
    full_name VARCHAR NOT NULL,
    role user_role NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create classes table
CREATE TABLE IF NOT EXISTS classes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    teacher_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    name VARCHAR NOT NULL,
    access_code VARCHAR(6) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create class_students table
CREATE TABLE IF NOT EXISTS class_students (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(class_id, student_id)
);

-- Create quizzes table
CREATE TABLE IF NOT EXISTS quizzes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    title VARCHAR NOT NULL,
    source_file_url TEXT,
    status quiz_status DEFAULT 'draft',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create questions table
CREATE TABLE IF NOT EXISTS questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quiz_id UUID NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    question_type question_type NOT NULL,
    points INTEGER DEFAULT 1,
    order_index INTEGER NOT NULL,
    is_ai_generated BOOLEAN DEFAULT true
);

-- Create answer_options table
CREATE TABLE IF NOT EXISTS answer_options (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    option_text TEXT NOT NULL,
    is_correct BOOLEAN DEFAULT false,
    order_index INTEGER
);

-- Create quiz_sessions table
CREATE TABLE IF NOT EXISTS quiz_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quiz_id UUID NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    score INTEGER,
    total_points INTEGER,
    UNIQUE(quiz_id, student_id)
);

-- Create student_answers table
CREATE TABLE IF NOT EXISTS student_answers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES quiz_sessions(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    selected_option_id UUID REFERENCES answer_options(id),
    text_answer TEXT,
    is_correct BOOLEAN,
    points_earned INTEGER,
    UNIQUE(session_id, question_id)
);

-- Function to generate access code
CREATE OR REPLACE FUNCTION generate_access_code() RETURNS TEXT AS $$
DECLARE
    chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    result TEXT := '';
    i INTEGER;
BEGIN
    FOR i IN 1..6 LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-generate access code for classes
CREATE OR REPLACE FUNCTION set_access_code() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.access_code IS NULL OR NEW.access_code = '' THEN
        LOOP
            NEW.access_code := generate_access_code();
            EXIT WHEN NOT EXISTS (SELECT 1 FROM classes WHERE access_code = NEW.access_code);
        END LOOP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_access_code
    BEFORE INSERT ON classes
    FOR EACH ROW
    EXECUTE FUNCTION set_access_code();

-- Row Level Security (RLS) Policies

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_students ENABLE ROW LEVEL SECURITY;
ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE answer_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_answers ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Classes policies
CREATE POLICY "Teachers can view own classes" ON classes FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'teacher')
    AND teacher_id = auth.uid()
);
CREATE POLICY "Students can view joined classes" ON classes FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'student')
    AND EXISTS (SELECT 1 FROM class_students WHERE class_id = id AND student_id = auth.uid())
);
CREATE POLICY "Teachers can insert own classes" ON classes FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'teacher')
    AND teacher_id = auth.uid()
);

-- Class students policies
CREATE POLICY "Students can view own enrollments" ON class_students FOR SELECT USING (student_id = auth.uid());
CREATE POLICY "Students can insert own enrollments" ON class_students FOR INSERT WITH CHECK (student_id = auth.uid());
CREATE POLICY "Teachers can view class enrollments" ON class_students FOR SELECT USING (
    EXISTS (SELECT 1 FROM classes WHERE id = class_id AND teacher_id = auth.uid())
);

-- Quizzes policies
CREATE POLICY "Teachers can manage own quizzes" ON quizzes FOR ALL USING (
    EXISTS (SELECT 1 FROM classes WHERE id = class_id AND teacher_id = auth.uid())
);
CREATE POLICY "Students can view active quizzes in joined classes" ON quizzes FOR SELECT USING (
    status = 'active' AND
    EXISTS (SELECT 1 FROM class_students WHERE class_id = quizzes.class_id AND student_id = auth.uid())
);

-- Questions policies
CREATE POLICY "Teachers can manage questions in own quizzes" ON questions FOR ALL USING (
    EXISTS (
        SELECT 1 FROM quizzes q
        JOIN classes c ON q.class_id = c.id
        WHERE q.id = quiz_id AND c.teacher_id = auth.uid()
    )
);
CREATE POLICY "Students can view questions in active quizzes" ON questions FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM quizzes q
        JOIN class_students cs ON q.class_id = cs.class_id
        WHERE q.id = quiz_id AND q.status = 'active' AND cs.student_id = auth.uid()
    )
);

-- Answer options policies
CREATE POLICY "Teachers can manage answer options" ON answer_options FOR ALL USING (
    EXISTS (
        SELECT 1 FROM questions qu
        JOIN quizzes q ON qu.quiz_id = q.id
        JOIN classes c ON q.class_id = c.id
        WHERE qu.id = question_id AND c.teacher_id = auth.uid()
    )
);
CREATE POLICY "Students can view answer options" ON answer_options FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM questions qu
        JOIN quizzes q ON qu.quiz_id = q.id
        JOIN class_students cs ON q.class_id = cs.class_id
        WHERE qu.id = question_id AND q.status = 'active' AND cs.student_id = auth.uid()
    )
);

-- Quiz sessions policies
CREATE POLICY "Students can manage own sessions" ON quiz_sessions FOR ALL USING (student_id = auth.uid());
CREATE POLICY "Teachers can view sessions in own quizzes" ON quiz_sessions FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM quizzes q
        JOIN classes c ON q.class_id = c.id
        WHERE q.id = quiz_id AND c.teacher_id = auth.uid()
    )
);

-- Student answers policies
CREATE POLICY "Students can manage own answers" ON student_answers FOR ALL USING (
    EXISTS (SELECT 1 FROM quiz_sessions WHERE id = session_id AND student_id = auth.uid())
);
CREATE POLICY "Teachers can view answers in own quizzes" ON student_answers FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM quiz_sessions qs
        JOIN quizzes q ON qs.quiz_id = q.id
        JOIN classes c ON q.class_id = c.id
        WHERE qs.id = session_id AND c.teacher_id = auth.uid()
    )
);

-- Create storage bucket for quiz files
INSERT INTO storage.buckets (id, name, public) VALUES ('quiz-files', 'quiz-files', false) ON CONFLICT DO NOTHING;

-- Storage policies for quiz files
CREATE POLICY "Teachers can upload files" ON storage.objects FOR INSERT WITH CHECK (
    bucket_id = 'quiz-files' AND
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'teacher')
);

CREATE POLICY "Teachers can view own files" ON storage.objects FOR SELECT USING (
    bucket_id = 'quiz-files' AND
    owner = auth.uid()
);

-- Function to create user profile automatically on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, role)
    VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'full_name', ''), 'student');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to automatically create profile
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();