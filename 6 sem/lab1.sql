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

------------------------------------------------------------------------------
--Функция подсчета
create or replace function get_parity
return boolean
is
    parity_counter number;
    odd_counter number;
begin
    select COUNT(VAL) into parity_counter from MY_TABLE WHERE MOD(VAL, 2) = 0;
    select COUNT(VAL) into odd_counter from MY_TABLE WHERE MOD(VAL, 2) = 1;
    if parity_counter > odd_counter then
        return true;
    else
        return false;
    end if;
end

--Вызов функции
DECLARE
   res boolean;
BEGIN
   res := get_parity();
   if res then
        dbms_output.put_line('True');
    else
       dbms_output.put_line('False');
   end if;
END;

------------------------------------------------------------------------------
--Функция создания запроса
create or replace function get_insert (inpt_value in varchar2)
return varchar2
is
    result_str varchar2(100);
begin
    result_str := 'insert into MY_TABLE ("id", VAL) VALUES (lab1_sec.nextval, ' || inpt_value || ');';
    dbms_output.put_line(result_str);
    return result_str;
end;

--Вызов функции (с проверкой вывода)
DECLARE
   res varchar2(100);
BEGIN
   res := get_insert(123);
   dbms_output.put_line(res);
END;

--Процедуры
CREATE OR REPLACE PROCEDURE my_table_insert(new_value number)
AS
BEGIN
   insert into MY_TABLE ("id", VAL) VALUES (lab1_sec.nextval, new_value);
   commit;
END;

CREATE OR REPLACE PROCEDURE my_table_delete(del_id number)
AS
BEGIN
   delete from MY_TABLE where "id"=del_id;
    commit;
END;

CREATE OR REPLACE PROCEDURE my_table_update(updt_id number, new_value number)
AS
BEGIN
   update MY_TABLE set VAL=new_value where "id"=updt_id;
    commit;
END;