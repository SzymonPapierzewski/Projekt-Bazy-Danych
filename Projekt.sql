--------------------------------------------------------------------
---------------        TABLE           -----------------------------
--------------------------------------------------------------------

CREATE TABLE dostepne_produkty (
    hurtownia_id_hurtowni   VARCHAR2(20) NOT NULL,
    dostepna_ilosc          NUMBER(10) NOT NULL,
    produkt_id_produktu     NUMBER(4) NOT NULL
);

ALTER TABLE dostepne_produkty ADD CONSTRAINT dostepne_produkty_pk PRIMARY KEY ( hurtownia_id_hurtowni,produkt_id_produktu );

CREATE TABLE faktura (
    id_faktury              VARCHAR2(10) NOT NULL,
    klient_id_klienta       NUMBER(4) NOT NULL,
    hurtownia_id_hurtowni   VARCHAR2(20) NOT NULL,
    suma_do_zaplaty         NUMBER(20,2) NOT NULL,
	data_wystawienia        date NOT NULL
);

ALTER TABLE faktura ADD CONSTRAINT faktura_pk PRIMARY KEY ( id_faktury );

CREATE TABLE hurtownia (
    id_hurtowni   VARCHAR2(20) NOT NULL,
    adres         VARCHAR2(60) NOT NULL
);

ALTER TABLE hurtownia ADD CONSTRAINT hurtownia_pk PRIMARY KEY ( id_hurtowni );

CREATE TABLE klient (
    id_klienta                   NUMBER(4) NOT NULL,
    nazwisko                     VARCHAR2(30) NOT NULL,
    adres                        VARCHAR2(60) NOT NULL,
    wojewodztwo_id_wojewodztwa   NUMBER(2) NOT NULL
);

ALTER TABLE klient ADD CONSTRAINT klient_pk PRIMARY KEY ( id_klienta );

CREATE TABLE pozycja_faktury (
    faktura_id_faktury    VARCHAR2(10) NOT NULL,
    id_pozycji_faktury    NUMBER NOT NULL,
    cena_produktu         NUMBER(8,2) NOT NULL,
    ilosc_produktu        NUMBER NOT NULL,
    produkt_id_produktu   NUMBER(4) NOT NULL
);

ALTER TABLE pozycja_faktury ADD CONSTRAINT pozycja_faktury_pk PRIMARY KEY ( id_pozycji_faktury,faktura_id_faktury );

CREATE TABLE produkt (
    id_produktu     NUMBER(4) NOT NULL,
    nazwa_poduktu   VARCHAR2(60) NOT NULL,
    cena                    NUMBER(8,2) NOT NULL
);

ALTER TABLE produkt ADD CONSTRAINT produkt_pk PRIMARY KEY ( id_produktu );

CREATE TABLE wojewodztwo (
    id_wojewodztwa      NUMBER(2) NOT NULL,
    nazwa_wojewodztwa   VARCHAR2(25) NOT NULL
);

ALTER TABLE wojewodztwo ADD CONSTRAINT wojewodztwo_pk PRIMARY KEY ( id_wojewodztwa );

ALTER TABLE dostepne_produkty
    ADD CONSTRAINT dostepne_produkty_hurtownia_fk FOREIGN KEY ( hurtownia_id_hurtowni )
        REFERENCES hurtownia ( id_hurtowni );

ALTER TABLE dostepne_produkty
    ADD CONSTRAINT dostepne_produkty_produkt_fk FOREIGN KEY ( produkt_id_produktu )
        REFERENCES produkt ( id_produktu );

ALTER TABLE faktura
    ADD CONSTRAINT faktura_hurtownia_fk FOREIGN KEY ( hurtownia_id_hurtowni )
        REFERENCES hurtownia ( id_hurtowni );

ALTER TABLE faktura
    ADD CONSTRAINT faktura_klient_fk FOREIGN KEY ( klient_id_klienta )
        REFERENCES klient ( id_klienta );

ALTER TABLE klient
    ADD CONSTRAINT klient_wojewodztwo_fk FOREIGN KEY ( wojewodztwo_id_wojewodztwa )
        REFERENCES wojewodztwo ( id_wojewodztwa );

ALTER TABLE pozycja_faktury
    ADD CONSTRAINT pozycja_faktury_faktura_fk FOREIGN KEY ( faktura_id_faktury )
        REFERENCES faktura ( id_faktury );

ALTER TABLE pozycja_faktury
    ADD CONSTRAINT pozycja_faktury_produkt_fk FOREIGN KEY ( produkt_id_produktu )
        REFERENCES produkt ( id_produktu );




--------------------------------------------------------------------------------------
--                     SEKWENCJE                  ------------------------------------
--------------------------------------------------------------------------------------

create sequence seq_faktura_id;
create sequence seq_hurtownia_id;
create sequence seq_klient_id;



--------------------------------------------------------------------------------------
--                     PROCEDURY
--------------------------------------------------------------------------------------	

create or replace procedure proc_ulupelnij_losowo_dostene_produkty_w_hurtowni
(v_id_hurtowni Hurtownia.id_hurtowni%type) as
v_liczba_rodzajow_produktow numeric;
begin

select count(*) 
into v_liczba_rodzajow_produktow
from Produkt;

if v_liczba_rodzajow_produktow > 0 then
for iterator in 1..v_liczba_rodzajow_produktow loop
insert into Dostepne_Produkty values (v_id_hurtowni,dbms_random.value(1000,10000),iterator);
end loop;
end if;

end proc_ulupelnij_losowo_dostene_produkty_w_hurtowni;
/

create or replace procedure proc_uzupelnij_produkty_we_wszystkich_hurtowniach as
v_liczna_hurtowni numeric;
begin

select count(*)
into v_liczna_hurtowni
from Hurtownia;

for i in 1..v_liczna_hurtowni loop
PROC_ULUPELNIJ_LOSOWO_DOSTENE_PRODUKTY_W_HURTOWNI(i);
end loop;

end proc_uzupelnij_produkty_we_wszystkich_hurtowniach;
/

create or replace procedure pr_generuj_losowa_fakture 
as
v_ilosc_pozycji number;
v_id_klienta Klient.id_klienta%type;
v_id_hurtowni Hurtownia.id_hurtowni%type;
v_id_faktury Faktura.id_faktury%type;
v_cena_produktu Produkt.cena%type;
begin
v_id_klienta := fn_losuj_klienta();
v_id_hurtowni := fn_losuj_hurtownie();
v_id_faktury := seq_faktura_id.nextval;
insert into Faktura values(v_id_faktury,v_id_klienta,v_id_hurtowni,0.00,fn_losuj_date());


select count(*) into v_ilosc_pozycji from PRODUKT;
for i in 1..dbms_random.value(3,v_ilosc_pozycji) loop
    select cena into v_cena_produktu 
    from Produkt
    where id_produktu = i;
    insert into POZYCJA_FAKTURY values(v_id_faktury,i,v_cena_produktu,round(dbms_random.value(50,300)),i);
end loop;
end;
/


------------------------- FUNKCJE --------------------------------------

create or replace function fn_losuj_klienta
return Klient.id_klienta%type as
v_id_klienta Klient.id_klienta%type;
begin
SELECT id_klienta into v_id_klienta
FROM(
    SELECT id_klienta FROM KLIENT
    ORDER BY dbms_random.value 
    )
WHERE rownum = 1;
return v_id_klienta;
end;
/

create or replace function fn_losuj_hurtownie
return Hurtownia.id_hurtowni%type as
v_id_hurtowni Hurtownia.id_hurtowni%type;
begin
SELECT id_hurtowni into v_id_hurtowni
FROM(
    SELECT id_hurtowni FROM Hurtownia
    ORDER BY dbms_random.value 
    )
WHERE rownum = 1;
return v_id_hurtowni;
end fn_losuj_hurtownie;
/

create or replace function losuj_produkt
return Produkt.id_produktu%type as
v_id_produktu Produkt.id_produktu%type;
begin
SELECT id_produktu into v_id_produktu
FROM(
    SELECT id_produktu FROM Produkt
    ORDER BY dbms_random.value 
    )
WHERE rownum = 1;
return v_id_produktu;
end;
/


----------------------  triggery ----------------------------------
create or replace trigger tr_INS_Faktura
before insert on Faktura
for each row
begin
:new.suma_do_zaplaty := 0;
end;
/

create or replace trigger tr_INS_Pozycja_Faktury
before insert on Pozycja_Faktury
for each row
	declare v_cena_pozycji_faktury number(8,2);
begin
update Faktura
set suma_do_zaplaty = suma_do_zaplaty + :new.cena_produktu*:new.ilosc_produktu
where id_faktury = :new.faktura_id_faktury;
update Dostepne_produkty
set DOSTEPNA_ILOSC = dostepna_ilosc - :new.ilosc_produktu
where HURTOWNIA_ID_HURTOWNI = :new.faktura_id_faktury and PRODUKT_ID_PRODUKTU = :new.produkt_id_produktu;
end;
/

create or replace trigger tr_UPD_Pozycja_Faktury
before update on Pozycja_Faktury
for each row
begin
update Faktura
set suma_do_zaplaty = suma_do_zaplaty - (:old.cena_produktu*:old.ilosc_produktu) + (:new.cena_produktu*:new.ilosc_produktu)
where id_faktury = :old.Faktura_id_faktury;

update Dostepne_produkty
set DOSTEPNA_ILOSC = dostepna_ilosc + :old.ilosc_produktu - :new.ilosc_produktu
where HURTOWNIA_ID_HURTOWNI = :old.faktura_id_faktury and PRODUKT_ID_PRODUKTU = :old.produkt_id_produktu;
end;
/

create or replace trigger tr_DEL_Pozycja_Faktury
before delete on Pozycja_Faktury
for each row
begin
update Faktura
set suma_do_zaplaty = suma_do_zaplaty - (:old.cena_produktu*:old.ilosc_produktu)
where id_faktury = :old.Faktura_id_faktury;
update Dostepne_produkty
set DOSTEPNA_ILOSC = dostepna_ilosc + :old.ilosc_produktu
where HURTOWNIA_ID_HURTOWNI = :old.faktura_id_faktury and PRODUKT_ID_PRODUKTU = :old.produkt_id_produktu;
end;
/
--------------------------------------------------------------------------------------
--                     UZUPELNIJ DANE
--------------------------------------------------------------------------------------	
-------------------------- WOJEWODZTWO ----------------------------------	
insert into wojewodztwo values(02,'Dolnoslaskie'); 
insert into wojewodztwo values(04,'Kujawsko-Pomorskie'); 
insert into wojewodztwo values(06,'Lubelskie'); 
insert into wojewodztwo values(08,'Lubuskie'); 
insert into wojewodztwo values(10,'Lodzkie'); 
insert into wojewodztwo values(12,'Malopolskie'); 
insert into wojewodztwo values(14,'Mazowieckie'); 
insert into wojewodztwo values(16,'Opolskie'); 
insert into wojewodztwo values(18,'Podkarpackie'); 
insert into wojewodztwo values(20,'Podlaskie'); 
insert into wojewodztwo values(22,'Pomorskie'); 
insert into wojewodztwo values(24,'Slaskie'); 
insert into wojewodztwo values(26,'Swietokrzyskie'); 
insert into wojewodztwo values(28,'Warminsko-Mazurskie'); 
insert into wojewodztwo values(30,'Wielkopolskie'); 
insert into wojewodztwo values(32,'Zachodniopomorskie');

------------------------------- PRODUKT ----------------------------------

insert into Produkt values(1,'Zeszyt A4',round(dbms_random.value(1.00,10.00),2));
insert into Produkt values(2,'Zeszyt A5',round(dbms_random.value(1.00,10.00),2));
insert into Produkt values(3,'Kalendarz A5',round(dbms_random.value(5.00,20.00),2));
insert into Produkt values(4,'Kalendarz A6',round(dbms_random.value(5.00,20.00),2));
insert into Produkt values(5,'Ryza papieru A4',round(dbms_random.value(10.00,15.00),2));
insert into Produkt values(6,'Ryza papieru A3',round(dbms_random.value(15.00,20.00),2));
insert into Produkt values(7,'Karteczki samoprzylepne',round(dbms_random.value(1.00,5.00),2));
insert into Produkt values(8,'Kostki papierowe',round(dbms_random.value(7.00,20.00),2));
insert into Produkt values(9,'Rolki do faksu',round(dbms_random.value(20.00,50.00),2));
insert into Produkt values(10,'Rolki termiczne',round(dbms_random.value(50.00,100.00),2));
insert into Produkt values(11,'Papier kancelaryjny',round(dbms_random.value(15.00,30.00),2));
insert into Produkt values(12,'Papier komputerowy',round(dbms_random.value(10.00,15.00),2));
insert into Produkt values(13,'Papier ksero bialy',round(dbms_random.value(7.00,10.00),2));
insert into Produkt values(14,'Papier ksero kolorowy',round(dbms_random.value(10.00,13.00),2));
insert into Produkt values(15,'Papier do plotera',round(dbms_random.value(10.00,30.00),2));
insert into Produkt values(16,'Papier fotograficzny',round(dbms_random.value(80.00,100.00),2));
insert into Produkt values(17,'Papier samoprzylepny',round(dbms_random.value(10.00,14.00),2));
insert into Produkt values(18,'Papier satynowy',round(dbms_random.value(150.00,300.00),2));
insert into Produkt values(19,'Papier wizytowkowy',round(dbms_random.value(50.00,100.00),2));

-------------------- KLIENCI -------------------------

insert into Klient values(seq_klient_id.nextval,'Abacki','adres Abackiego',02);
insert into Klient values(seq_klient_id.nextval,'Abacki','adres Bbackiego',04);
insert into Klient values(seq_klient_id.nextval,'Babacki','adres Bbackiego',06);
insert into Klient values(seq_klient_id.nextval,'Cabacki','adres Bbackiego',08);
insert into Klient values(seq_klient_id.nextval,'Dabacki','adres Bbackiego',10);
insert into Klient values(seq_klient_id.nextval,'Ebacki','adres Bbackiego',12);
insert into Klient values(seq_klient_id.nextval,'Fabacki','adres Bbackiego',14);
insert into Klient values(seq_klient_id.nextval,'Gabacki','adres Bbackiego',16);
insert into Klient values(seq_klient_id.nextval,'Habacki','adres Bbackiego',18);
insert into Klient values(seq_klient_id.nextval,'Ibacki','adres Bbackiego',20);
insert into Klient values(seq_klient_id.nextval,'Jabacki','adres Bbackiego',22);
insert into Klient values(seq_klient_id.nextval,'Kabacki','adres Bbackiego',24);
insert into Klient values(seq_klient_id.nextval,'Labacki','adres Bbackiego',26);
insert into Klient values(seq_klient_id.nextval,'Mabacki','adres Bbackiego',28);
insert into Klient values(seq_klient_id.nextval,'Nabacki','adres Bbackiego',30);
insert into Klient values(seq_klient_id.nextval,'Obacki','adres Bbackiego',32);
insert into Klient values(seq_klient_id.nextval,'Pabacki','adres Bbackiego',02);
insert into Klient values(seq_klient_id.nextval,'Rabacki','adres Bbackiego',04);
insert into Klient values(seq_klient_id.nextval,'Sabacki','adres Bbackiego',06);
insert into Klient values(seq_klient_id.nextval,'Tabacki','adres Bbackiego',08);
insert into Klient values(seq_klient_id.nextval,'Ubacki','adres Bbackiego',10);
insert into Klient values(seq_klient_id.nextval,'Wabacki','adres Bbackiego',12);
insert into Klient values(seq_klient_id.nextval,'Zabacki','adres Bbackiego',14);

---------------- HURTOWNIE ---------------------------

insert into Hurtownia values (seq_hurtownia_id.nextval,'Warszawa ul. Polna 1');
insert into Hurtownia values (seq_hurtownia_id.nextval,'Lodz ul.Ogrodowa 6');
insert into Hurtownia values (seq_hurtownia_id.nextval,'Wroclaw ul. Papiernicza 12');
insert into Hurtownia values (seq_hurtownia_id.nextval,'Szczecin ul. Morska 14');
insert into Hurtownia values (seq_hurtownia_id.nextval,'Inowroclaw ul. Zamojska 10');
insert into Hurtownia values (seq_hurtownia_id.nextval,'Kutno ul. Kurkowa 30');
insert into Hurtownia values (seq_hurtownia_id.nextval,'Lublin ul. Krajowa 6');
insert into Hurtownia values (seq_hurtownia_id.nextval,'Rzeszow ul. Kaliska 28');

-------------- DOSTEPNE PRODUKTY ---------------------

begin
proc_uzupelnij_produkty_we_wszystkich_hurtowniach();
end;
/
---------------- FAKTURY -----------------------------

begin
for i in 1..20 loop
PR_GENERUJ_LOSOWA_FAKTURE();
end loop;
end;
/

------------------- WIDOWKI ----------------------------


  CREATE OR REPLACE FORCE EDITIONABLE VIEW "IBDC_17"."NAJMNIEJ_PRODUKTOW_W_HURTOWNIACH" ("ID Hurtowni", "ID Produktu", "Nazwa Produktu", "Dostepna Ilosc") AS 
  select dp.hurtownia_id_hurtowni as "ID Hurtowni", pr.id_produktu as "ID Produktu",pr.NAZWA_PODUKTU as "Nazwa Produktu",dp.DOSTEPNA_ILOSC as "Dostepna Ilosc"
from Dostepne_produkty dp inner join Produkt pr on dp.produkt_id_produktu = pr.id_produktu
order by dp.DOSTEPNA_ILOSC;


  CREATE OR REPLACE FORCE EDITIONABLE VIEW "IBDC_17"."ZAROBKI_W_POSZCZEGOLNYCH_WOJEWODZTWACH" ("Wojewodztwo", "Przychod z wojewodztwa") AS 
  select distinct Wojewodztwo.nazwa_wojewodztwa as "Wojewodztwo", sum(Faktura.suma_do_zaplaty) as "Przychod z wojewodztwa"
from Wojewodztwo ,Klient,Faktura
where Wojewodztwo.id_wojewodztwa = Klient.wojewodztwo_id_wojewodztwa and Klient.id_klienta = Faktura.klient_id_klienta
group by Wojewodztwo.nazwa_wojewodztwa
order by sum(Faktura.suma_do_zaplaty)desc;

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "IBDC_17"."ZESTAWIENIE_WYDATKOW_KLIENTOW" ("Nazwisko klienta", "Wydatki") AS 
  select distinct Klient.nazwisko as "Nazwisko klienta", sum(Faktura.suma_do_zaplaty) as "Wydatki"
from Klient, Faktura
where Klient.ID_KLIENTA = Faktura.klient_id_klienta
group by Klient.nazwisko
order by sum(Faktura.suma_do_zaplaty)desc;

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "IBDC_17"."ZESTAWIENIE_ZAROBKOW_HURTOWNI" ("Hurtownia", "Adres", "Zysk") AS 
  select Hurtownia.id_hurtowni as "Hurtownia",Hurtownia.adres as "Adres", sum(Faktura.suma_do_zaplaty) as "Zysk"
from Hurtownia ,Faktura 
where Hurtownia.id_hurtowni = Faktura.hurtownia_id_hurtowni
group by Hurtownia.id_hurtowni,Hurtownia.adres;




























