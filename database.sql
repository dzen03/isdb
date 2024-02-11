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
