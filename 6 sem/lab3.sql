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

create table DIST_TABLES (
        "t_name"  varchar2(128) not null
    );

    create table OUT_TABLES (
        "t_name"  varchar2(128) not null
    )

DROP table DIST_TABLES;
DROP table OUT_TABLES;
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

    for tab in (SELECT * FROM OUT_TABLES) LOOP
        dbms_output.put_line(tab."t_name"); 
    END LOOP;
END;


SELECT "t_name" FROM DIST_TABLES

SELECT * FROM ALL_TAB_COLUMNS WHERE OWNER='LAB3_DEV';
SELECT * FROM ALL_CONSTRAINTS WHERE OWNER='LAB3_DEV';
SELECT * FROM ALL_TAB_COLUMNS WHERE table_name='ALL_CONSTRAINTS';