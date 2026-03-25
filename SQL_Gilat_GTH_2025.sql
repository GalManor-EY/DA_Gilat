-- create schema gilat_2025;
use gilat_2025;

DROP TABLE IF EXISTS GTH_Gilat_JE_2025;
create table GTH_Gilat_JE_2025(
Asiento_contable varchar(100),
Creado_por varchar(100),
Creado_por_name varchar(100),
Tipo_de_cambio varchar(100),
ID_de_empresa varchar(100),
ID_doc_original varchar(100),
Cuenta_de_mayor varchar(100),
Cuenta_de_mayor_name varchar(100),
Tipo_de_cuenta_de_mayor varchar(100),
Centro_de_coste varchar(100),
Centro_de_coste_name varchar(100),
Socio_comercial varchar(100),
Socio_comercial_name varchar(100),
Moneda_de_transaccion varchar(100),
Periodo_ano_contable varchar(100),
Tipo_de_asiento_contable varchar(100),
Texto_de_cabecera_de_asiento_contable varchar(100),
Tipo_de_documento_original varchar(100),
Fecha_de_contabilizacion varchar(100),
Referencia_externa_de_documento_original varchar(100),
Fecha_de_compensacion varchar(100),
Texto_de_posicion_de_asiento_contable varchar(100),
Sistema_contable varchar(100),
Cuenta_de_contrapartida_de_libro_mayor varchar(100),
Cuenta_de_contrapartida_de_libro_mayor_name varchar(100),
Asiento_contable_anulado varchar(100),
Indicador_de_asiento_contable_de_anulacion varchar(100),
Asiento_contable_de_anulacion varchar(100),
Indicador_de_asiento_contable_de_anulacion2 varchar(100),
Importe_en_moneda_de_empresa varchar(100),
Importe_en_moneda_de_empresa_currency varchar(100),
Importe_en_moneda_de_transaccion varchar(150),
Importe_en_moneda_de_transaccion_currency varchar(150)
);

LOAD DATA INFILE "F:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Gilat 2025/GTH Full YEAR 2025 - GTH.csv"
INTO TABLE GTH_Gilat_JE_2025
CHARACTER SET latin1
COLUMNS TERMINATED BY ','
ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

select *
from full_Gilat_JE_2025_v2
limit 100;

DROP TABLE IF EXISTS User_distribution;
create table User_distribution(

);

LOAD DATA INFILE "F:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Gilat 2025/User distribution 2025.csv"
INTO TABLE User_distribution
CHARACTER SET latin1
COLUMNS TERMINATED BY ','
ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;





select Cuenta_de_mayor, count(*)
from full_Gilat_JE_2025_v2
group by Cuenta_de_mayor;


-- ################ Reperformance of the lead procedures ################

select right(Fecha_de_contabilizacion,4), count(*)
from GTH_Gilat_JE_2025
group by right(Fecha_de_contabilizacion,4);
-- FY-2025: 100,287

-- Test 1: Journal entries recorded by a preparer who posted ten (10) or fewer journal entries during the period
-- Audit comment: 
-- EY IT comment: Done. Found 5 users

select Creado_por, Creado_por_name, count(*)
from GTH_Gilat_JE_2025
group by Creado_por, Creado_por_name
having count(*)<10;

-- Test 2: Journal entries (manual and/or automated) created and posted by management personnel, including senior management, IT personnel, or individuals who may have incentives to commit fraud
-- Audit comment: 
-- EY IT comment: Done. found 50 entries marked as prepared in the Full JE

select distinct Creado_por
from GTH_Gilat_JE_2025;

-- Test 3: Journal entries (manual and/or automated) containing specific keywords. In Spanish: CEO: Gerente General, Admin: Administrador, COO: Director de Operaciones
-- Audit comment: 
-- EY IT comment: No exception noted as well

select *
from GTH_Gilat_JE_2025
where Creado_por like "%Gerente General%" or Creado_por like "%Administrador%" or Creado_por like "%Director de Operaciones%" 
	or Creado_por_name like "%Gerente General%" or Creado_por_name like "%Administrador%" or Creado_por_name like "%Director de Operaciones%";
-- FY-25: 0 rows


-- Test 4: Journal entries (manual and/or automated) without an account description
-- Audit comment: 
-- EY IT comment: No exception noted as well

select *
from GTH_Gilat_JE_2025
where Cuenta_de_mayor_name = "" or Cuenta_de_mayor_name is null;


-- Test 5: Testing of transactions in sensitive accounts exceeding an amount of 203K. The materiality amount of 203K was determined in accordance with the materiality calculation prepared by DOF
-- Audit comment: We found 12 GL account with 657 transaction of more then 203K
-- EY IT comment: We found 12 GL account with 656 transaction of more then 203K

select count(*), sum(Importe_en_moneda_de_transaccion)
from GTH_Gilat_JE_2025
where
Cuenta_de_mayor in ( 2114200, 2116501, 73000180)
and abs(Importe_en_moneda_de_empresa)>203000;
-- FY-25: 32


select count(*), sum(Importe_en_moneda_de_empresa)
from GTH_Gilat_JE_2025
where
Cuenta_de_mayor in (65001600, 60001000,65001700, 65001500, 65001400,
75000000, 75000090, 75000130, 75000100, 75000031, 75000030, 75000350, 75000175, 75000006, 75000004, 75000080, 70010055, 75000410, 70010041, 75000210, 75000220, 73000000,
75000280, 75000380, 75000245, 70010042, 75000310, 70029300, 72000040, 70029100, 70029200, 70020031, 75000060, 73000180, 72010100, 72010200, 73000110, 76000106, 76000020, 76000040, 76000060, 74000000, 70000000, 75000999,
1133000, 1252550,
2114200, 2116110, 2116500, 2113200)
and abs(Importe_en_moneda_de_empresa)>203000;
-- full accounts list based on the excel



-- Test 6: Journal entries (manual and/or automated) with a significant gap (365 days) between the creation date and the posting date, which may indicate backdated entries
-- Audit comment: We found  314 transactions with exceptions
-- EY IT comment: We found  339 transactions with exceptions

with full_Gilat_JE as (
select *, 
DATE_FORMAT(STR_TO_DATE(Fecha_de_contabilizacion, '%d.%m.%Y'), '%Y-%m-%d') as posting_date,
DATE_FORMAT(STR_TO_DATE(Fecha_de_compensacion, '%d.%m.%Y'), '%Y-%m-%d') as Creation_date
from GTH_Gilat_JE_2025
)

select *, datediff(Creation_date, posting_date) as date_diff
from full_Gilat_JE
where datediff(Creation_date, posting_date)>370 and Creation_date <> "9999-12-31";
-- FY-25: 339

with full_Gilat_JE as (
select *, 
DATE_FORMAT(STR_TO_DATE(Fecha_de_contabilizacion, '%d.%m.%Y'), '%Y-%m-%d') as posting_date,
DATE_FORMAT(STR_TO_DATE(Creation_date, '%d/%m/%Y'), '%Y-%m-%d') as Creation_date_format
from full_Gilat_JE_2025_v2
)

select *, datediff(Creation_date_format, posting_date) as date_diff
from full_Gilat_JE
where datediff(Creation_date_format, posting_date)>=370 and Creation_date_format <> "9999-12-31";
-- FY-25: 313


-- Test 10: Journal entries (manual and/or automated) created or posted on Sundays
-- Audit comment: We found 668 transactions with exceptions
-- EY IT comment:

select *
from GTH_Gilat_JE_2025
where DAYOFWEEK(STR_TO_DATE(Fecha_de_contabilizacion, '%d.%m.%Y')) = 1 and
Creation_date <> "" and
 Creation_date <> "31/12/9999" and
Texto_de_posicion_de_asiento_contable not in ("CAMBIO", "BANK") and
Account_Description2 not in ("DIFERENCIA DE CAMBIO", "DIFERENCIA EN CAMBIO");
-- FY-25: 1470


select *
from GTH_Gilat_JE_2025
limit 10;

