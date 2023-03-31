------------------------------------------------------------------------------
--0. Создание юзеров для лабы
ALTER SESSION SET "_oracle_script"=TRUE;
CREATE USER LAB3_DEV;
ALTER USER LAB3_DEV QUOTA UNLIMITED ON USERS;

ALTER SESSION SET "_oracle_script"=TRUE;
CREATE USER LAB3_PROD;
ALTER USER LAB3_PROD QUOTA UNLIMITED ON USERS;

GRANT CONNECT, RESOURCE TO LAB3_DEV;
GRANT CONNECT, RESOURCE TO LAB3_PROD;

------------------------------------------------------------------------------
--1. Сравнение таблиц
DECLARE
    schema1 varchar2(225) := 'LAB2';
BEGIN
    for itm in (select * from ALL_TABLES WHERE OWNER=schema1) loop
        dbms_output.put_line(itm.TABLE_NAME);
    END LOOP;
END;