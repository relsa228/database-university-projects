------------------------------------------------------------------------------
--Тестовые таблицы
create table LAB3_DEV."groups"
(
    "id" number primary key,
    "name"  varchar2(30) not null,
    c_val number not null
);

create table LAB3_PROD."groups"
(
    "id" number primary key,
    "name"  varchar2(30) not null,
    c_val number not null
);

create table LAB3_DEV."students"
(
    "id" number primary key,
    "name"  varchar2(30) not null,
    group_id number not null
);

DROP TABLE LAB3_DEV."supplier";
CREATE TABLE LAB3_DEV."supplier"
( supplier_id numeric(10) not null,
  supplier_name varchar2(50) not null,
  contact_name varchar2(50),
  CONSTRAINT supplier_pk PRIMARY KEY (supplier_id)
);

DROP TABLE LAB3_DEV."products";
CREATE TABLE LAB3_DEV."products"
( product_id numeric(10) not null,
  supplier_id numeric(10) not null,
  CONSTRAINT fk_supplier
    FOREIGN KEY (supplier_id)
    REFERENCES  LAB3_DEV."supplier"(supplier_id)
);


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

DROP table DIST_TABLES;
DROP table OUT_TABLES;
create table DIST_TABLES (
        "t_name"  varchar2(128) not null
    );

create table OUT_TABLES (
    "t_name"  varchar2(128) not null
);
------------------------------------------------------------------------------
--1. Сравнение таблиц
DECLARE
    dev_schema varchar2(225) := 'LAB3_DEV';
    prod_schema varchar2(225) := 'LAB3_PROD';

    ref_table varchar2(225);
    ref_constrain varchar2(225);

    tab_count NUMBER;
    clmn_count NUMBER;
    dist_tab_count NUMBER;
    ref_table_count NUMBER;

    input_flag BOOLEAN := TRUE;

    funct_count NUMBER;
    f1_arg_count NUMBER;
    f2_arg_count NUMBER;
    arg_count NUMBER;

    ddl_out varchar2(225);
    funct_ending varchar2(225);
BEGIN

--Модуль обхода дев таблицы и поиска отличий
    for tab in (select * from ALL_TABLES WHERE OWNER=dev_schema) loop
        SELECT COUNT(*) INTO tab_count FROM ALL_TABLES WHERE OWNER=prod_schema AND TABLE_NAME=tab.TABLE_NAME;
        IF tab_count=1 THEN
            for clmn in (SELECT * FROM ALL_TAB_COLUMNS WHERE table_name=tab.TABLE_NAME AND OWNER=dev_schema) loop 
                SELECT COUNT(*) INTO clmn_count FROM ALL_TAB_COLUMNS WHERE  OWNER=prod_schema AND 
                                                                            COLUMN_NAME=clmn.COLUMN_NAME AND
                                                                            DATA_TYPE=clmn.DATA_TYPE AND 
                                                                            DATA_LENGTH=clmn.DATA_LENGTH;
                IF clmn_count=0 THEN
                    INSERT INTO DIST_TABLES VALUES (tab.TABLE_NAME);
                END IF;
                EXIT WHEN clmn_count=0;
            END LOOP;
        ELSE
            INSERT INTO DIST_TABLES VALUES (tab.TABLE_NAME);
        END IF;
    END LOOP;

--Модуль проверки форен кея
    SELECT COUNT(*) INTO dist_tab_count FROM DIST_TABLES;
    WHILE dist_tab_count <> 0 LOOP
        for tab in (SELECT * FROM DIST_TABLES) LOOP
            for f_key in (SELECT * FROM ALL_CONSTRAINTS WHERE OWNER=dev_schema AND table_name=tab."t_name" AND CONSTRAINT_TYPE='R') loop
                SELECT TABLE_NAME into ref_table from ALL_CONSTRAINTS WHERE CONSTRAINT_NAME=f_key.R_CONSTRAINT_NAME;

                SELECT COUNT(*) into ref_table_count FROM OUT_TABLES WHERE "t_name"=ref_table;

                if ref_table_count=0 then
                    input_flag:=FALSE;
                END IF;
            end loop;

            IF input_flag THEN
                DELETE FROM DIST_TABLES WHERE "t_name"=tab."t_name";
                INSERT INTO OUT_TABLES VALUES (tab."t_name");
            END IF;
            input_flag:=TRUE;
        END LOOP;
        SELECT COUNT(*) INTO dist_tab_count FROM DIST_TABLES;
    END LOOP;

    dbms_output.put_line('--------TABLES--------');
    for tab in (SELECT * FROM OUT_TABLES) LOOP
        dbms_output.put_line(tab."t_name"); 
    END LOOP;

--Модуль проверки функций (выводит)
    dbms_output.put_line('----FUNCTIONS----');
    for funct in (select * from all_objects WHERE object_type='FUNCTION' AND owner=dev_schema) loop
        select COUNT(*) into funct_count from all_objects where owner=prod_schema and object_type='FUNCTION' and object_name=funct.object_name;
        if funct_count=0 THEN
            dbms_output.put_line(funct.object_name);
            ddl_out := 'CREATE OR REPLACE FUNCTION ' || prod_schema || '.' || funct.object_name || ' (';
            dbms_output.put_line(ddl_out);
            for proc_out in (SELECT * from ALL_ARGUMENTS where owner=dev_schema AND OBJECT_NAME=funct.object_name AND POSITION<>0 AND PACKAGE_NAME IS NULL) loop
                ddl_out := proc_out.DATA_TYPE || ' ' || proc_out.ARGUMENT_NAME;
                dbms_output.put_line(ddl_out);
            end loop;
            dbms_output.put_line(')');
            SELECT DATA_TYPE into funct_ending from ALL_ARGUMENTS where owner=prod_schema AND OBJECT_NAME=funct.object_name AND POSITION=0;
            funct_ending := 'return ' || funct_ending;
            dbms_output.put_line(funct_ending);
        ELSE
            SELECT count(*) into f1_arg_count from ALL_ARGUMENTS where owner=dev_schema AND OBJECT_NAME=funct.object_name;
            SELECT count(*) into f2_arg_count from ALL_ARGUMENTS where owner=prod_schema AND OBJECT_NAME=funct.object_name;
            if f1_arg_count <> f2_arg_count then
                dbms_output.put_line(funct.object_name);
                ddl_out := 'CREATE OR REPLACE FUNCTION ' || prod_schema || '.' || funct.object_name || ' (';
                dbms_output.put_line(ddl_out);
                for proc_out in (SELECT * from ALL_ARGUMENTS where owner=dev_schema AND OBJECT_NAME=funct.object_name AND POSITION<>0 AND PACKAGE_NAME IS NULL) loop
                    ddl_out := proc_out.DATA_TYPE || ' ' || proc_out.ARGUMENT_NAME;
                    dbms_output.put_line(ddl_out);
                end loop;
                dbms_output.put_line(')');
                SELECT DATA_TYPE into funct_ending from ALL_ARGUMENTS where owner=prod_schema AND OBJECT_NAME=funct.object_name AND POSITION=0;
                funct_ending := 'return ' || funct_ending;
                dbms_output.put_line(funct_ending);
            else
                for arg in (select * from ALL_ARGUMENTS where owner=dev_schema AND OBJECT_NAME=funct.object_name) loop
                    if arg.position=0 THEN
                        SELECT count(*) into arg_count from ALL_ARGUMENTS where owner=prod_schema AND OBJECT_NAME=funct.object_name and DATA_TYPE=arg.DATA_TYPE and POSITION=0;
                        if arg_count=0 THEN
                            dbms_output.put_line(funct.object_name);
                            ddl_out := 'CREATE OR REPLACE FUNCTION ' || prod_schema || '.' || funct.object_name || ' (';
                            dbms_output.put_line(ddl_out);
                            for proc_out in (SELECT * from ALL_ARGUMENTS where owner=dev_schema AND OBJECT_NAME=funct.object_name AND POSITION<>0 AND PACKAGE_NAME IS NULL) loop
                                ddl_out := proc_out.DATA_TYPE || ' ' || proc_out.ARGUMENT_NAME;
                                dbms_output.put_line(ddl_out);
                            end loop;
                            dbms_output.put_line(')');
                            SELECT DATA_TYPE into funct_ending from ALL_ARGUMENTS where owner=prod_schema AND OBJECT_NAME=funct.object_name AND POSITION=0;
                            funct_ending := 'return ' || funct_ending;
                            dbms_output.put_line(funct_ending);
                        end if;
                    else
                        SELECT count(*) into arg_count from ALL_ARGUMENTS where owner=prod_schema AND OBJECT_NAME=funct.object_name and DATA_TYPE=arg.DATA_TYPE;
                        if arg_count=0 THEN
                            dbms_output.put_line(funct.object_name);
                            ddl_out := 'CREATE OR REPLACE FUNCTION ' || prod_schema || '.' || funct.object_name || ' (';
                            dbms_output.put_line(ddl_out);
                            for proc_out in (SELECT * from ALL_ARGUMENTS where owner=dev_schema AND OBJECT_NAME=funct.object_name AND POSITION<>0 AND PACKAGE_NAME IS NULL) loop
                                ddl_out := proc_out.DATA_TYPE || ' ' || proc_out.ARGUMENT_NAME;
                                dbms_output.put_line(ddl_out);
                            end loop;
                            dbms_output.put_line(')');
                            SELECT DATA_TYPE into funct_ending from ALL_ARGUMENTS where owner=prod_schema AND OBJECT_NAME=funct.object_name AND POSITION=0;
                            funct_ending := 'return ' || funct_ending;
                            dbms_output.put_line(funct_ending);
                        end if;
                    end if;
                end loop;
            end if;
        end if;
    end loop;

--Модуль проверки процедур (выводит)
    dbms_output.put_line('----PROCEDURE----');
    for funct in (select * from all_objects WHERE object_type='PROCEDURE' AND owner=dev_schema) loop
        select COUNT(*) into funct_count from all_objects where owner=prod_schema and object_type='PROCEDURE' and object_name=funct.object_name;
        if funct_count=0 THEN
            dbms_output.put_line(funct.object_name);
            ddl_out := 'CREATE OR REPLACE PROCEDURE ' || prod_schema || '.' || funct.object_name || ' (';
            dbms_output.put_line(ddl_out);
            for proc_out in (SELECT * from ALL_ARGUMENTS where owner=dev_schema AND OBJECT_NAME=funct.object_name) loop
                ddl_out := proc_out.ARGUMENT_NAME || ' in ' || proc_out.DATA_TYPE;
                dbms_output.put_line(ddl_out);
            end loop;
            dbms_output.put_line(')');
        ELSE
            SELECT count(*) into f1_arg_count from ALL_ARGUMENTS where owner=dev_schema AND OBJECT_NAME=funct.object_name;
            SELECT count(*) into f2_arg_count from ALL_ARGUMENTS where owner=prod_schema AND OBJECT_NAME=funct.object_name;
            
            if f1_arg_count <> f2_arg_count then
                dbms_output.put_line(funct.object_name);
                ddl_out := 'CREATE OR REPLACE PROCEDURE ' || prod_schema || ' . ' || funct.object_name || ' (';
                dbms_output.put_line(ddl_out);
                for proc_out in (SELECT * from ALL_ARGUMENTS where owner=dev_schema AND OBJECT_NAME=funct.object_name) loop
                    ddl_out := proc_out.ARGUMENT_NAME || ' in ' || proc_out.DATA_TYPE;
                    dbms_output.put_line(ddl_out);
                end loop;
                dbms_output.put_line(')');
            else
                for arg in (select * from ALL_ARGUMENTS where owner=dev_schema AND OBJECT_NAME=funct.object_name) loop
                    SELECT count(*) into arg_count from ALL_ARGUMENTS where owner=prod_schema AND OBJECT_NAME=funct.object_name and DATA_TYPE=arg.DATA_TYPE;
                    if arg_count=0 THEN
                        dbms_output.put_line(funct.object_name);
                        ddl_out := 'CREATE OR REPLACE PROCEDURE ' || prod_schema || '.' || funct.object_name || ' (';
                        dbms_output.put_line(ddl_out);
                        for proc_out in (SELECT * from ALL_ARGUMENTS where owner=dev_schema AND OBJECT_NAME=funct.object_name) loop
                            ddl_out := proc_out.ARGUMENT_NAME || ' in ' || proc_out.DATA_TYPE;
                            dbms_output.put_line(ddl_out);
                        end loop;
                        dbms_output.put_line(')');
                    end if;
                end loop;
            end if;
        end if;
    end loop;

--Модуль проверки пакетов
    dbms_output.put_line('----Packages----');
    for pkg in (select * from all_objects WHERE object_type='PACKAGE' AND owner=dev_schema) loop
        select COUNT(*) into funct_count from all_objects where owner=prod_schema and object_type='PACKAGE' and object_name=pkg.OBJECT_NAME;
        if funct_count=0 THEN
            dbms_output.put_line(pkg.object_name);
        ELSE
            SELECT count(*) into f1_arg_count from all_procedures where owner=dev_schema AND OBJECT_NAME=pkg.OBJECT_NAME;
            SELECT count(*) into f2_arg_count from all_procedures where owner=prod_schema AND OBJECT_NAME=pkg.OBJECT_NAME;
            
            if f1_arg_count <> f2_arg_count then
                dbms_output.put_line(pkg.object_name);
            else
                for proc_pkg in (select * from all_procedures where owner=dev_schema and object_name=pkg.object_name) loop
                    if proc_pkg.SUBPROGRAM_ID<>0 then
                        select COUNT(*) into funct_count from all_procedures where owner=prod_schema and object_name=pkg.object_name and PROCEDURE_NAME=proc_pkg.PROCEDURE_NAME;
                        if funct_count=0 THEN
                            dbms_output.put_line(pkg.object_name);
                        end if;
                    end if;
                end loop;
            end if;
        end if;
    end loop;
END;


SELECT "t_name" FROM DIST_TABLES

SELECT * FROM ALL_TAB_COLUMNS WHERE OWNER='LAB3_DEV';
SELECT * FROM ALL_CONSTRAINTS WHERE OWNER='LAB3_DEV';
SELECT * FROM ALL_TAB_COLUMNS WHERE table_name='ALL_CONSTRAINTS';

------------------------------------------------------------------------------
--2. Сравнение функций
select *
from   all_objects
where  owner = 'LAB3_DEV'
and    object_type = 'PROCEDURE';

select * from ALL_ARGUMENTS where owner='LAB3_DEV' and OBJECT_NAME='HELLO_SECOND';

create or replace function LAB3_dev.hello
return number
is
    parity_counter number;
    odd_counter number;
begin
    dbms_output.put_line('Hello'); 
    return 1;
end;

create or replace function LAB3_prod.hello_second(salary in number, percent in VARCHAR2)
return number
is
    parity_counter number;
    odd_counter number;
begin
    dbms_output.put_line('Hello'); 
    return 1;
end;

CREATE OR REPLACE PROCEDURE LAB3_prod.hello_proc(start_time IN VARCHAR2, end_time IN number)
IS
   cnumber number;
BEGIN
    dbms_output.put_line('Hello'); 
END hello_proc;

drop procedure LAB3_prod.hello_proc;
drop procedure LAB3_dev.hello_proc;

drop function LAB3_dev.hello_second;
drop function LAB3_dev.hello;

drop function LAB3_prod.hello_second;
drop function LAB3_prod.hello;

CREATE or replace PACKAGE LAB3_PROD.TESTPKG AS 
   PROCEDURE hello_second(salary in number, percent in VARCHAR2);
END TESTPKG;


drop PACKAGE LAB3_dev.cust_sal;

select * from all_objects WHERE object_type='PACKAGE' AND owner='LAB3_DEV';
select * from all_procedures where owner='LAB3_DEV' and object_name='TESTPKG';