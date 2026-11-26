-- Převod stávajících dat z původního webu. Bezpečné spouštět opakovaně: nic nepřepisuje a nevytváří duplicity (on conflict do nothing).
begin;
insert into public.site_settings(id,data) values (1,'{"name": "M-klub", "logo": "/logo.png", "hero": "", "accent": "", "email": "mklub@mklub.cz", "phone": "465 420 420", "address": "Litomyšlská 72, 566 01 Vysoké Mýto", "tickets": "", "ga": "", "facebook": "https://www.facebook.com/profile.php?id=61575567497951", "instagram": "https://www.instagram.com/mklub_vysoke_myto?igsh=a3FxdzBkeHp5cHRt", "youtube": "https://www.youtube.com/user/MklubVM#p/u", "bandzone": "http://bandzone.cz/klub/mklubvysokemyto", "mapUrl": "https://goo.gl/maps/sVgNCXQQx4Q2"}'::jsonb) on conflict (id) do nothing;
insert into public.categories(name,slug,sort) values ('Koncerty','koncerty',1) on conflict do nothing;
insert into public.categories(name,slug,sort) values ('Divadlo','divadlo',2) on conflict do nothing;
insert into public.categories(name,slug,sort) values ('Kino','kino',3) on conflict do nothing;
insert into public.categories(name,slug,sort) values ('Kurzy','kurzy',4) on conflict do nothing;
insert into public.categories(name,slug,sort) values ('Besedy','besedy',5) on conflict do nothing;
insert into public.categories(name,slug,sort) values ('Ostatní akce','ostatni-akce',6) on conflict do nothing;
insert into public.categories(name,slug,sort) values ('Pronájem','pronajem',7) on conflict do nothing;
insert into public.events(id,iso,t,category,title,descr,price,place,availability,info_url,ticket_url,image) values ('e1','2026-10-21','19:00','Divadlo','ADF – Peter Quilter: Tak já letim!','Vše se dá přežít s nadhledem, sebeironií a humorem.','580 / 560 / 540 Kč','Šemberovo divadlo','ok','','','') on conflict (id) do nothing;
insert into public.events(id,iso,t,category,title,descr,price,place,availability,info_url,ticket_url,image) values ('e2','2026-11-06','19:00','Koncerty','Lucie Bílá – recitál','Recitál několikanásobné zlaté slavice Lucie Bílé za klavírního doprovodu Petra Maláska.','1590 / 1570 / 1550 Kč','Vysoké Mýto','ok','','','') on conflict (id) do nothing;
insert into public.events(id,iso,t,category,title,descr,price,place,availability,info_url,ticket_url,image) values ('e3','2026-11-14','17:00','Besedy','Snow Film Fest | Háčkova přednáška „SNOW“','1. ročník Snow film festu ve Vysokém Mýtě. Součástí bude přednáška horolezce, skialpinisty a dobrodruha Zdeňka „Háčka“ Háka nazvaná SNOW.','předprodej 200 Kč / na místě 250 Kč','Vysoké Mýto','ok','','','') on conflict (id) do nothing;
insert into public.events(id,iso,t,category,title,descr,price,place,availability,info_url,ticket_url,image) values ('e4','2026-11-19','20:00','Divadlo','LiStOVáNí: Deník lehké holky (Celeste Will)','Cyklus scénických čtení aneb knížky na jevišti. Hrají: Daniela Šišková a Jakub Koudela.','předprodej 190 Kč / na místě 240 Kč','Vysoké Mýto','ok','','','') on conflict (id) do nothing;
insert into public.events(id,iso,t,category,title,descr,price,place,availability,info_url,ticket_url,image) values ('e5','2026-11-22','19:00','Koncerty','Dan Bárta & Illustratosphere & Lash & Grey','Stříbrná svatba tour 2026. Exkluzivní koncert v M-klubu!','550 Kč (prvních 100 ks) / 670 Kč (dalších 100 ks) / 770 Kč (posledních 100 ks)','M-klub','ok','','','') on conflict (id) do nothing;
insert into public.news(id,iso,title,descr,image) values ('n1',null,'Startujeme pravidelné M-kvízy!','Přihlašte se na nové hospodské kvízy v M-klubu. Pořádáme ve čtvrtek jednou za 14 dní!','') on conflict (id) do nothing;
insert into public.spaces(id,title,place,capacity,descr,contact,image,sort) values ('s1','Klubová scéna','Litomyšlská 71, 566 01 Vysoké Mýto','','Univerzální prostor pro koncerty a další aktivity. Na Klubovce můžete navštívit akci nebo si ji pronajmout pro vlastní program.','Pavel Kopp, tel. 465 420 420, 739 062 915','',1) on conflict (id) do nothing;
insert into public.spaces(id,title,place,capacity,descr,contact,image,sort) values ('s2','Společenský sál','M-klub, Litomyšlská 71, 566 01 Vysoké Mýto','','Sál v budově M-klubu pro společenské akce.','Pavel Kopp, tel. 465 420 420, 739 062 915','',2) on conflict (id) do nothing;
insert into public.spaces(id,title,place,capacity,descr,contact,image,sort) values ('s3','Šemberovo divadlo','Komenského 281, 566 01 Vysoké Mýto','','V sále Šemberova divadla pravidelně probíhají filmová, divadelní a koncertní představení. Vstupenky se prodávají půl hodiny před začátkem představení.','Pavel Kopp, tel. 465 420 420, 739 062 915','',3) on conflict (id) do nothing;
insert into public.spaces(id,title,place,capacity,descr,contact,image,sort) values ('s4','(M)BAR','Litomyšlská 71, 566 01 Vysoké Mýto','','(M)BAR je otevřen pravidelně každý týden: pátek a sobota 19:00–24:00. Vedoucí baru David Řehák.','David Řehák, rezervace tel. 731 269 447','',4) on conflict (id) do nothing;
insert into public.spaces(id,title,place,capacity,descr,contact,image,sort) values ('s5','Amfiteátr M-KLUBU','Vysoké Mýto','','V letních měsících se v Amfiteátru M-KLUBU pořádají akce.','Pavel Kopp, tel. 465 420 420, 739 062 915','',5) on conflict (id) do nothing;
insert into public.page_contents(key,body) values ('about','VYSOKOMÝTSKÁ KULTURNÍ o. p. s. — středisko M-klub. Obecně prospěšnou společnost zřídilo Město Vysoké Mýto k 1. 8. 2012. Zajišťuje kulturní, pořadatelskou a agenturní činnost pro obyvatele města a regionu a propaguje místní kulturu. Vytváří také podmínky pro zájmové spolky a neprofesionální kulturu.

## Co děláme

V čele společnosti stojí ředitel, kterého jmenuje starosta města. Úsek mimoškolního vzdělávání připravuje jazykové, hudební a taneční kurzy, přednášky, besedy a školení. Dramaturgie nabízí divadlo, film, koncerty a taneční večery a odpoledne.

Spolupracujeme s divadelním spolkem Šembera, pěveckým sborem Otakar a loutkovým divadlem Srdíčko. V létě pořádáme akce v Amfiteátru M-klubu a celoročně pronajímáme všechny budovy. Součástí práce jsou i celoměstské, regionální a celostátní akce s mezinárodní účastí.') on conflict (key) do nothing;
insert into public.page_contents(key,body) values ('rent','Za výhodných podmínek pronajmeme M-klub a Šemberovo divadlo. Konkrétní ceny pronájmů vám sdělíme na dotaz. Kontaktní osoba: Pavel Kopp, tel. 465 420 420, 739 062 915.') on conflict (key) do nothing;
insert into public.page_contents(key,body) values ('hours','Kancelář (září–červen): pondělí a středa 8:00–16:30

Kancelář (červenec–srpen): středa 8:00–16:30

(M)BAR: pátek a sobota 19:00–24:00') on conflict (key) do nothing;
insert into public.page_contents(key,body) values ('posters','Zajistěte si viditelnost své akce jednoduše a online. Výlep zajišťuje Vysokomýtská kulturní, o. p. s. na 17 plochách ve městě.

## Výlepové dny

Úterý a čtvrtek (jen pracovní dny mimo státní svátky). Plakáty musí být doručeny nejpozději den před výlepem. Objednávejte alespoň 3 pracovní dny předem. Přijímáme minimálně 17 plakátů a doporučujeme přidat 10 % kusů navíc na opravy.

## Jak postupovat

1) Vyplňte elektronický objednávkový formulář.
2) Počkejte na potvrzení e-mailem (do 3 pracovních dnů), objednávka platí až po něm.
3) Doručte plakáty označené číslem objednávky do kanceláře M-klubu (Litomyšlská 71) nebo do označené schránky vlevo za mřížemi u vchodu.
4) Výlep provedeme v nejbližší výlepový den.

## Upozornění

Plakáty bez čísla objednávky nepřijímáme. Nevylepujeme plakáty s nenávistným, rasistickým či politickým obsahem a vyhrazujeme si právo výlep odmítnout.

## Odpovědná osoba

Petra Till — tel. 465 420 420 / 603 194 029') on conflict (key) do nothing;
insert into public.page_contents(key,body) values ('staff','Ředitel společnosti | Tibor Pagáč | 
Vedoucí M-klubu, hudební dramaturgie, kino, jarmarky | Ing. Pavel Kopp | 739 062 915
Programová referentka, kurzy, výlep plakátů | Petra Till | 603 194 029
Programový referent, pronájem prostor | Josef Stoklasa | 
Ekonom | Pavel Stránský | 739 064 714
Divadelní dramaturgie | Martina Skálová, DiS. | 
Vedoucí údržby | Jaroslav Jindra | 
Mistr zvuku, technické zajištění akcí | Marcel Svěrák | 
Vedoucí barů | David Řehák | 731 269 447') on conflict (key) do nothing;
insert into public.page_contents(key,body) values ('company','VYSOKOMÝTSKÁ KULTURNÍ, o. p. s.
IČO: 28852150, DIČ: CZ28852150
Č. ú.: 107-2997920237/0100
Č. ú. vstupenky: 107-6260510207/0100
ID datové schránky: 9ryksqp
Zastoupená ředitelem Tiborem Pagáčem') on conflict (key) do nothing;
insert into public.published_site(id,snapshot) select 1, public.build_snapshot() on conflict (id) do nothing;
commit;
