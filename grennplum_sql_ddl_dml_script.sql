CREATE SCHEMA e_ilicheva;

-- 1. DISTRIBUTION
-- Создать таблицу на основе внешней таблицы `yndx_metrica.dds.ext_raw_yndx_metrica_logs`
-- с наиболее оптимальной структурой для хранения и выполнения запросов с учетом потребности аналитиков выполнять регулярные запросы
-- с наличием предикатов по полям




select * from yndx_metrica.dds.ext_raw_yndx_metrica_logs limit 5;

-- 2. EXCHANGE PARTITION
-- Создайте staging  таблицу выгрузкой последней партиции (например, по дате) из таблицы п.1.
-- Измените значение ключа партицирования и создайте новую партицию в исходной таблице при помощи Direct Partition Exchange


-- 3. GPFDIST
-- Используя gpfdist  создать внешнюю таблицу с источником в контейнере с GreenPlum (например, `gpdb@greenplum:/home/gpdb/countries.csv`) (домашняя директория пользователя под которым запущен сервер) (если файла нет - залить из файла во вложении)
-- Создать таблицу (справочник) на основе данных из внешней таблицы
-- Оптимизировать структуру хранения с учетом потребности использования для соединения с таблицей из п. 1

-- 4. EXTERNAL
-- Создать внешнюю таблицу с хранением данных в hdfs /data/raw/ в формате parquet (назвать по своему усмотрению). Наполнить данными из таблицы п. 3. Вывести кол-во записей в таблице

-- 5. COMPLEX TASK 
-- Создадим внешнюю таблицу на данных hdfs
-- DROP EXTERNAL TABLE e_ilicheva.stock_market_data_ext;
CREATE READABLE EXTERNAL TABLE e_ilicheva.stock_market_data_ext (
    tradeno BIGINT,
    trade_session_date TEXT,
    tradetime TEXT,
    secid TEXT,
    boardid TEXT,
    price DOUBLE PRECISION,
    quantity BIGINT,
    value DOUBLE PRECISION,
    buysell TEXT,
    title TEXT,
    isin TEXT,
    qualified_investor TEXT
)
LOCATION ('pxf://moex_labs/eilicheva_stock_market_securities_20260604.parquet?PROFILE=hdfs:parquet&SERVER=default&HOST="IP"&PORT=xxxx')
FORMAT 'CUSTOM' (FORMATTER='pxfwritable_import');
--SELECT * FROM e_ilicheva.stock_market_data_ext LIMIT 5;

/*
Сопоствим поля из hdfs-файла и требуемые по заданию:
BOARD_NAME - title
ISQUALIFIEDINVESTORS - qualified_investor
DEAL_TYPE - BUYSELL
DEAL_TIME - TRADETIME
 */

-- Создадим внутреннюю таблицу 
-- DROP TABLE e_ilicheva.stock_market_data_int;
CREATE TABLE e_ilicheva.stock_market_data_int (
    tradeno BIGINT,
    boardid TEXT,
    board_name TEXT,
    isin TEXT,
    isqualifiedinvestors bool,
    secid TEXT,
    price DOUBLE PRECISION,
    value DOUBLE PRECISION,
    quantity BIGINT,
    deal_type TEXT,
    deal_time Time,
    trade_session_date Date
)
with
(
appendonly = true,
orientation = column,
compresstype = zstd,
compresslevel = 1
)
distributed by(tradeno);

-- Заполним внутреннюю таблицу данными из внешней таблицы
insert into e_ilicheva.stock_market_data_int
select tradeno, 
       boardid,
       title,
       isin,
       case
        when qualified_investor is not null then true
        else false
       end,
       secid,
       price,
       value,
       quantity,
       case
        when buysell = 'B' then 'buy'
        when buysell = 'S' then 'sell'
       end,
       tradetime::time,
       trade_session_date::date
from e_ilicheva.stock_market_data_ext;

analyse e_ilicheva.stock_market_data_int;

SELECT * FROM e_ilicheva.stock_market_data_int LIMIT 10;

/*
 Найти самые крупные сделки для конкретной акции для каждого типа (BUY / SELL) в разрезе дня
 Витрина составляется для определенного тикера акции
 Моя фамилия Ilicheva, возьму тикер IGST.
 Необходимо оптимизировать хранение и использование витрины
 */

-- выберем secid = 'IGST'
SELECT * FROM e_ilicheva.stock_market_data_int
WHERE secid = 'IGST' 
ORDER BY value DESC, deal_time
LIMIT 10;

select count(distinct secid) from e_ilicheva.stock_market_data_int;

-- создадим витрину
create or replace view e_ilicheva.stock_market_big_deal as
select tradeno,
       boardid,
       board_name,
       isin,
       isqualifiedinvestors,
       secid,
       price,
       value,
       quantity,
       deal_type,
       deal_time,
       trade_session_date
from (select *,
             row_number() over(partition by secid, deal_type order by value desc, deal_time) as flag_deal_num 
      from e_ilicheva.stock_market_data_int 
      where secid = 'IGST') as t
where flag_deal_num = 1;

-- проанализируем производительность
explain analyse
select * from e_ilicheva.stock_market_big_deal;

