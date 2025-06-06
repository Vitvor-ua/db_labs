DROP TABLE IF EXISTS "SelectedVar" CASCADE;
DROP TABLE IF EXISTS "Result" CASCADE;
DROP TABLE IF EXISTS "Feedback" CASCADE;
DROP TABLE IF EXISTS "EventParticipant" CASCADE;
DROP TABLE IF EXISTS "WorkflowEvent" CASCADE;
DROP TABLE IF EXISTS "Variant" CASCADE;
DROP TABLE IF EXISTS "Answer" CASCADE;
DROP TABLE IF EXISTS "Type" CASCADE;
DROP TABLE IF EXISTS "Question" CASCADE;
DROP TABLE IF EXISTS "Quiz" CASCADE;
DROP TABLE IF EXISTS "user_roles" CASCADE;
DROP TABLE IF EXISTS "role_permissions" CASCADE;
DROP TABLE IF EXISTS "Permission" CASCADE;
DROP TABLE IF EXISTS "Role" CASCADE;
DROP TABLE IF EXISTS "User" CASCADE;
DROP TABLE IF EXISTS "Survey" CASCADE;

-- Додаємо розширення для генерації UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =========================
-- Створюємо таблицю Survey (щоб уникнути помилок при FOREIGN KEY)
-- =========================
CREATE TABLE IF NOT EXISTS "Survey" (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4()
);

-- =========================
-- 1. Таблиці без зовнішніх залежностей
-- =========================

CREATE TABLE IF NOT EXISTS "User" (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  first_name VARCHAR(255) NOT NULL,
  last_name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  phone_number VARCHAR(20),
  age SMALLINT
);

CREATE TABLE IF NOT EXISTS "Role" (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(255) NOT NULL,
  description TEXT
);

CREATE TABLE IF NOT EXISTS "Permission" (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(255) NOT NULL,
  description TEXT
);

-- =========================
-- 2. Quiz залежить від User
-- =========================

CREATE TABLE IF NOT EXISTS "Quiz" (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  creation_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  close_date TIMESTAMP,
  is_active BOOLEAN DEFAULT TRUE,
  owner_id UUID NOT NULL,
  FOREIGN KEY (owner_id) REFERENCES "User"(id) ON DELETE CASCADE
);

-- =========================
-- 3. Question залежить від Quiz
-- =========================

CREATE TABLE IF NOT EXISTS "Question" (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  header VARCHAR(255),
  description TEXT,
  quiz_id UUID NOT NULL,
  FOREIGN KEY (quiz_id) REFERENCES "Quiz"(id) ON DELETE CASCADE
);

-- =========================
-- 4. Type залежить від Question
-- =========================

CREATE TABLE IF NOT EXISTS "Type" (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  description TEXT,
  question_id UUID NOT NULL,
  FOREIGN KEY (question_id) REFERENCES "Question"(id) ON DELETE CASCADE
);

-- =========================
-- 5. WorkflowEvent залежить від User і Quiz
-- =========================

CREATE TABLE IF NOT EXISTS "WorkflowEvent" (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  datetime TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  state TEXT NOT NULL CHECK (state IN ('pending', 'approved', 'rejected', 'completed')),
  description TEXT,
  initiator_id UUID NOT NULL,
  quiz_id UUID NOT NULL,
  FOREIGN KEY (initiator_id) REFERENCES "User"(id) ON DELETE CASCADE,
  FOREIGN KEY (quiz_id) REFERENCES "Quiz"(id) ON DELETE CASCADE
);

-- =========================
-- 6. EventParticipant залежить від User і WorkflowEvent
-- =========================

CREATE TABLE IF NOT EXISTS "EventParticipant" (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  role TEXT NOT NULL,
  user_id UUID NOT NULL,
  event_id UUID NOT NULL,
  FOREIGN KEY (user_id) REFERENCES "User"(id) ON DELETE CASCADE,
  FOREIGN KEY (event_id) REFERENCES "WorkflowEvent"(id) ON DELETE CASCADE
);

-- =========================
-- 7. Variant залежить від Question
-- =========================

CREATE TABLE IF NOT EXISTS "Variant" (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  question_id UUID NOT NULL,
  text TEXT NOT NULL,
  FOREIGN KEY (question_id) REFERENCES "Question"(id) ON DELETE CASCADE
);

-- =========================
-- 8. Answer залежить від User і Question (self-reference)
-- =========================

CREATE TABLE IF NOT EXISTS "Answer" (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  content TEXT NOT NULL,
  user_id UUID NOT NULL,
  question_id UUID NOT NULL,
  answer_id UUID NOT NULL,
  FOREIGN KEY (user_id) REFERENCES "User"(id) ON DELETE CASCADE,
  FOREIGN KEY (question_id) REFERENCES "Question"(id) ON DELETE CASCADE,
  CONSTRAINT fk_answer_self FOREIGN KEY (answer_id) REFERENCES "Answer"(id)
);

-- =========================
-- 9. SelectedVar залежить від Variant і Answer
-- =========================

CREATE TABLE IF NOT EXISTS "SelectedVar" (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  variant_id UUID NOT NULL,
  answer_id UUID NOT NULL,
  FOREIGN KEY (variant_id) REFERENCES "Variant"(id) ON DELETE CASCADE,
  FOREIGN KEY (answer_id) REFERENCES "Answer"(id) ON DELETE CASCADE
);

-- =========================
-- 10. Result залежить від Answer
-- =========================

CREATE TABLE IF NOT EXISTS "Result" (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  content TEXT NOT NULL,
  name VARCHAR(255) NOT NULL,
  answer_id UUID NOT NULL,
  CONSTRAINT fk_result_answer FOREIGN KEY (answer_id) REFERENCES "Answer"(id)
);

-- =========================
-- 11. user_roles (зв’язок User ↔ Role)
-- =========================

CREATE TABLE IF NOT EXISTS "user_roles" (
  user_id UUID NOT NULL,
  role_id UUID NOT NULL,
  PRIMARY KEY (user_id, role_id),
  FOREIGN KEY (user_id) REFERENCES "User"(id) ON DELETE CASCADE,
  FOREIGN KEY (role_id) REFERENCES "Role"(id) ON DELETE CASCADE
);

-- =========================
-- 12. role_permissions (зв’язок Role ↔ Permission)
-- =========================

CREATE TABLE IF NOT EXISTS "role_permissions" (
  role_id UUID NOT NULL,
  permission_id UUID NOT NULL,
  PRIMARY KEY (role_id, permission_id),
  FOREIGN KEY (role_id) REFERENCES "Role"(id) ON DELETE CASCADE,
  FOREIGN KEY (permission_id) REFERENCES "Permission"(id) ON DELETE CASCADE
);

-- =========================
-- 13. Feedback залежить від User і Survey
-- =========================

CREATE TABLE IF NOT EXISTS "Feedback" (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  description TEXT NOT NULL,
  date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  user_id UUID NOT NULL,
  survey_id UUID,
  CONSTRAINT fk_feedback_user FOREIGN KEY (user_id)
    REFERENCES "User"(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_feedback_survey FOREIGN KEY (survey_id)
    REFERENCES "Survey"(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_feedback_user ON "Feedback"(user_id);
CREATE INDEX IF NOT EXISTS idx_feedback_survey ON "Feedback"(survey_id);

-- =========================
-- Вставка початкових даних
-- =========================

INSERT INTO "Role" (name, description)
VALUES
  ('Admin', 'Administrator role with full access'),
  ('Editor', 'Editor role with content editing permissions'),
  ('Viewer', 'Viewer role with read-only access');

INSERT INTO "Permission" (name, description)
VALUES
  ('Manage Users', 'Permission to manage users'),
  ('Edit Content', 'Permission to edit content'),
  ('View Content', 'Permission to view content');

INSERT INTO "User" (first_name, last_name, email, password, phone_number, age)
VALUES
  ('Alice', 'Smith', 'alice@example.com', 'hashedpassword1', '+123456789', 30),
  ('Bob', 'Johnson', 'bob@example.com', 'hashedpassword2', '+987654321', 25),
  ('Charlie', 'Brown', 'charlie@example.com', 'hashedpassword3', '+192837465', 35);

INSERT INTO "user_roles" (user_id, role_id)
VALUES
  ((SELECT id FROM "User" WHERE email = 'alice@example.com'), (SELECT id FROM "Role" WHERE name = 'Admin')),
  ((SELECT id FROM "User" WHERE email = 'bob@example.com'), (SELECT id FROM "Role" WHERE name = 'Editor')),
  ((SELECT id FROM "User" WHERE email = 'charlie@example.com'), (SELECT id FROM "Role" WHERE name = 'Viewer'));

INSERT INTO "role_permissions" (role_id, permission_id)
VALUES
  ((SELECT id FROM "Role" WHERE name = 'Admin'), (SELECT id FROM "Permission" WHERE name = 'Manage Users')),
  ((SELECT id FROM "Role" WHERE name = 'Editor'), (SELECT id FROM "Permission" WHERE name = 'Edit Content')),
  ((SELECT id FROM "Role" WHERE name = 'Viewer'), (SELECT id FROM "Permission" WHERE name = 'View Content'));

INSERT INTO "Quiz" (title, description, creation_date, close_date, is_active, owner_id)
VALUES
  ('Customer Satisfaction Quiz', 'Quiz about customer satisfaction', '2025-04-20 10:00:00', '2025-04-30 23:59:59', TRUE, (SELECT id FROM "User" WHERE email = 'alice@example.com'));

INSERT INTO "Question" (quiz_id, header, description)
VALUES
  ((SELECT id FROM "Quiz" WHERE title = 'Customer Satisfaction Quiz'), 'How satisfied are you?', 'Please rate your satisfaction from 1 to 5');

INSERT INTO "Type" (question_id, description)
VALUES
  ((SELECT id FROM "Question" WHERE header = 'How satisfied are you?'), '1TO5RATING');

-- Add one variant so GET /variant returns data
INSERT INTO "Variant" (question_id, text)
VALUES
  ((SELECT id FROM "Question" WHERE header = 'How satisfied are you?'), 'Option 1');
