--Создание таблицы
create table "MY_TABLE"
(
    "id" number primary key,
    val  number not null
)

--Создание автоинкремента
create sequence lab1_sec
start with 1
increment by 1;

--Заполнение значениями
declare
    random_num Number;
begin
    DBMS_OUTPUT.PUT_LINE(random_num);

    FOR i IN 15 ..10000 LOOP
        select round(DBMS_RANDOM.value(low => 1, high => 1000)) into random_num from dual;
        insert into MY_TABLE ("id", VAL) VALUES (lab1_sec.nextval, random_num);
    END LOOP;
end;