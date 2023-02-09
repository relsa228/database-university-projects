--1. Создание таблиц
create table "students"
(
    "id" number primary key,
    name  varchar2(30) not null,
    group_id number not null
);

create sequence lab2_student
start with 1
increment by 1;

create table "groups"
(
    "id" number primary key,
    name  varchar2(30) not null,
    c_val number not null
);

create sequence lab2_group
start with 1
increment by 1;

--2. Проверка целостности
--3. Foreign Key
--4. Журналирование
--5. Восстановления информации
--6. Триггер на синхронизацию
