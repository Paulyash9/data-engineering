DROP TABLE IF EXISTS product_dim; -- done

CREATE TABLE product_dim
(
 product_id   serial NOT NULL,
 product_name varchar(127) NOT NULL,
 subcategory  varchar(50) NOT NULL,
 category     varchar(50) NOT NULL,
 CONSTRAINT PK_product PRIMARY KEY ( product_id )
);

insert into product_dim
select 
		100+row_number() over (), -- product_id
		product_name, subcategory, category from (select distinct product_name, subcategory, category from orders) pn; -- product_name

select * from product_dim pd ;


DROP TABLE IF EXISTS ship_dim; -- done

CREATE TABLE ship_dim
(
 ship_id   serial NOT NULL,
 ship_mode varchar(50) NOT NULL,
 CONSTRAINT PK_shipping PRIMARY KEY ( ship_id )
);

insert into ship_dim
select 
		100+row_number() over (), 
		ship_mode from (select distinct ship_mode from orders) a;


DROP TABLE IF EXISTS geo_dim; -- done

CREATE TABLE geo_dim
(
 geo_id      serial NOT NULL,
 country     varchar(30) NOT NULL,
 city        varchar(50) NOT NULL,
 state       varchar(50) NOT NULL,
 region      varchar(50) NOT NULL,
 postal_code int NULL,
 CONSTRAINT PK_geography PRIMARY KEY ( geo_id )
);

insert into geo_dim 
select 
		100+row_number() over ()
		,country
		,city
		,state
		,region
		,postal_code 
from (select distinct country, city, state, region, postal_code from orders) c;


DROP TABLE IF EXISTS customer_dim; -- done

CREATE TABLE customer_dim
(
 customer_id   serial NOT NULL,
 customer_name varchar(50) NOT NULL,
 segment       varchar(50) NOT NULL,
 CONSTRAINT PK_customer_dim PRIMARY KEY ( customer_id )
);

insert into customer_dim
select 
		100+row_number() over(), 
		customer_name, 
		segment 
			from (select distinct customer_name, segment from orders) b;


DROP TABLE IF EXISTS calendar_dim; -- 

CREATE TABLE calendar_dim
(
date_id serial  NOT NULL,
year        int NOT NULL,
quarter     int NOT NULL,
month       int NOT NULL,
week        int NOT NULL,
date        date NOT NULL,
week_day    varchar(20) NOT NULL,
leap  varchar(20) NOT NULL,
CONSTRAINT PK_calendar_dim PRIMARY KEY ( date_id )
);

insert into calendar_dim 
select 
to_char(date,'yyyymmdd')::int as date_id,  
       extract('year' from date)::int as year,
       extract('quarter' from date)::int as quarter,
       extract('month' from date)::int as month,
       extract('week' from date)::int as week,
       date::date,
       to_char(date, 'dy') as week_day,
       extract('day' from
               (date + interval '2 month - 1 day')
              ) = 29
       as leap
  from generate_series(date '2000-01-01',
                       date '2030-01-01',
                       interval '1 day')
       as t(date);
--checking
select * from calendar_dim; 


DROP TABLE IF EXISTS sales_fact; --

CREATE TABLE sales_fact
(
 sales_id        serial NOT NULL,
 order_id      varchar(50) NOT NULL,
 sales         numeric(9,4) NOT NULL,
 quantity      int NOT NULL,
 discount      numeric(8,2) NOT NULL,
 profit        numeric(22,16) NOT NULL,
 order_date_id int NOT NULL,
 ship_date_id  int NOT NULL,
 date_id       integer NOT NULL,
 ship_id       integer NOT NULL,
 product_id    integer NOT NULL,
 customer_id   integer NOT NULL,
 geo_id        integer NOT NULL,
 CONSTRAINT PK_sales_fact PRIMARY KEY ( sales_id ),
 CONSTRAINT FK_117 FOREIGN KEY ( date_id ) REFERENCES calendar_dim ( date_id ),
 CONSTRAINT FK_120 FOREIGN KEY ( ship_id ) REFERENCES ship_dim ( ship_id ),
 CONSTRAINT FK_123 FOREIGN KEY ( product_id ) REFERENCES product_dim ( product_id ),
 CONSTRAINT FK_126 FOREIGN KEY ( customer_id ) REFERENCES customer_dim ( customer_id ),
 CONSTRAINT FK_129 FOREIGN KEY ( geo_id ) REFERENCES geo_dim ( geo_id )
);

insert into sales_fact 
select 
		100+row_number() over() as sales_id
		,order_id
		,
		
