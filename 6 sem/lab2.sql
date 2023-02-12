--0. Создание юзера для лабы
alter session set "_oracle_script"=TRUE;
create user LAB2;

--1. Создание таблиц
create table LAB2."students"
(
    "id" number primary key,
    name  varchar2(30) not null,
    group_id number not null
);

create sequence LAB2.lab2_student
start with 1
increment by 1;

create table LAB2."groups"
(
    "id" number primary key,
    name  varchar2(30) not null,
    c_val number not null
);

create sequence LAB2.lab2_group
start with 1
increment by 1;

--2. Проверка целостности

--3. Foreign Key
CREATE OR REPLACE TRIGGER LAB2.cascade_del 
BEFORE DELETE ON LAB2."groups"
FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    DELETE FROM LAB2."students" WHERE "id" = :old."id";
    COMMIT;
END;

--4. Журналирование

--5. Восстановления информации

--6. Триггер на синхронизацию
CREATE OR REPLACE TRIGGER LAB2.sync 
AFTER INSERT OR DELETE OR UPDATE ON LAB2."students"
FOR EACH ROW
BEGIN
    IF inserting THEN
        UPDATE LAB2."groups" SET c_val=c_val+1 WHERE "id" = :NEW.group_id;
    ELSIF updating THEN
        UPDATE LAB2."groups" SET c_val=c_val+1 WHERE "id" = :NEW.group_id;
        UPDATE LAB2."groups" SET c_val=c_val-1 WHERE "id" = :OLD.group_id;
    ELSIF deleting THEN
        UPDATE LAB2."groups" SET c_val=c_val-1 WHERE "id" = :OLD.group_id;
    END IF;
END;