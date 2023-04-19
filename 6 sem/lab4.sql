------------------------------------------------------------------------------
--0. Создание юзеров для лабы
ALTER SESSION SET "_oracle_script"=TRUE;
CREATE USER LAB4;
ALTER USER LAB4 QUOTA UNLIMITED ON USERS;

GRANT CONNECT, RESOURCE TO LAB4;


------------------------------------------------------------------------------
--1. Тестовая зона для xpath

with demo3 as(select 1 id, XMLType('<a><b>b1</b><b>b2</b></a>') xml from dual
                  union all select 2 id, XMLType('<a><b>b3</b><b>b4</b></a>') xml from dual)
    select id xml_id
           ,extractValue(value(t),'b') result
    from demo3 s,table(XMLSequence(s.xml.extract('a/b'))) t;

with demo1 as (
select XMLType(
    ) xml
  from dual
)
select extractValue(value(t_col),'column'),
        extractValue(value(t_tab),'tab') result
    from demo1 s, table(XMLSequence(s.xml.extract('SELECT/columns/column'))) t_col 
        full join demo1 j, table(XMLSequence(j.xml.extract('SELECT/from/tab'))) t_tab ON 3 = 3;

declare 
    ref_table VARCHAR2(2000) := '<SELECT>
            <columns>
                <column>col1</column>
                <column>col2</column>
                <column>col3</column>
            </columns>
            <from>
                <tab>tab1</tab>
            </from>
            <joins>
                <join>
                    <type>LEFT JOIN</type>
                    <tab>tab2</tab>
                    <condition>tab1.col1 = tab2.col2</condition>
                </join>
                <join>
                    <type>LEFT JOIN</type>
                    <tab>tab2</tab>
                    <condition>tab1.col1 = tab2.col2</condition>
                </join>
                <join>
                    <type>LEFT JOIN</type>
                    <tab>tab2</tab>
                    <condition>tab1.col1 = tab2.col2</condition>
                </join>
                <join>
                    <type>LEFT JOIN</type>
                    <tab>tab2</tab>
                    <condition>tab1.col1 = tab2.col2</condition>
                </join>
            </joins>
        <where>
                <condition>col1 = 5</condition>
                <condition>col2 = 8</condition>
            </where>
        </SELECT>';
begin
    for tab in (select extractValue(value(t),'column') column_name
                    from table(XMLSequence(XMLType(ref_table).extract('SELECT/columns/column'))) t) LOOP
        dbms_output.put_line(tab."COLUMN_NAME"); 
    end loop;

    for tab in (select extractValue(value(t),'tab') src_tab
                    from table(XMLSequence(XMLType(ref_table).extract('SELECT/from/tab'))) t) LOOP
        dbms_output.put_line(tab."SRC_TAB"); 
    end loop;

    for tab in (select * from table(XMLSequence(l_xml.extract('SELECT/joins'))) t) loop
                    
    end loop;

    for tab in (select extractValue(value(t),'condition') CONDITION
                    from table(XMLSequence(XMLType(ref_table).extract('SELECT/where/condition'))) t) LOOP
        dbms_output.put_line(tab."CONDITION"); 
    end loop;
end;

