--use [Evolve]

declare	@start  date = '01-November-2025';  -- a day after the month-end of interest.

declare	@ProjectionEndMonth  date = '01-Dec-2039';  

declare @CancellationRate float= 0.03; 

declare @K float= Power(1.190294732374546*1.000000,(1*1.000000/12)); 






drop table if exists #claims;
drop table if exists #claims2;
drop table if exists #claims3;
drop table if exists #claims4;
drop table if exists #Pol;
drop table if exists #res;
drop table if exists #res2;
drop table if exists #res3;
drop table if exists #res4;
drop table if exists #res5;
drop table if exists #res6;
drop table if exists #res7;
drop table if exists #res8;
drop table if exists #res9;
drop table if exists #res10;
drop table if exists #res11;
drop table if exists #CriteriaTab;
drop table if exists #Toyota;
drop table if exists #Toyota2;
drop table if exists #OtherCars;
drop table if exists #MTH;
drop table if exists #Base;

--drop table if exists #ms_santam_rating;

--Assumptions

Declare @RatingDate date = Getdate();
Declare @AssumedMonthlyKMs int = 2000;
Declare @vat float = 0.15
Declare @PerIncChange float = 1.2
Declare @PerDecChange float = 0.8
Declare @InflationInc float = 1.06
Declare @MaxIncrease float = 1.2

Declare @avgHiluxPrice float= (select avg(cast(price as float)) 
                               from [MSureEvolve].[dbo].[ViewVehicleModels] 
							   where brand like 'TOYOTA' and range like '%HILUX%' and doors = 4)

--select @avgHiluxPrice
--Create tables
CREATE TABLE #CriteriaTab (
    C_Criteria int,
    C_AgeFrom int,
    C_AgeTo int,
	C_OdometerLimit int
);

--Insert into tables

insert into #CriteriaTab Values	(1,0,5,100000);	
insert into #CriteriaTab Values	(2,5,8,160000);	
insert into #CriteriaTab Values	(3,8,10,200000);	
insert into #CriteriaTab Values	(4,10,12,250000);	
insert into #CriteriaTab Values	(5,12,15,300000);	



-- Save the base policy numbers
Create table					#Base (POL_PolicyNumber nvarchar(50));


Insert into #Base (POL_PolicyNumber) values 	('SWTY000001POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000003POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000005POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000008POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000008POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000019POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000021POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000022POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000023POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000028POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000030POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000030POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000034POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000034POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000041POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000045POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000050POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000053POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000063POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000064POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000065POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000076POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000077POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000079POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000080POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000093POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000099POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000102POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000103POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000105POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000115POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000116POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000120POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000125POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000133POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000136POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000137POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000158POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000161POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000172POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000179POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000181POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000182POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000183POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000197POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000199POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000200POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000204POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000205POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000207POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000216POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000218POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000231POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000234POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000236POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000237POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000241POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000246POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000261POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000268POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000273POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000276POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000277POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000278POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000289POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000291POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000294POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000296POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000298POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000300POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000306POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000316POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000318POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000321POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000324POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000325POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000328POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000329POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000333POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000336POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000339POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000340POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000351POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000353POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000354POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000358POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000362POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000364POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000379POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000380POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000381POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000387POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000394POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000395POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000396POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000398POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000401POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000406POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000410POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000415POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000416POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000423POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000429POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000433POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000435POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000444POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000446POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000448POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000449POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000454POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000458POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000463POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000465POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000473POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000479POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000480POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000481POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000489POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000493POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000494POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000500POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000501POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000507POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000514POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000518POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000519POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000528POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000534POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000537POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000540POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000542POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000545POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000549POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000550POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000551POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000561POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000563POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000566POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000567POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000578POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000579POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000591POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000594POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000597POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000599POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000606POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000612POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000614POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000616POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000625POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000626POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000626POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000632POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000638POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000639POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000659POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000666POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000668POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000671POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000673POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000674POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000678POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000683POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000684POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000686POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000688POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000690POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000691POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000695POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000696POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000699POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000700POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000710POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000712POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000718POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000726POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000727POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000734POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000735POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000738POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000740POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000740POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000741POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000758POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000797POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000798POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000801POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000803POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000809POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000818POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000821POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000832POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000834POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000835POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000843POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000845POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000857POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000867POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000868POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000889POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000890POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000895POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000896POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000897POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000900POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000903POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000914POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000921POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000923POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000936POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000944POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000944POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000947POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000948POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000951POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000952POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000955POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000961POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000973POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000974POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000987POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000988POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000989POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000992POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000993POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY000995POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001003POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001012POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001018POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001026POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001029POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001037POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001039POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001042POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001047POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001049POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001051POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001055POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001057POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001062POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001065POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001068POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001069POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001071POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001073POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001077POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001084POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001085POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001094POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001099POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001109POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001114POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001141POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001142POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001154POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001156POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001162POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001163POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001172POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001181POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001196POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001201POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001225POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001241POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001242POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001249POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001254POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001256POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001261POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001263POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001265POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001267POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001280POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001285POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001333POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001351POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001364POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001367POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001375POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001382POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001391POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001395POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001397POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001405POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001406POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001427POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001439POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001442POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001447POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001450POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001454POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001455POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001466POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001466POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001470POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001475POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001484POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001485POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001487POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001504POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001505POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001512POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001526POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001545POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001551POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001554POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001565POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001576POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001611POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001619POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001621POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001637POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001640POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001641POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001648POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001663POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001677POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001679POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001687POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001688POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001689POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001694POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001695POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001748POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001778POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001780POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001835POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001838POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001840POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001855POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001864POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001865POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001875POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001885POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001898POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001901POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001919POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001935POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001942POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001957POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001968POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001969POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001973POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY001975POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002016POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002029POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002059POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002060POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002060POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002079POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002100POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002105POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002106POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002107POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002118POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002130POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002143POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002166POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002177POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002185POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002187POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002195POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002218POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002251POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002277POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002307POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002374POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002377POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002385POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002387POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002429POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002441POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002445POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002449POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002460POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002476POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002501POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002502POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002517POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002518POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002536POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002545POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002547POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002557POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002566POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002620POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002622POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002663POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002716POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002719POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002766POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002773POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002820POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002824POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002866POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002898POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002926POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY002961POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003004POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003021POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003037POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003038POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003041POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003051POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003076POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003077POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003123POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003125POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003127POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003153POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003157POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003188POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003194POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003296POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003317POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003318POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003342POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003351POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003364POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003416POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003417POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003428POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003434POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003454POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003470POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003497POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003522POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003554POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003577POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003585POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003597POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003608POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003667POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003717POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003737POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003746POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003761POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003817POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003828POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003847POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003851POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003864POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003896POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003908POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003943POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY003973POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY004006POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY004009POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY004025POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY004058POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY004108POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY004133POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY004194POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY004213POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY004214POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY004224POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY004247POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY004248POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY004249POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY004283POL')
Insert into #Base (POL_PolicyNumber) values 	('SWTY004285POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004286POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004300POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004308POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004336POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004341POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004390POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004393POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004395POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004413POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004415POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004417POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004420POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004430POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004430POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004430POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004461POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004468POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004476POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004507POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004519POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004526POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004545POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004553POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004563POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004585POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004598POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004600POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004601POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004666POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004696POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004702POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004760POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004763POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004900POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004954POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004961POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004973POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004982POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY004991POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY005210POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY005244POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY005273POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY005284POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY005304POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY005325POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY005329POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY005337POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY005412POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY005419POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY005938POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY006542POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY006554POL');
Insert into #Base (POL_PolicyNumber) values 	('SWTY008101POL');









--SELECT *  INTO 
--#ms_santam_rating 
--FROM  [MSureEvolve].[dbo].[ms_santam_rating] 

--select * from #CriteriaTab 

--Policy Info

SELECT [POL_PolicyNumber]
      ,Policy_ID
	  ,ITS_Item_ID
	  ,[PMI_VehicleCode]
	  ,[PMI_Make] [PMI_MakeOriginal]
      ,isnull((select distinct Brand from [MSureEvolve].[dbo].[ViewVehicleModels]  
	              where ADG_CODE = [PMI_VehicleCode]),[PMI_Make]) [PMI_Make]
      ,[PMI_Model]
	  ,[PRP_PlanName]
	  ,[PDS_SectionGrouping]
      ,[ITS_SumInsured]
      ,[ITS_Premium]
	  ,[PMI_PresentKM]
      ,[ITS_Status]
	  ,[RTF_Description]
	  ,[PMI_RegistrationDate]
	  ,[PMI_PurchaseDate]
	  ,case when POL_SoldDate>='2024-01-01' and POL_SoldDate <'2024-01-23' then '2023-12-31' else POL_SoldDate end POL_SoldDate
	  ,POL_ReceivedDate
	  ,[PMI_MileageDate]
      ,[ITS_StartDate]
      ,[ITS_EndDate]
	  ,[POL_RenewalDate]

  into #Pol

  FROM [Evolve].[dbo].[ItemSummary]

  left join [Evolve].[dbo].Policy p on [ITS_Policy_ID] = Policy_ID
  left join [Evolve].[dbo].[PolicyMechanicalBreakdownItem] on [PolicyMechanicalBreakdownItem_ID] = ITS_Item_ID
  left join [Evolve].[dbo].[ReferenceTermFrequency] on [POL_ProductTerm_ID] = [TermFrequency_Id]
  left join [Evolve].[dbo].[ProductPlans] on [ProductPlans_Id] = [PMI_Plan_ID]
  left join [Evolve].[dbo].[ProductSection] on [ProductSection_Id] = [PMI_Section_ID]
  where 1=1
  --      and [POL_PolicyNumber] --like 'S%'
		
		--in

		--(
		

		--)


		    and POL_GeneratedPolicyNumber in (Select * from  #base) --like 'SW%'

	 -- and POL_PolicyNumber like 'SW%Pol'

    and POL_Status in (1)

	--and ITS_Status = 1

  --  and PMI_Make = 'Ford'

	--and POL_StartDate = POL_EndDate


	--	and [POL_Status]=1

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Claims info

SELECT [ClaimItemSummary_ID]
      ,[CWI_PolicyWarrantyItem_ID]
      ,[CIS_CreateUser_ID]
      ,[CIS_CreateDate]
      ,[CIS_UpdateUser_ID]
      ,[CIS_UpdateDate]
     -- ,[CIS_Deleted]
      ,[CIS_AssignedUser_ID]
      ,[CIS_Section_ID]
      ,[CIS_Claim_ID]
      ,[CIS_ClaimItem_ID]
      ,[CIS_SectionLossType_ID]
      ,[CIS_Plan_ID]
  --   ,[CIS_Description]
      ,[CIS_ClaimDescription]
      ,[CIS_LossTypeDescription]
      ,[CIS_ClaimItemDescription]
      ,[CIS_PlanName]
      ,[CIS_Status]
	  ,[CWI_OdoMeterReading]
	  ,[CWI_FailureDate]
      ,[CIS_SumInsured]
      ,[CIS_Estimate] CIS_AuthAmount
      ,[CIS_Paid]
      ,[CIS_OutstandingEstimate]
      ,[CIS_ThirdPartyAmount]
      ,[CIS_OwnDamageAmount]
      ,[CIS_Policy_ID]
      ,[CIS_PolicyNumber]
      ,[CIS_ClaimNumber]
      ,[CIS_LossDate]
      ,[CIS_SectionName]
      ,[CIS_AuthorizationNumber]
      ,[CIS_AuthBy]
      ,[CIS_AuthDate]
     -- ,[CIS_AuthAmount]
      ,[CIS_MaxLiability]
      ,[CIS_ClaimType_ID]
      ,[CIS_SubAuthAmount]
      ,[CIS_PendingReasons]
      ,[CIS_AbandonedReason]
	  ,[CLS_Description]
	  ,d.[CIS_Description]

	  into #claims

  FROM [Evolve].[dbo].[ClaimItemSummary] a

  left join [Evolve].[dbo].[Claim] on [CLM_ClaimNumber] = [CIS_ClaimNumber]
  left join [Evolve].[dbo].[ReferenceClaimstatus] on [ClaimStatus_ID] = [CLM_Status]
  left join [Evolve].[dbo].[ReferenceClaimitemstatus] d on [ClaimItemStatus_ID] = [CIS_Status]
  left join [Evolve].[dbo].[ClaimWarrantyItem] on [CIS_ClaimItem_ID] = [ClaimWarrantyItem_ID] 
  where 1=1
       -- and [CIS_Policy_ID] = 'DFC34627-44B8-4078-B1C6-28EC16C8B049'
	    --and [CLS_Description] <>'Rejected'
		--and CIS_PolicyNumber = 'SWTY000043POL'

		--and d.[CIS_Description] <>'Rejected'
		and a.[CIS_Deleted] = 0
		and [CIS_CreateDate]>= DATEADD(day,-365,@RatingDate)
		and CIS_PolicyNumber in (select [POL_PolicyNumber] from #pol)

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
select [CWI_PolicyWarrantyItem_ID] ,count(distinct CIS_ClaimNumber) ClaimsCount
 
 into #claims2

 from #Claims

  where 1=1
  
  and CIS_AuthAmount>0
  --and CWI_PolicyWarrantyItem_ID = '103E270B-83A3-4241-B7E3-EB64F063DD33'

 
 group by [CWI_PolicyWarrantyItem_ID]


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


 select o.[CWI_PolicyWarrantyItem_ID] ,ClaimsCount,sum(CIS_AuthAmount) CIS_AuthAmount, [CWI_OdoMeterReading],[CWI_FailureDate]

 into #claims3 

 from  #claims2 c 

 left join #Claims o on o.[CWI_PolicyWarrantyItem_ID] = c.[CWI_PolicyWarrantyItem_ID]




 group by o.[CWI_PolicyWarrantyItem_ID] ,[CWI_OdoMeterReading],[CWI_FailureDate],ClaimsCount

 ----------------------------------------------------------------------------------------------------------------


 select [CWI_PolicyWarrantyItem_ID],ClaimsCount,sum(CIS_AuthAmount) CIS_AuthAmount, max([CWI_OdoMeterReading]) [CWI_OdoMeterReading]
        ,max([CWI_FailureDate]) [CWI_FailureDate]

 into #claims4

 from #Claims3



 group by [CWI_PolicyWarrantyItem_ID],ClaimsCount


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 select p.*,c.*
 
 into #res 

 from #pol p
 left join #claims4 c on  ITS_Item_ID  = [CWI_PolicyWarrantyItem_ID]
-- left join [MSureEvolve].[dbo].[ViewVehicleModels] on [ADG_CODE] = PMI_VehicleCode

 order by POL_PolicyNumber
------------------------------------------------------------------------------------------------------------------------------------------
Select ADG_CODE, AVG(cast(Price as float)) AvePrice 

into #OtherCars

from [MSureEvolve].[dbo].[ViewVehicleModels] group by ADG_CODE
---------------------------------------------------------------------------------------------------------------------------------------------------------
select distinct ADG_CODE,[Desc],
cast(price as float) Price
into #toyota
from [MSureEvolve].[dbo].[ViewVehicleModels]
where brand like 'TOYOTA'
---------------------------------------------------------------------------------------------------------------------------------
select ADG_CODE ,avg(Price) ToyotaPrice
into #toyota2
from #toyota
group by ADG_CODE


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
select *,case when PMI_Make ='Volkswagen' and PMI_Model like '%polo%' then 'VOLKSWAGEN Polo'
         when PMI_Make ='Volkswagen' and PMI_Model not like '%polo%' then 'VOLKSWAGEN Other'
         when PMI_Make ='Ford' and PMI_Model like '%ranger%'  then 'FORD Ranger and Everest'
		 when PMI_Make ='Ford' and PMI_Model like '%everest%'  then 'FORD Ranger and Everest'
		 when PMI_Make ='Ford'  then 'FORD Other'
		 when PMI_Make ='Toyota' and (select ToyotaPrice from #toyota2 where PMI_VehicleCode = ADG_CODE ) >= @avgHiluxPrice 
		 then 'TOYOTA High' 
		 when PMI_Make ='Toyota' and (select ToyotaPrice from #toyota2 where PMI_VehicleCode = ADG_CODE ) < @avgHiluxPrice  
		 then 'TOYOTA Other' 
		 when PMI_Make COLLATE DATABASE_DEFAULT in (select distinct make from [MSureEvolve].[dbo].[ms_santam_rating] ) then PMI_Make
         when  (select avePrice from #OtherCars where ADG_CODE = PMI_VehicleCode ) <= 200000 then 'OTHER Low' 
		 when  (select avePrice from #OtherCars where ADG_CODE = PMI_VehicleCode ) <= 300000 then 'OTHER Standard' 
		 else 'OTHER High'

		--else PMI_Make 
		end Make

		
		


	--	select * from #OtherCars

        ,'Standard' RatingG , 'Warranty' Sect_ion--, case when 

        ,((DATEDIFF(day,PMI_RegistrationDate,case when POL_PolicyNumber like '%-%' then ITS_StartDate 
		 else POL_SoldDate end )*1.000000-
		      (case when DATEDIFF(day,POL_ReceivedDate,POL_SoldDate) <35 and POL_ReceivedDate < POL_SoldDate  then DATEDIFF(day,POL_ReceivedDate,POL_SoldDate) else 35 end)  )/365) VehicleAgeAtStart

		         ,(DATEDIFF(day,PMI_RegistrationDate,case when POL_PolicyNumber like '%-%' then ITS_StartDate
				 
		 else POL_ReceivedDate end )*1.000000/365) VehicleAgeAtReceivedDate

        ,(DATEDIFF(day,PMI_RegistrationDate,POL_RenewalDate)*1.000000/365) VehicleAgeAtRenewal
		,ISNULL(CWI_OdoMeterReading,PMI_PresentKM) latestOdoMeterReading
		,ISNULL(CWI_FailureDate,case when PMI_MileageDate=0 then (case when POL_PolicyNumber like '%-%' then ITS_StartDate 
		 else POL_SoldDate end) else PMI_MileageDate end ) latestMileageDate

into #res2 
from #res 

-------------------------------------------------------------------------------------------------------------------------------------------------
select *,case when VehicleAgeAtStart * 1.0000  <= 5 and PMI_PresentKM < 100000 then 1
              when VehicleAgeAtStart * 1.0000  <= 8 and PMI_PresentKM < 160000 then 2
              when VehicleAgeAtStart * 1.0000  <= 10 and PMI_PresentKM < 200000 then 3
              when VehicleAgeAtStart * 1.0000  <= 12 and PMI_PresentKM < 250000 then 4
              when VehicleAgeAtStart * 1.0000  <= 15 and PMI_PresentKM < 300000 then 5
              else 999 end CriteriaStart

      ,case when VehicleAgeAtStart * 1.0000  <= 5 and PMI_PresentKM < 100000 then 1
              when VehicleAgeAtStart * 1.0000  <= 8 and PMI_PresentKM < 160000 then 2
              when VehicleAgeAtStart * 1.0000  <= 10 and PMI_PresentKM < 200000 then 3
              when VehicleAgeAtStart * 1.0000  <= 12 and PMI_PresentKM < 250000 then 4
              when VehicleAgeAtStart * 1.0000  <= 15 and PMI_PresentKM < 300000 then 5
              else 999 end OriPlanCriteriaStart

        ,case when VehicleAgeAtStart * 1.0000  <= 5  then 1
              when VehicleAgeAtStart * 1.0000  <= 8  then 2
              when VehicleAgeAtStart * 1.0000  <= 10  then 3
              when VehicleAgeAtStart * 1.0000  <= 12  then 4
              when VehicleAgeAtStart * 1.0000  <= 15 and PMI_PresentKM < 300000 then 5
              else 999 end OriCriteriaStart




        ,Cast( latestOdoMeterReading + 
		@AssumedMonthlyKMs * (DATEDIFF(day,latestMileageDate,POL_RenewalDate)*1.0/365*12) as int) RenewalAssumedOdoMeterReading
	
into #res3
	
from #res2
--select * from #CriteriaTab
------------------------------------------------------------------------------------------------------------------------------------------------
select r.*, o.C_AgeFrom StartAgeFrom,o.C_AgeTo StartAgeTo,o.C_OdometerLimit StartOdometerLimit
          , Ori.C_AgeFrom OriStartAgeFrom,Ori.C_AgeTo OriStartAgeTo,Ori.C_OdometerLimit OriStartOdometerLimit

		   ,case when PRP_PlanName='Chrome' then PRP_PlanName

		when PRP_PlanName='Bronze' then PRP_PlanName
								  
		when PRP_PlanName='Silver' and OriPlanCriteriaStart = 5 then 'Bronze'
		when PRP_PlanName='Silver' and OriPlanCriteriaStart in (1,2,3,4) then PRP_PlanName

		when PRP_PlanName='Gold' and OriPlanCriteriaStart = 5 then 'Bronze'
		when PRP_PlanName='Gold' and OriPlanCriteriaStart = 4 then 'Silver'
		when PRP_PlanName='Gold' and OriPlanCriteriaStart in (1,2,3) then PRP_PlanName

		when PRP_PlanName='Platinum' and OriPlanCriteriaStart = 5 then 'Bronze'
		when PRP_PlanName='Platinum' and OriPlanCriteriaStart = 4 then 'Silver'
		when PRP_PlanName='Platinum' and OriPlanCriteriaStart = 3 then 'Gold'
		when PRP_PlanName='Platinum' and OriPlanCriteriaStart in (1,2) then PRP_PlanName

		when PRP_PlanName='Titanium' and OriPlanCriteriaStart = 5 then 'Bronze'
		when PRP_PlanName='Titanium' and OriPlanCriteriaStart = 4 then 'Silver'
		when PRP_PlanName='Titanium' and OriPlanCriteriaStart = 3 then 'Gold'
		when PRP_PlanName='Titanium' and OriPlanCriteriaStart = 2 then 'Platinum'
		when PRP_PlanName='Titanium' and OriPlanCriteriaStart = 1 then PRP_PlanName

		end OriPlanOption 



       , case when RenewalAssumedOdoMeterReading >= 300000 then 999
	          when VehicleAgeAtRenewal * 1.0000  <= 5 and RenewalAssumedOdoMeterReading < 100000 then 1
              when VehicleAgeAtRenewal * 1.0000  <= 8 and RenewalAssumedOdoMeterReading < 160000 then 2
              when VehicleAgeAtRenewal * 1.0000  <= 10 and RenewalAssumedOdoMeterReading < 200000 then 3
              when VehicleAgeAtRenewal * 1.0000  <= 12 and RenewalAssumedOdoMeterReading < 250000 then 4
              when VehicleAgeAtRenewal * 1.0000  <= 15 and RenewalAssumedOdoMeterReading < 300000 then 5
              else 999 end CriteriaRenewal

              , case when RenewalAssumedOdoMeterReading >= 300000 then 999
			  when VehicleAgeAtRenewal * 1.0000  <= 5 and RenewalAssumedOdoMeterReading < 100000 then 1
              when VehicleAgeAtRenewal * 1.0000  <= 8 and RenewalAssumedOdoMeterReading < 160000 then 2
              when VehicleAgeAtRenewal * 1.0000  <= 10 and RenewalAssumedOdoMeterReading < 200000 then 3
              when VehicleAgeAtRenewal * 1.0000  <= 12 and RenewalAssumedOdoMeterReading < 250000 then 4
              when VehicleAgeAtRenewal * 1.0000  <= 15 and RenewalAssumedOdoMeterReading < 300000 then 5
              else 999 end OriPlanCriteriaRenewal

       , case when RenewalAssumedOdoMeterReading >= 300000 then 999
	          when VehicleAgeAtRenewal * 1.0000  <= 5  then 1
              when VehicleAgeAtRenewal * 1.0000  <= 8  then 2
              when VehicleAgeAtRenewal * 1.0000  <= 10  then 3
              when VehicleAgeAtRenewal * 1.0000  <= 12  then 4
              when VehicleAgeAtRenewal * 1.0000  <= 15 and RenewalAssumedOdoMeterReading < 300000 then 5
              else 999 end OriCriteriaRenewal
       
into #res4

from #res3 r
left join #CriteriaTab o on C_Criteria = CriteriaStart
left join #CriteriaTab Ori on Ori.C_Criteria = OriCriteriaStart

--select * from #res5
-----------------------------------------------------------------------------------------------------------------------------------------------------------

--Declare @vat float = 0.15;

select r.*
,c.C_AgeFrom ReAgeFrom,
c.C_AgeTo ReAgeTo,c.C_OdometerLimit ReOdometerLimit 

          ,Ori.C_AgeFrom OriReAgeFrom,Ori.C_AgeTo OriReAgeTo,Ori.C_OdometerLimit OriReOdometerLimit



 ,case when PRP_PlanName='Chrome' then PRP_PlanName

		when PRP_PlanName='Bronze' then PRP_PlanName
								  
		when PRP_PlanName='Silver' and CriteriaRenewal = 5 then 'Bronze'
		when PRP_PlanName='Silver' and CriteriaRenewal in (1,2,3,4) then PRP_PlanName

		when PRP_PlanName='Gold' and CriteriaRenewal = 5 then 'Bronze'
		when PRP_PlanName='Gold' and CriteriaRenewal = 4 then 'Silver'
		when PRP_PlanName='Gold' and CriteriaRenewal in (1,2,3) then PRP_PlanName

		when PRP_PlanName='Platinum' and CriteriaRenewal = 5 then 'Bronze'
		when PRP_PlanName='Platinum' and CriteriaRenewal = 4 then 'Silver'
		when PRP_PlanName='Platinum' and CriteriaRenewal = 3 then 'Gold'
		when PRP_PlanName='Platinum' and CriteriaRenewal in (1,2) then PRP_PlanName

		when PRP_PlanName='Titanium' and CriteriaRenewal = 5 then 'Bronze'
		when PRP_PlanName='Titanium' and CriteriaRenewal = 4 then 'Silver'
		when PRP_PlanName='Titanium' and CriteriaRenewal = 3 then 'Gold'
		when PRP_PlanName='Titanium' and CriteriaRenewal = 2 then 'Platinum'
		when PRP_PlanName='Titanium' and CriteriaRenewal = 1 then PRP_PlanName

		end RenewalPlanOption 

 ,case when PRP_PlanName='Chrome' then PRP_PlanName

		when PRP_PlanName='Bronze' then PRP_PlanName
								  
		when PRP_PlanName='Silver' and OriPlanCriteriaRenewal = 5 then 'Bronze'
		when PRP_PlanName='Silver' and OriPlanCriteriaRenewal in (1,2,3,4) then PRP_PlanName

		when PRP_PlanName='Gold' and OriPlanCriteriaRenewal = 5 then 'Bronze'
		when PRP_PlanName='Gold' and OriPlanCriteriaRenewal = 4 then 'Silver'
		when PRP_PlanName='Gold' and OriPlanCriteriaRenewal in (1,2,3) then PRP_PlanName

		when PRP_PlanName='Platinum' and OriPlanCriteriaRenewal = 5 then 'Bronze'
		when PRP_PlanName='Platinum' and OriPlanCriteriaRenewal = 4 then 'Silver'
		when PRP_PlanName='Platinum' and OriPlanCriteriaRenewal = 3 then 'Gold'
		when PRP_PlanName='Platinum' and OriPlanCriteriaRenewal in (1,2) then PRP_PlanName

		when PRP_PlanName='Titanium' and OriPlanCriteriaRenewal = 5 then 'Bronze'
		when PRP_PlanName='Titanium' and OriPlanCriteriaRenewal = 4 then 'Silver'
		when PRP_PlanName='Titanium' and OriPlanCriteriaRenewal = 3 then 'Gold'
		when PRP_PlanName='Titanium' and OriPlanCriteriaRenewal = 2 then 'Platinum'
		when PRP_PlanName='Titanium' and OriPlanCriteriaRenewal = 1 then PRP_PlanName

		end OriRenewalPlanOption 



       ,round(s.[Premium_exclVAT] * (1+@vat)* (case when [RTF_Description] = 'Annual' then 11 else 1 end),2) E_StartPremium
	   ,round(O.[Premium_exclVAT] * (1+@vat)* (case when [RTF_Description] = 'Annual' then 11 else 1 end),2) OriE_StartPremium
	   , ITS_Premium PremiumAtInception 

		  into #res5

from #res4 r
left join #CriteriaTab c on C_Criteria = CriteriaRenewal
left join [MSureEvolve].[dbo].[ms_santam_rating] s on s.[make] = r.Make COLLATE DATABASE_DEFAULT


													  and [section] = [Sect_ion] COLLATE DATABASE_DEFAULT
													  and s.[make] = r.Make COLLATE DATABASE_DEFAULT
													  and [AgeFrom] = StartAgeFrom --COLLATE DATABASE_DEFAULT
													  and [AgeTo] = StartAgeTo --COLLATE DATABASE_DEFAULT
													  and [OdometerLimit] = StartOdometerLimit --COLLATE DATABASE_DEFAULT
													  and [PlanOption] = [PRP_PlanName] COLLATE DATABASE_DEFAULT
													  and [PremiumFrequency] = 'Monthly'--[RTF_Description] COLLATE DATABASE_DEFAULT
													  and [Effectivedate] = (select max([Effectivedate]) from [MSureEvolve].[dbo].[ms_santam_rating] where POL_SoldDate>=[Effectivedate])


left join #CriteriaTab Ori on Ori.C_Criteria = OriCriteriaRenewal
left join [MSureEvolve].[dbo].[ms_santam_rating] O on O.[make] = r.Make COLLATE DATABASE_DEFAULT


													  and o.[section] = [Sect_ion] COLLATE DATABASE_DEFAULT
													  and o.[make] = r.Make COLLATE DATABASE_DEFAULT
													  and o.[AgeFrom] = OriStartAgeFrom --COLLATE DATABASE_DEFAULT
													  and o.[AgeTo] = OriStartAgeTo --COLLATE DATABASE_DEFAULT
													  and o.[OdometerLimit] = OriStartOdometerLimit --COLLATE DATABASE_DEFAULT
													  and o.[PlanOption] = [PRP_PlanName] COLLATE DATABASE_DEFAULT
													  and o.[PremiumFrequency] = 'Monthly'--[RTF_Description] COLLATE DATABASE_DEFAULT
													  and o.[Effectivedate] = (select max([Effectivedate]) from [MSureEvolve].[dbo].[ms_santam_rating] where POL_SoldDate>=[Effectivedate])



													 
--where POL_PolicyNumber like 'SWTY001465POL%'

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
select r.*,round(s.[Premium_exclVAT] * (1+@vat) * (case when [RTF_Description] = 'Annual' then 11 else 1 end)  ,2) E_NewPremiumRew 
          ,round(o.[Premium_exclVAT] * (1+@vat) * (case when [RTF_Description] = 'Annual' then 11 else 1 end)  ,2) OriE_NewPremiumRew 

into #res6 

from #res5 r
left join [MSureEvolve].[dbo].[ms_santam_rating] s on s.[make] = r.Make COLLATE DATABASE_DEFAULT


													  and [section] = [Sect_ion] COLLATE DATABASE_DEFAULT
													  and s.[make] = r.Make COLLATE DATABASE_DEFAULT
													  and [AgeFrom] = ReAgeFrom --COLLATE DATABASE_DEFAULT
													  and [AgeTo] = ReAgeTo --COLLATE DATABASE_DEFAULT
													  and [OdometerLimit] = ReOdometerLimit --COLLATE DATABASE_DEFAULT
													  and [PlanOption] = RenewalPlanOption COLLATE DATABASE_DEFAULT
													  and [PremiumFrequency] = 'Monthly'--[RTF_Description] COLLATE DATABASE_DEFAULT
													  and [Effectivedate] = (select max([Effectivedate]) from [MSureEvolve].[dbo].[ms_santam_rating] where POL_SoldDate>=[Effectivedate])

left join [MSureEvolve].[dbo].[ms_santam_rating] o on o.[make] = r.Make COLLATE DATABASE_DEFAULT


													  and o.[section] = [Sect_ion] COLLATE DATABASE_DEFAULT
													  and o.[make] = r.Make COLLATE DATABASE_DEFAULT
													  and o.[AgeFrom] = OriReAgeFrom --COLLATE DATABASE_DEFAULT
													  and o.[AgeTo] = OriReAgeTo --COLLATE DATABASE_DEFAULT
													  and o.[OdometerLimit] = OriReOdometerLimit --COLLATE DATABASE_DEFAULT
													  and o.[PlanOption] = OriRenewalPlanOption COLLATE DATABASE_DEFAULT
													  and o.[PremiumFrequency] = 'Monthly'--[RTF_Description] COLLATE DATABASE_DEFAULT
													  and o.[Effectivedate] = (select max([Effectivedate]) from [MSureEvolve].[dbo].[ms_santam_rating] where POL_SoldDate>=[Effectivedate])
---------------------------------------------------------------------------------------------------------------------------------------------
select *, E_NewPremiumRew/isnull(E_StartPremium,E_NewPremiumRew) PerChange, 
          OriE_NewPremiumRew/isnull(OriE_StartPremium,OriE_NewPremiumRew) OriPerChange, 
		  OriE_NewPremiumRew/ITS_Premium OldPerChange,

       case when RenewalAssumedOdoMeterReading >300000
	        then 'Tariff not calculated: Vehicle odometer reading not permissible for cover on any plan.'
			when  VehicleAgeAtRenewal > 15 then 'Tariff not calculated: Vehicle age not eligible for cover on any plan.'
			when E_StartPremium is NULL then 'This policy was not qualifying for '+[PRP_PlanName] +' at inception.'
			when E_StartPremium <> ITS_Premium  then 'The premium at inception was suppose to be ' 
			     + cast (E_StartPremium as varchar) +'.'

			else '' end Comments,
			       case when RenewalAssumedOdoMeterReading >300000
	        then 'Tariff not calculated: Vehicle odometer reading not permissible for cover on any plan.'
			when  VehicleAgeAtRenewal > 15 then 'Tariff not calculated: Vehicle age not eligible for cover on any plan.'
			when OriE_StartPremium is NULL then 'This policy was not qualifying for '+[PRP_PlanName] +' at inception.'
			when OriE_StartPremium <> ITS_Premium  then 'The premium at inception was suppose to be ' 
			     + cast (OriE_StartPremium as varchar) +'.'

			else '' end OriComments



into #res7

from #res6

where ITS_Premium <>0

--select * from #res6

-----------------------------------------------------------------------------------------------------------------------------------------------
select *, round( case --when CriteriaRenewal = CriteriaStart and RenewalPlanOption = PRP_PlanName then E_StartPremium
               when RenewalPlanOption = PRP_PlanName and  PerChange < @PerIncChange and PerChange >1 then E_NewPremiumRew
			   when RenewalPlanOption = PRP_PlanName and  PerChange < @PerIncChange  then E_StartPremium
			   when RenewalPlanOption = PRP_PlanName and  PerChange >= @PerIncChange then E_StartPremium * @PerIncChange
			   

			   when E_NewPremiumRew = E_StartPremium and RenewalPlanOption <> PRP_PlanName then E_StartPremium
			   when PerChange >= @PerIncChange and RenewalPlanOption <> PRP_PlanName then E_StartPremium * @PerIncChange
			   when PerChange < @PerIncChange  and PerChange > @PerDecChange  
			        and RenewalPlanOption <> PRP_PlanName then E_NewPremiumRew 
               when PerChange <= @PerDecChange and RenewalPlanOption <> PRP_PlanName then E_StartPremium * @PerDecChange
			   else null end,2) RenewalPremiumBeClaims ,

         round( case --when OriCriteriaRenewal = OriCriteriaStart and OriRenewalPlanOption = PRP_PlanName then OriE_StartPremium
		       when OriRenewalPlanOption = PRP_PlanName and  OriPerChange < @PerIncChange and OriPerChange>1 then OriE_NewPremiumRew
               when OriRenewalPlanOption = PRP_PlanName and  OriPerChange < @PerIncChange then OriE_StartPremium
			   when OriRenewalPlanOption = PRP_PlanName and  OriPerChange >= @PerIncChange then OriE_StartPremium * @PerIncChange

			   when OriE_NewPremiumRew = OriE_StartPremium and OriRenewalPlanOption <> PRP_PlanName then OriE_StartPremium
			   when OriPerChange >= @PerIncChange and OriRenewalPlanOption <> PRP_PlanName then OriE_StartPremium * @PerIncChange
			   when OriPerChange < @PerIncChange  and OriPerChange > @PerDecChange  
			        and OriRenewalPlanOption <> PRP_PlanName then OriE_NewPremiumRew 
               when OriPerChange <= @PerDecChange and OriRenewalPlanOption <> PRP_PlanName then OriE_StartPremium * @PerDecChange
			   else null end,2) OriRenewalPremiumBeClaims ,

         round( case --when OriCriteriaRenewal = OriCriteriaStart and OriRenewalPlanOption = PRP_PlanName then ITS_Premium
               when OriRenewalPlanOption = PRP_PlanName and  OldPerChange < @PerIncChange and OldPerChange > 1 then OriE_NewPremiumRew
			   when OriRenewalPlanOption = PRP_PlanName and  OldPerChange < @PerIncChange then ITS_Premium
			   when OriRenewalPlanOption = PRP_PlanName and  OldPerChange >= @PerIncChange then ITS_Premium * @PerIncChange

			   when OriE_NewPremiumRew = ITS_Premium and OriRenewalPlanOption <> PRP_PlanName then ITS_Premium
			   when OldPerChange >= @PerIncChange and OriRenewalPlanOption <> PRP_PlanName then ITS_Premium * @PerIncChange
			   when OldPerChange < @PerIncChange  and OldPerChange > @PerDecChange  
			        and OriRenewalPlanOption <> PRP_PlanName then OriE_NewPremiumRew 
               when OldPerChange <= @PerDecChange and OriRenewalPlanOption <> PRP_PlanName then ITS_Premium * @PerDecChange
			   else null end,2) OldRenewalPremiumBeClaims 



into #res8

from #res7
--------------------------------------------------------------------------------------------------------------------------------------------------------------
select *, round( case when ClaimsCount is null and CIS_AuthAmount is null then RenewalPremiumBeClaims 
               when ClaimsCount = 1 and  CIS_AuthAmount >0  then RenewalPremiumBeClaims * @InflationInc
			   when ClaimsCount > 1 and  CIS_AuthAmount >0  then RenewalPremiumBeClaims * @PerIncChange
			    when ClaimsCount = 1 and  CIS_AuthAmount = 0  then RenewalPremiumBeClaims

               else null end,2) RenewalPremium,

			   round( case when ClaimsCount is null and CIS_AuthAmount is null then OriRenewalPremiumBeClaims 
               when ClaimsCount = 1 and  CIS_AuthAmount >0  then OriRenewalPremiumBeClaims * @InflationInc
			   when ClaimsCount > 1 and  CIS_AuthAmount >0  then OriRenewalPremiumBeClaims * @PerIncChange
			    when ClaimsCount = 1 and  CIS_AuthAmount = 0  then OriRenewalPremiumBeClaims

               else null end,2) ORiRenewalPremium,

			   round( case when ClaimsCount is null and CIS_AuthAmount is null then OldRenewalPremiumBeClaims 
               when ClaimsCount = 1 and  CIS_AuthAmount >0  then OldRenewalPremiumBeClaims * @InflationInc
			   when ClaimsCount > 1 and  CIS_AuthAmount >0  then OldRenewalPremiumBeClaims * @PerIncChange
			    when ClaimsCount = 1 and  CIS_AuthAmount = 0  then OldRenewalPremiumBeClaims

               else null end,2) OldRenewalPremium

into #res9

from #res8

--------------------------------------------------------------------------------------------------------------------------------------------------

select --distinct
POL_PolicyNumber	PolicyNumber	,
--ITS_Item_ID	ITS_Item_ID	,
PMI_VehicleCode	VehicleCode	,
PMI_Make	Make	,
PMI_Model	Model	,
Make MakeSys,
PRP_PlanName	OriginalPlanOption	,
ITS_Premium	CurrentPremium	,
--OriE_NewPremiumRew CurrentPremiumForNewPol,
PMI_PresentKM OriginalOdoMeterReading,
PMI_RegistrationDate	RegistrationDate	, POL_SoldDate, POL_ReceivedDate,POL_RenewalDate,
E_StartPremium,	OriE_StartPremium,	PremiumAtInception,
VehicleAgeAtStart,VehicleAgeAtReceivedDate, dateadd(year,15,PMI_RegistrationDate) EndDate,@start StartVal,@k Factor,

case
     when VehicleAgeAtStart<=5 and VehicleAgeAtReceivedDate<=5 then 'Same Age'
	 when VehicleAgeAtStart >5 and VehicleAgeAtReceivedDate >5 and VehicleAgeAtStart<=8 and VehicleAgeAtReceivedDate<=8 then 'Same Age'
	 when VehicleAgeAtStart >8 and VehicleAgeAtReceivedDate >8 and VehicleAgeAtStart<=10 and VehicleAgeAtReceivedDate<=10 then 'Same Age'
	 when VehicleAgeAtStart >10 and VehicleAgeAtReceivedDate >10 and VehicleAgeAtStart<=12 and VehicleAgeAtReceivedDate<=12 then 'Same Age'
	 when VehicleAgeAtStart >12 and VehicleAgeAtReceivedDate >12 and VehicleAgeAtStart<=15 and VehicleAgeAtReceivedDate<=15 then 'Same Age'

	 else 'Diff Age' end Age,

case when abs( OriE_StartPremium	- PremiumAtInception)<=1 then 'Fine'
     when POL_SoldDate> POL_ReceivedDate  and  POL_SoldDate>='2024-01-01' then 'Old rates used' 



else 'Error' end PCheck

into #res10

--riComments	Comments	
 

from #res9


where 1=1

and abs( OriE_StartPremium	- PremiumAtInception)>1

--and POL_RenewalDate >='2024/01/01' --in('2023/06/01','2023/07/01','2023/08/01','2023/09/01')
--and POL_RenewalDate <='2024/02/29'
--and POL_PolicyNumber not like '%-%'
 --and POL_PolicyNumber ='SWTY000027POL'
 --and Comments<>''
--and E_StartPremium is null
--and POL_PolicyNumber like 'SWTY004415POL%'

--E_NewPremiumRew is null

order by POL_PolicyNumber;
---------------------------------------------------------------------------------------------------------------------------------------------

-- Create the valuation months  

With						cte As (  
Select						DATEADD(month, DATEDIFF(month, 0, @start), 0) MTH,         
							EOMONTH(DATEADD(month, DATEDIFF(month, 0, @start), 0)) ME,         
							CAST(1 as float) Surv  

Union all  
Select						DATEADD(Month, 1, cte.MTH) MTH,          
							EOMONTH(DATEADD(Month, 1, cte.MTH)) ME,         
							cte.Surv * (1 - @CancellationRate) Surv  

							

From						cte  
Where						EOMONTH(DATEADD(Month, 1, cte.MTH)) < @ProjectionEndMonth         
							)  
Select						*  
Into						#MTH  
From						cte   
Option						(Maxrecursion 500);    



select 

PolicyNumber	,
VehicleCode	,
Make	,
Model	,
MakeSys	,
OriginalPlanOption	,
CurrentPremium	,
--OriginalOdoMeterReading	,
--RegistrationDate	,
--POL_SoldDate	,
--POL_ReceivedDate	,
--POL_RenewalDate	,
--E_StartPremium	,
OriE_StartPremium * Power(Factor,datediff(Month,StartVal,Me))	OriE_StartPremium,
PremiumAtInception * Power(Factor,datediff(Month,StartVal,Me)) PremiumAtInception	,
--VehicleAgeAtStart	,
--VehicleAgeAtReceivedDate	,
EndDate	,
Age	,
PCheck	,
MTH	,
ME	,
Surv	



from #res10 cross join #mth 

where 1=1
and ME < EndDate 
--and PolicyNumber = 'SWTY004476POL-01'





