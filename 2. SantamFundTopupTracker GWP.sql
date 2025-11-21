--**************************************
-- Santam Fund Topup Tracker
--**************************************

-- Define the database to use
Use								Evolve;

-- Clear previous results
Drop table if exists			#Base;
Drop table if exists			#Pol;

-- Declare variables
Declare							@start date = '01-Jan-2022';
Declare							@end date = '01-Nov-2025'; -- a day after the month-end of interest.

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








-- Get all policy numbers linked to the base policy key 
SELECT							Distinct LEFT(p.POL_PolicyNumber, CHARINDEX('POL', p.POL_PolicyNumber) + 3 - 1) AS BasePolicyNumber,
								p.POL_PolicyNumber,
								p.POL_Status,
								rps.POS_Description StatusDescription
Into							#Pol
FROM							Policy p
								Inner join #Base b 
								on LEFT(p.POL_PolicyNumber, CHARINDEX('POL', p.POL_PolicyNumber) + 3 - 1) = b.POL_PolicyNumber
								Left join ReferencePolicyStatus rps
								on rps.PolicyStatus_ID = p.Pol_Status
WHERE							1 = 1
								and CHARINDEX('POL', p.POL_PolicyNumber) > 0;

-- Get the gross written premium on the policies 
With gwp as						(
Select							ats.ATS_DisplayNumber [DisplayNumber], 
								i.INS_InsurerName [Insurer], 
								ats.ATS_Description [Description], 
								att.ATT_Description [Transaction Type], 
								Main.GLC_GlCode MainGlCode, 
								Main.GLC_Description MainGlDescription, 
								isnull(VAT.GLC_GlCode,'') VatGlCode, 
								isnull(VAT.GLC_Description,'') VATGlDescription,
								p.PRD_GLCode [Product], 
								main.GLC_Category [Category], 
								ats.ATS_TransactionNumber [Transaction number], 
								Party.APY_PartyNumber [Party Number], 
								Party.APY_Name [Party], 
								d.DBT_Description [Disbursement Type],
								ats.ATS_CreateDate, 
								ats.ATS_EffectiveDate,
								case when atn.ATN_VATAmount = 0 then 1 else 2 end VATType, 
								case when atn.ATN_VATAmount = 0 then Main.glc_VATType ELSE Main.glc_VATType END GPVATType,  
								(atn.ATN_GrossAmount) GrossAmount, 
								(atn.ATN_VATAmount) VATAmount, 
								(atn.ATN_NettAmount) NettAmount,
								DATEADD(month, DATEDIFF(month, 0, IIF(ats.ATS_CreateDate > ats.ATS_EffectiveDate, ats.ATS_CreateDate, ats.ATS_EffectiveDate)), 0) AccountingMonth
From							Evolve.dbo.AccountTransactionSet ats 
								Left Outer Join Evolve.dbo.Insurer i
								on ats.ATS_Insurer_Id = i.Insurer_Id 
								Left Outer Join Evolve.dbo.Product p
								on ats.ATS_Product_Id = p.Product_Id 
								Left Outer Join Evolve.dbo.SalesBranch Branch 
								on ATS_SalesBranch = Branch.SalesRegion_ID, 
								Evolve.dbo.AccountTransaction atn
								Left Outer Join Evolve.dbo.ReferenceGLCode Main 
								on atn.ATN_GLCode_ID = Main.GlCode_ID 
								Left Outer Join Evolve.dbo.ReferenceGLCode VAT 
								on atn.ATN_GLCodeVAT_ID = VAT.GlCode_ID 
								Left Outer Join Evolve.dbo.AccountParty Party 
								on AccountParty_Id = ATN_AccountParty_ID 
								Left Join Evolve.dbo.DisbursementType d
								on atn.ATN_DisbursementType_ID = d.DisbursementType_Id
								Left Join Evolve.dbo.AccountTransactionType att
								on atn.ATN_AccountTransactionType_ID = att.AccountTransactionType_Id 
Where							ATN_AccountTransactionSet_ID = AccountTransactionSet_ID 
								and ATN_GrossAmount <> 0 
								and Main.GLC_GlCode in ('100000')
								AND IIF(ats.ATS_CreateDate > ats.ATS_EffectiveDate, ats.ATS_CreateDate, ats.ATS_EffectiveDate) >= @start
								AND IIF(ats.ATS_CreateDate > ats.ATS_EffectiveDate, ats.ATS_CreateDate, ats.ATS_EffectiveDate) < @end
								AND ats.ATS_CreateDate < @end
								and i.INS_Deleted = 0
								and p.PRD_Deleted = 0)
Select							gwp.*,
								p.*
From							gwp 
								inner join #Pol p
								on gwp.DisplayNumber = p.POL_PolicyNumber;

-- Garbage collection
--Drop table if exists			#Base;	
--Drop table if exists			#Pol;

--select * from #Pol

--select * from #Base