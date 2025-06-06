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
  ('Customer Satisfaction Quiz', 'Quiz about customer satisfaction', '2025-04-20 10:00:00', '2025-04-30 23:59:59', TRUE, 'e7b3f5b4-8a63-4e2e-baad-5a8c5c5b1234'),
  ('Employee Feedback Quiz', 'Quiz to collect employee feedback', '2025-04-21 12:00:00', NULL, TRUE, '0e00b3e1-2c66-4f56-9332-9e20bfcdb812'),
  ('Website Usability Quiz', 'Quiz to evaluate website usability', '2025-04-22 14:00:00', '2025-05-01 20:00:00', FALSE, '7f6c9aee-681c-4f61-812d-dcd7edb7b029');

INSERT INTO "Question" (quiz_id, header, description)
VALUES
  ('827487ea-227a-4847-9bf7-e0ada468c87e', 'How satisfied are you?', 'Please rate your satisfaction from 1 to 5'),
  ('827487ea-227a-4847-9bf7-e0ada468c87e', 'Would you recommend us?', ''),
  ('827487ea-227a-4847-9bf7-e0ada468c87e', 'What could we improve?', 'Open-ended feedback welcome'),
  ('827487ea-227a4847-9bf7-e0ada468c87e', 'How easy was it to use our product?', 'Rate from 1 (hard) to 5 (easy)'),
  ('827487ea-227a-4847-9bf7-e0ada468c87e', 'Did everything work as expected?', '');

INSERT INTO "Type" (question_id, description)
VALUES
  ('f1b5084c-3e9a-485d-92e4-9b4696c2f953', '1TO5RATING'),
  ('11a6f19f-612c-4562-acba-a4573decb6ef', 'YES/NO'),
  ('68d46927-04b7-4d88-bf3d-6cd2d61e0756', 'TEXT'),
  ('654d25da-b39f-4bf0-9731-4872b7c3b5b3', '1TO5RATING'),
  ('b7135385-ca55-458c-b3f7-8c56c6449117', 'YES/NO');

INSERT INTO "WorkflowEvent" (datetime, state, description, initiator_id, quiz_id)
VALUES
  (NOW(), 'pending', 'Перевірка квізу про SQL',
    (SELECT id FROM "User" WHERE email = 'alice@example.com'),
    (SELECT id FROM "Quiz" WHERE title = 'Customer Satisfaction Quiz')),
  (NOW(), 'approved', 'Затвердження квізу для початківців',
    (SELECT id FROM "User" WHERE email = 'bob@example.com'),
    (SELECT id FROM "Quiz" WHERE title = 'Employee Feedback Quiz'));

INSERT INTO "EventParticipant" (role, user_id, event_id)
VALUES
  ('Reviewer', 'dcd73fec-10fb-4bc5-8c01-938fa329af46', (SELECT id FROM "WorkflowEvent" WHERE state = 'pending' LIMIT 1)),
  ('Submitter', 'd3e1b89e-23f5-4de1-a37d-5243f16f9b8c', (SELECT id FROM "WorkflowEvent" WHERE state = 'approved' LIMIT 1));

INSERT INTO "Answer" (content, user_id, question_id, answer_id)
VALUES
  ('The answer to life is 42.', 'dcd73fec-10fb-4bc5-8c01-938fa329af46', '827487ea-227a-4847-9bf7-e0ada468c87e', 'd3e1b89e-23f5-4de1-a37d-5243f16f9b8c'),
  ('The second possible answer is 24.', 'e6d3b15e-29c4-49ad-97d3-61ad1234ac9b', '827487ea-227a-4847-9bf7-e0ada468c87e', 'e6d3b15e-29c4-49ad-97d3-61ad1234ac9b');

INSERT INTO "Variant" (question_id, text)
VALUES
  ('f1b5084c-3e9a-485d-92e4-9b4696c2f953', 'Option 1'),
  ('f1b5084c-3e9a-485d-92e4-9b4696c2f953', 'Option 2'),
  ('11a6f19f-612c-4562-acba-a4573decb6ef', 'Yes'),
  ('11a6f19f-612c-4562-acba-а4573decb6еф', 'No');

INSERT INTO "SelectedVar" (variant_id, answer_id)
VALUES
  ((SELECT id FROM "Variant" WHERE text = 'Option 1'), (SELECT id FROM "Answer" WHERE content = 'The answer to life is 42.')),
  ((SELECT id FROM "Variant" WHERE text = 'Yes'), (SELECT id FROM "Answer" WHERE content = 'The second possible answer is 24.'));

INSERT INTO "Feedback" (description, date, user_id, survey_id)
VALUES
  ('This is some feedback content.', NOW(), 'dcd73fec-10fb-4bc5-8c01-938fa329af46', NULL);

INSERT INTO "Result" (content, name, answer_id)
VALUES
  ('User successfully answered the question.', 'First Attempt', (SELECT id FROM "Answer" WHERE content = 'The answer to life is 42.')),
  ('A comment on the first answer.', 'Comment1', (SELECT id FROM "Answer" WHERE content = 'The answer to life is 42.'));
