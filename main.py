import telebot
import datetime
import time
import psycopg2
import re

import config

bot = telebot.TeleBot(config.TELEGRAM_KEY)


# Student zone start
@bot.message_handler(commands=['start', 'register'])
def register(message):
    try:
        args = message.text.split()
        if len(args) != 5:
            bot.reply_to(message, r'Вы должны указать свои данные: Фамилия Имя Группа ИСУ\.'
                                  '\nПример: `/register Радмир Кирпич P33081 335000`', parse_mode='MarkdownV2')
            return
        surname, name, group, isu = args[1:]

        conn = psycopg2.connect(config.DATABASE_URL, sslmode='require')
        c = conn.cursor()
        c.execute('insert into telegram (id) values (%s) on conflict do nothing', (message.from_user.id,))
        c.execute('insert into student (id, name, surname, group_id, telegram_id) '
                  '(select %s, %s, %s, id, %s from "group" where number = %s)',
                  (int(isu), name, surname, message.from_user.id, group))
        conn.commit()
        c.close()
        conn.close()
        bot.set_message_reaction(message.chat.id, message.id, [telebot.types.ReactionTypeEmoji("👍")])
    except Exception as ex:
        bot.set_message_reaction(message.chat.id, message.id, [telebot.types.ReactionTypeEmoji("👎")])
        bot.reply_to(message, f'{ex}')


@bot.message_handler(commands=['delete_me'])
def delete_user(message):
    try:
        conn = psycopg2.connect(config.DATABASE_URL, sslmode='require')
        c = conn.cursor()
        c.execute('delete from student where telegram_id = %s', (message.from_user.id,))
        conn.commit()
        c.close()
        conn.close()
        bot.set_message_reaction(message.chat.id, message.id, [telebot.types.ReactionTypeEmoji("👍")])
    except Exception as ex:
        bot.set_message_reaction(message.chat.id, message.id, [telebot.types.ReactionTypeEmoji("👎")])
        bot.reply_to(message, f'{ex}')


@bot.message_handler(commands=['whoami'])
def delete_user(message):
    try:
        conn = psycopg2.connect(config.DATABASE_URL, sslmode='require')
        c = conn.cursor()
        c.execute('select name, surname, "group".number, student.id from student '
                  'left join "group" on student.group_id = "group".id '
                  'where telegram_id = %s', (message.from_user.id,))

        name, surname, group, isu = c.fetchone()
        c.close()
        conn.close()

        bot.reply_to(message, f"Вы - {surname} {name} ИСУ №{isu}, группа {group}")
    except Exception as ex:
        bot.set_message_reaction(message.chat.id, message.id, [telebot.types.ReactionTypeEmoji("👎")])
        bot.reply_to(message, f'{ex}')


@bot.message_handler(commands=['apply_to_course'])  # TODO make inline
def apply_to_course(message):
    try:
        args = message.text.split()
        if len(args) < 2:
            bot.reply_to(message, r'Вы должны указать название курса\.'
                                  '\nПример: `/apply_to_course Информационные системы и базы данных`',
                         parse_mode='MarkdownV2')
            return
        name = ' '.join(args[1:])

        conn = psycopg2.connect(config.DATABASE_URL, sslmode='require')
        c = conn.cursor()
        c.execute('insert into student_course (student_id, course_id) '
                  '(select s.id, c.id from student s, course c '
                  'where s.telegram_id = %s and c.name = %s)',
                  (message.from_user.id, name))
        conn.commit()
        c.close()
        conn.close()
        bot.set_message_reaction(message.chat.id, message.id, [telebot.types.ReactionTypeEmoji("👍")])
    except Exception as ex:
        bot.set_message_reaction(message.chat.id, message.id, [telebot.types.ReactionTypeEmoji("👎")])
        bot.reply_to(message, f'{ex}')


@bot.message_handler(commands=['send'])  # TODO make inline
def send(message):
    bot.reply_to(message, r'Вы должны загрузить файл и указать название курса и название лабораторной работы\.'
                          '\nПример: `Информационные системы и базы данных'
                          '\nЛабораторная работа #1`',
                 parse_mode='MarkdownV2')
# student zone end


# teacher zone start
@bot.message_handler(commands=['add_prep'])
def add_prep(message):
    try:
        args = message.text.split()
        if len(args) != 5:
            bot.reply_to(message, r'Вы должны указать свои данные: Фамилия Имя ИСУ Telegram\_ID\.'
                                  '\nПример: `/add_prep Виктор Сапёр 335000 0`', parse_mode='MarkdownV2')
            return
        name, surname, isu, tg_id = args[1:]

        conn = psycopg2.connect(config.DATABASE_URL, sslmode='require')
        c = conn.cursor()
        c.execute('insert into telegram (id) values (%s) on conflict do nothing', (message.from_user.id,))
        c.execute('insert into prep (id, name, surname, telegram_id) '
                  'values (%s, %s, %s, %s)',
                  (int(isu), name, surname, tg_id))
        conn.commit()
        c.close()
        conn.close()
        bot.set_message_reaction(message.chat.id, message.id, [telebot.types.ReactionTypeEmoji("👍")])
    except Exception as ex:
        bot.set_message_reaction(message.chat.id, message.id, [telebot.types.ReactionTypeEmoji("👎")])
        bot.reply_to(message, f'{ex}')


@bot.message_handler(commands=['add_course'])
def add_course(message):
    try:
        args = message.text.split()
        if len(args) < 2:
            bot.reply_to(message, r'Вы должны указать название курса\.'
                                  '\nПример: `/add_course Информационные системы и базы данных`',
                         parse_mode='MarkdownV2')
            return
        name = ' '.join(args[1:])

        conn = psycopg2.connect(config.DATABASE_URL, sslmode='require')
        c = conn.cursor()
        c.execute('insert into course (name, prep_id) '
                  '(select %s, prep.id from prep where telegram_id = %s)',
                  (name, message.from_user.id))
        conn.commit()
        c.close()
        conn.close()
        bot.set_message_reaction(message.chat.id, message.id, [telebot.types.ReactionTypeEmoji("👍")])
    except Exception as ex:
        bot.set_message_reaction(message.chat.id, message.id, [telebot.types.ReactionTypeEmoji("👎")])
        bot.reply_to(message, f'{ex}')


@bot.message_handler(commands=['add_lab'])  # TODO make inline
def add_lab(message):
    try:
        args = message.text.split('\n')
        if len(args) != 3:
            bot.reply_to(message, r'Вы должны указать название курса и название лабораторной работы\.'
                                  '\nПример: `/add_lab Информационные системы и базы данных'
                                  '\nЛабораторная работа #1'
                                  '\nСоставить запросы на языке SQL (пункты 1-2).`',
                         parse_mode='MarkdownV2')
            return
        course_name = args[0][len('/add_lab '):]
        lab_name = args[1]
        lab_text = args[1]

        conn = psycopg2.connect(config.DATABASE_URL, sslmode='require')
        c = conn.cursor()
        c.execute('insert into lab (name, task, course_id) '
                  '(select %s, %s, id from course where course.name = %s)',
                  (lab_name, lab_text, course_name))
        conn.commit()
        c.close()
        conn.close()
        bot.set_message_reaction(message.chat.id, message.id, [telebot.types.ReactionTypeEmoji("👍")])
    except Exception as ex:
        bot.set_message_reaction(message.chat.id, message.id, [telebot.types.ReactionTypeEmoji("👎")])
        bot.reply_to(message, f'{ex}')


@bot.message_handler(commands=['get'])  # TODO make inline
def get(message):
    try:
        args = message.text.split('\n')
        if len(args) != 2:
            bot.reply_to(message, r'Вы должны указать название курса и название лабораторной работы\.'
                                  '\nПример: `/get Информационные системы и базы данных'
                                  '\nЛабораторная работа #1`',
                         parse_mode='MarkdownV2')
            return
        course_name = args[0][len('/get '):]
        lab_name = args[1]

        conn = psycopg2.connect(config.DATABASE_URL, sslmode='require')
        c = conn.cursor()
        c.execute('select message_id, s.telegram_id, s.name, s.surname, g.number, s.id from report '
                  'left join student s on report.student_id = s.id '
                  'left join "group" g on g.id = s.group_id '
                  'left join lab l on l.id = report.lab_id '
                  'left join course c on l.course_id = c.id '
                  'left join prep p on c.prep_id = p.id '
                  'where p.telegram_id = %s and c.name = %s and l.name = %s',
                  (message.from_user.id, course_name, lab_name))

        for report in c:
            message_id, chat_id, name, surname, group, isu = report
            sent_message = bot.forward_message(message.chat.id, chat_id, message_id)
            bot.reply_to(sent_message, f'Работа {surname} {name} {group}, ИСУ {isu}')

        c.close()
        conn.close()
    except Exception as ex:
        bot.set_message_reaction(message.chat.id, message.id, [telebot.types.ReactionTypeEmoji("👎")])
        bot.reply_to(message, f'{ex}')
# teacher zone end


# util zone start
@bot.message_handler(commands=['id'])
def id_(message):
    bot.reply_to(message, f'Ваш ID телеграм: `{message.from_user.id}`', parse_mode='MarkdownV2')
# util zone end


# student zone 2
@bot.message_handler(func=lambda x: True, content_types=['document'])  # TODO make inline & remove caption
def send(message):
    try:
        if message.caption is None:
            bot.reply_to(message, r'Вы должны загрузить файл и указать название курса и название лабораторной работы\.'
                                  '\nПример: `Информационные системы и базы данных'
                                  '\nЛабораторная работа #1`',
                         parse_mode='MarkdownV2')
            return
        args = message.caption.split('\n')
        if len(args) != 2:
            bot.reply_to(message, r'Вы должны загрузить файл и указать название курса и название лабораторной работы\.'
                                  '\nПример: `Информационные системы и базы данных'
                                  '\nЛабораторная работа #1`',
                         parse_mode='MarkdownV2')
            return
        course_name = args[0]
        lab_name = args[1]

        conn = psycopg2.connect(config.DATABASE_URL, sslmode='require')
        c = conn.cursor()
        c.execute('insert into report (lab_id, student_id, message_id) '
                  '(select l.id, s.id, %s from lab l left join course c on l.course_id = c.id, student s '
                  'where s.telegram_id = %s and c.name = %s and l.name = %s)',
                  (message.id, message.from_user.id, course_name, lab_name))
        conn.commit()
        c.close()
        conn.close()
        bot.set_message_reaction(message.chat.id, message.id, [telebot.types.ReactionTypeEmoji("👍")])
    except Exception as ex:
        bot.set_message_reaction(message.chat.id, message.id, [telebot.types.ReactionTypeEmoji("👎")])
        bot.reply_to(message, f'{ex}')


# teacher zone 2
@bot.message_handler(func=lambda x: True)
def reply_with_mark(message):
    try:
        if message.reply_to_message is None:
            bot.reply_to(message, "Вы должны ответить на документ")
            return

        if message.reply_to_message.document is not None:
            bot.send_message(message.reply_to_message.forward_from.id, message.reply_to_message.caption + ":\n" + message.text)
        else:
            bot.reply_to(message, "Вы должны ответить на документ")
            return

        bot.set_message_reaction(message.chat.id, message.id, [telebot.types.ReactionTypeEmoji("👍")])
    except Exception as ex:
        bot.set_message_reaction(message.chat.id, message.id, [telebot.types.ReactionTypeEmoji("👎")])
        bot.reply_to(message, f'{ex}')


if __name__ == "__main__":
    try:
        print(f'I am @{bot.get_me().username} and I started at '
              f'{datetime.datetime.isoformat(datetime.datetime.now())}')
        bot.polling()
    except InterruptedError:
        exit(0)
    except Exception as exception:
        print(exception)
        time.sleep(10)
