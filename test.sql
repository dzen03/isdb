insert into telegram (id) values (1), (2), (3);


insert into "group" (number) values ('P00000'), ('P00001'), ('P00002');


insert into student (id, name, surname, group_id, telegram_id) values 
(1, 'Тимурка', 'Промах', 1, 1),
(2, 'Артёмка', 'Самурай', 2, 2),
(3, 'Андрей', 'Воркута', 3, 3);


insert into prep (id, name, surname) values (1, 'Святополк', 'Лютый'), (2, 'Савелий', 'Верховный');


insert into course (prep_id, name) values (1, 'ИСБД'), (2, 'LLP');


insert into example (message_id) values (123), (456), (789);


insert into lab (course_id, name, task, example_id) values 
(1, 'Курсовая', 'Напишите курсовую работу', 1),
(1, 'Лабораторная 1', 'Сделайте лабу 1', 2),
(2, 'Лабораторная 2', 'Сделайте лабу 2', 3);


insert into report_status (str) values ('не проверен'), ('принят'), ('не принят');


insert into student_course (student_id, course_id) values
(1, 1),
(2, 2),
(3, 1);


insert into report (lab_id, status_id, student_id, message_id) values 
(1, 1, 1, 123),
(3, 2, 2, 456),
(2, 1, 3, 123);


