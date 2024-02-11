drop table if exists telegram cascade;
create table telegram(
    id bigint primary key);


drop table if exists "group" cascade;
create table "group"(
    id serial primary key,
    number text not null);


drop table if exists student cascade;
create table student(
    id int primary key,
    name text not null,
    surname text not null,
    group_id int references "group"(id) not null,
    telegram_id bigint references telegram(id) not null);


drop table if exists prep cascade;
create table prep(
    id int primary key,
    name text not null,
    surname text not null,
    telegram_id bigint references telegram(id) not null);


drop table if exists course cascade;
create table course(
    id serial primary key,
    prep_id bigint references prep(id) not null ,
    name text not null);


drop table if exists example cascade;
create table example(
    id serial primary key,
    message_id bigint not null);


drop table if exists lab cascade;
create table lab(
    id serial primary key,
    course_id int references course(id) not null,
    name text not null,
    task text not null,
    example_id int references example(id) null);


drop table if exists report_status cascade;
create table report_status(
    id serial primary key,
    str text not null);
insert into report_status (str) values ('не проверено'), ('принято'), ('не принято');

drop table if exists report cascade;
create table report(
    id serial primary key,
    lab_id int references lab(id) not null,
    status_id int references report_status(id) default 1,
    student_id int references student(id) not null,
    message_id bigint not null);


drop table if exists student_course cascade;
create table student_course(
    student_id int references student(id),
    course_id bigint references course(id),
    PRIMARY KEY (student_id, course_id));

---------------------

create index idx_student_group_id on student (group_id);
create index idx_course_prep_id on course (prep_id);
create index idx_lab_course_id on lab (course_id);
create index idx_report_student_lab on report (student_id, lab_id);

---------------------

CREATE OR REPLACE FUNCTION check_student_course() RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS(SELECT 1 FROM student_course WHERE student_id = NEW.student_id AND course_id IN (SELECT course_id FROM lab WHERE id = NEW.lab_id)) THEN
        RETURN NEW;
    ELSE
        RAISE EXCEPTION 'Student does not belong to the course for this lab';
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_student_course
BEFORE INSERT ON report
FOR EACH ROW
EXECUTE FUNCTION check_student_course();


CREATE OR REPLACE FUNCTION check_student_group()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM "group" WHERE id = NEW.group_id) THEN
        RAISE EXCEPTION 'Student must belong to an existing group';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_student_group
BEFORE INSERT ON student
FOR EACH ROW
EXECUTE FUNCTION check_student_group();


CREATE OR REPLACE FUNCTION check_course_prep()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM prep WHERE id = NEW.prep_id) THEN
        RAISE EXCEPTION 'Course must have an existing instructor';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_course_prep
BEFORE INSERT ON course
FOR EACH ROW
EXECUTE FUNCTION check_course_prep();


CREATE OR REPLACE FUNCTION check_report_lab()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM lab WHERE id = NEW.lab_id) THEN
        RAISE EXCEPTION 'Report must belong to an existing lab';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_report_lab
BEFORE INSERT ON report
FOR EACH ROW
EXECUTE FUNCTION check_report_lab();

-- Функция для регистрации студента
CREATE OR REPLACE FUNCTION register_student(surname TEXT, name TEXT, group_number TEXT, isu_id INTEGER, telegram_id INTEGER) RETURNS VOID AS
$$
BEGIN
    INSERT INTO telegram (id) VALUES (telegram_id) ON CONFLICT DO NOTHING;
    INSERT INTO student (id, name, surname, group_id, telegram_id)
    SELECT isu_id, name, surname, g.id, telegram_id
    FROM "group" g
    WHERE g.number = group_number;
END;
$$ LANGUAGE plpgsql;

-- Функция для удаления студента
CREATE OR REPLACE FUNCTION delete_student(tg_id INTEGER) RETURNS VOID AS
$$
BEGIN
    DELETE FROM student WHERE telegram_id = tg_id;
END;
$$ LANGUAGE plpgsql;

-- Функция для получения информации о студенте
CREATE OR REPLACE FUNCTION get_student_info(tg_id INTEGER) RETURNS TABLE(name TEXT, surname TEXT, group_number TEXT, isu_id INTEGER) AS
$$
BEGIN
    RETURN QUERY
    SELECT s.name, s.surname, g.number, s.id
    FROM student s
    LEFT JOIN "group" g ON s.group_id = g.id
    WHERE s.telegram_id = tg_id;
END;
$$ LANGUAGE plpgsql;

-- Функция для записи студента на курс
CREATE OR REPLACE FUNCTION apply_to_course(name_ TEXT, tg_id INTEGER) RETURNS VOID AS
$$
BEGIN
    INSERT INTO student_course (student_id, course_id)
    SELECT s.id, c.id
    FROM student s, course c
    WHERE s.telegram_id = tg_id AND c.name = name_;
END;
$$ LANGUAGE plpgsql;

-- Функция для добавления преподавателя
CREATE OR REPLACE FUNCTION add_teacher(surname TEXT, name TEXT, isu_id INTEGER, telegram_id INTEGER) RETURNS VOID AS
$$
BEGIN
    INSERT INTO telegram (id) VALUES (telegram_id) ON CONFLICT DO NOTHING;
    INSERT INTO prep (id, name, surname, telegram_id) VALUES (isu_id, name, surname, telegram_id);
END;
$$ LANGUAGE plpgsql;

-- Функция для добавления курса
CREATE OR REPLACE FUNCTION add_course(name_ TEXT, tg_id INTEGER) RETURNS VOID AS
$$
BEGIN
    INSERT INTO course (name, prep_id)
    SELECT name_, p.id
    FROM prep p
    WHERE p.telegram_id = tg_id;
END;
$$ LANGUAGE plpgsql;

-- Функция для добавления лабораторной работы
CREATE OR REPLACE FUNCTION add_lab(course_name TEXT, lab_name TEXT, lab_text TEXT) RETURNS VOID AS
$$
BEGIN
    INSERT INTO lab (name, task, course_id)
    SELECT lab_name, lab_text, c.id
    FROM course c
    WHERE c.name = course_name;
END;
$$ LANGUAGE plpgsql;

-- Функция для получения информации о работах студентов по лабораторной
CREATE OR REPLACE FUNCTION get_reports(course_name TEXT, lab_name TEXT, teacher_telegram_id INTEGER)
    RETURNS TABLE (message_id BIGINT, chat_id BIGINT, name TEXT, surname TEXT, "group" TEXT, isu INTEGER) AS
$$
BEGIN
    RETURN QUERY
    SELECT r.message_id, s.telegram_id, s.name, s.surname, g.number, s.id
    FROM report r
    LEFT JOIN student s ON r.student_id = s.id
    LEFT JOIN "group" g ON g.id = s.group_id
    LEFT JOIN lab l ON l.id = r.lab_id
    LEFT JOIN course c ON l.course_id = c.id
    LEFT JOIN prep p ON c.prep_id = p.id
    WHERE p.telegram_id = teacher_telegram_id AND c.name = course_name AND l.name = lab_name;
END;
$$ LANGUAGE plpgsql;

-- Функция для добавления отчета о выполненной лабораторной работе студентом
CREATE OR REPLACE FUNCTION add_report(course_name TEXT, lab_name TEXT, student_telegram_id INTEGER, message_id INTEGER) RETURNS VOID AS
$$
DECLARE
    student_id INTEGER;
    lab_id INTEGER;
BEGIN
    SELECT s.id INTO student_id
    FROM student s
    JOIN telegram t ON s.telegram_id = t.id
    WHERE t.id = student_telegram_id;

    SELECT l.id INTO lab_id
    FROM lab l
    JOIN course c ON l.course_id = c.id
    WHERE c.name = course_name AND l.name = lab_name;

    INSERT INTO report (lab_id, student_id, message_id) VALUES (lab_id, student_id, message_id);
END;
$$ LANGUAGE plpgsql;


