# TüskeAI Architecture Roadmap

## Dokumentum célja

Ez a roadmap a TüskeAI jelenlegi, helyi projektfájlokból ellenőrzött állapotából indul ki. A „jelenleg” megjelölés implementált elemet, a „tervezett” megjelölés jövőbeli fejlesztést jelent. A fázisok nem írják felül a meglévő architektúrát, nem egyesítik az Agenteket, és megtartják a Closed World helyi működését.

## Kiinduló állapot

Jelenleg ellenőrzötten rendelkezésre áll:

- külön Agent-konfiguráció szerverrel, modellnévvel és saját prompttal;
- helyi Ollama-kapcsolat az `AgentModelService` protokoll és az `OllamaClient` révén;
- soros, hibatűrő `ChatCoordinator` és külön `AgentResponse` eredmények;
- `World`, `City`, `Village`, `WorldLocation` és `WorldChatCoordinator` adatmodell;
- iOS chatnézet, amely még a korábbi közvetlen modellhívást használja;
- egyszerű beszédszintézis a `VoiceManager` fájlban;
- külön macOS target és alkalmazásindítási képesség az `AppLauncher` segítségével.

Memória-, kép-/videófeldolgozó és többgépes felügyeleti réteg jelenleg nem azonosítható kész komponensként.

---

## Phase 1 – Alap rendszer

**Cél:** Stabil, tesztelhető helyi alap létrehozása úgy, hogy az egyes Agentek identitása és a meglévő egyszereplős működés változatlan maradjon.

**Szükséges komponensek:**

- meglévő `Agent`, `AgentModelService`, `OllamaClient` és beállításkezelés stabilizálása;
- egységes, de Agentenként külön konfigurációs forrás;
- modell- és hostelérhetőségi ellenőrzés;
- strukturált hibák és helyi naplózás;
- unit- és smoke tesztek az Agent–modell–host megfeleltetésekhez;
- a `ContentView` közvetlen Ollama-hívásának későbbi átvezetése a szolgáltatási rétegre, viselkedésváltozás nélkül.

**Függőségek:** Helyben futó Ollama, ellenőrzött helyi modellnevek, Mac/ASUS hostbeállítások, meglévő UI.

**Várható nehézség:** Közepes.

**Kockázatok:** A párhuzamos régi és új hálózati út eltérhet; egy nem ellenőrzött modellnév hibás identitást adhat; a meglévő felhasználói beállítások sérülhetnek migráció során.

**Mikor érdemes elkezdeni:** Azonnal. Ez minden további fázis belépési feltétele. Akkor zárható le, ha az egyszereplős chat ugyanúgy működik, a modellkapcsolat tesztelhető, és nincs közvetlenül duplikált hálózati logika.

**Mi van már kész:** Az `Agent` konfiguráció, az `AgentModelService` protokoll, az `OllamaClient`, a helyi hostválasztás és a meglévő egyszereplős UI működési alapja rendelkezésre áll. Kai külön Agentként szerepel.

**Mi hiányzik még:** A chat UI még saját közvetlen `URLSession`-hívást használ; nincs egységes konfigurációs forrás, automatikus modell-elérhetőségi teszt vagy teljes alapréteg-tesztcsomag.

**Konkrét következő mérföldkő:** Az egyszereplős `ContentView` modellhívását viselkedésváltozás nélkül átvezetni az `AgentModelService` rétegen, majd fordítással és célzott teszttel igazolni a kompatibilitást.

**A következő fázis elkezdésének feltételei:** Az egyszereplős chat ugyanazzal az Agent-, modell- és promptkiválasztással működik az új szolgáltatási úton; a Mac és ASUS hostkezelés ellenőrzött; a fordítás és az alap smoke tesztek sikeresek.

**Visszamaradható technikai adósság:** A konfiguráció kezdetben maradhat statikus Swift-adat, és a naplózás lehet egyszerű helyi diagnosztika. Nem maradhat két eltérő éles Ollama-hívási út vagy nem ellenőrzött modell-hozzárendelés.

**Továbblépés előtti tesztek:** Egyszereplős sikeres válasz; hibás host; nem futó Ollama; timeout; üres és hibás HTTP-válasz; Agent–modell–host megfeleltetés; meglévő szereplők regressziós tesztje; iOS és macOS target fordítása.

---

## Phase 2 – Több szereplős chat

**Cél:** Több, külön identitású Agent válaszainak közös beszélgetésben történő biztonságos kezelése, felhasználó által kiválasztott résztvevőkkel.

**Szükséges komponensek:**

- meglévő `ChatCoordinator` és `AgentResponse` megtartása;
- közös beszélgetés- és üzenetmodell;
- Agent-kiválasztási állapot, alapértelmezett automatikus „mindenki válaszol” nélkül;
- közös előzményből Agentenként összeállított, saját rendszerpromptot megőrző kérés;
- válaszállapotok megjelenítése: folyamatban, siker, hiba, timeout;
- koordinátor- és UI-integrációs tesztek.

**Függőségek:** Lezárt Phase 1; stabil `AgentModelService`; egyértelmű üzenetazonosítók és sorrend.

**Várható nehézség:** Közepes–magas.

**Kockázatok:** Hosszú kontextus és lassú soros válaszadás; szereplőpromptok összekeverése; duplikált üzenetek; egy hibás UI-állapot a sikeres válaszokat is elrejtheti.

**Mikor érdemes elkezdeni:** Ha az egyszereplős szolgáltatási út stabil és automatikus teszttel ellenőrzött. Első kiadásban maradjon soros végrehajtás, mert ez egyezik a jelenlegi koordinátor működésével.

**Mi van már kész:** A `ChatCoordinator` sorban hív több Agentet, Agentenként külön `AgentResponse` objektumot ad vissza, és hiba vagy timeout után folytatja a feldolgozást. A modellhívás protokollon keresztül történik.

**Mi hiányzik még:** Nincs közös beszélgetésmodell, résztvevőválasztás, közös előzménykezelés, több-Agentes UI vagy folyamatban lévő válaszállapot.

**Konkrét következő mérföldkő:** Létrehozni a közös beszélgetés és üzenet adatmodelljét, valamint automatizált tesztben igazolni, hogy a kiválasztott Agentek a megadott sorrendben, saját prompttal kapják meg az előzményeket.

**A következő fázis elkezdésének feltételei:** A beszélgetés- és üzenetazonosítók stabilak; az Agent-választás explicit; minden válasz külön állapotobjektum; egy Agent hibája nem szakítja meg a sort; az egyszereplős út változatlanul működik.

**Visszamaradható technikai adósság:** Az első kiadás maradhat soros és korlátozott kontextusablakú. A streaming, párhuzamos válaszadás és fejlett válaszprioritás későbbre halasztható. Az Agent-promptok összekeveredése nem elfogadható adósság.

**Továbblépés előtti tesztek:** Egy, több és nulla kiválasztott Agent; válaszsorrend; saját prompt Agentenként; közös előzmény átadása; részleges hiba és timeout; duplikáció elleni teszt; hosszú beszélgetés; UI-állapotok; egyszereplős regresszió.

---

## Phase 3 – Világok, Városok, Falvak

**Cél:** A beszélgetések és Agentek rendezése külön Worldökbe, azon belül City és Village helyszínekbe, a helyszínek közötti identitás- és állapothatárok megtartásával.

**Szükséges komponensek:**

- meglévő `World`, `City`, `Village`, `WorldLocation` és `WorldChatCoordinator` továbbvitele;
- World-szintű stabil azonosító, név és leírás, mert ezek jelenleg még hiányoznak;
- World- és helyszínjegyzék külön konfigurációs/tárolási rétegben;
- kiválasztott World és kiválasztott helyszín alkalmazásállapota;
- helyszínhez tartozó beszélgetések kapcsolata;
- későbbi UI: World- és helyszínválasztás, csak az adatmodell lezárása után.

**Függőségek:** Phase 2 közös beszélgetésmodellje; stabil Agent-azonosítók; egyedi helyszínazonosítók.

**Várható nehézség:** Közepes.

**Kockázatok:** Az Agent konfiguráció és helyszíntagság összekeverése; azonosítóütközés; törölt helyszínre mutató beszélgetés; tesztadatok véletlen éles konfigurációvá válása.

**Mikor érdemes elkezdeni:** Az adatmodell alapja már elkészült. A perzisztens World-kezelést akkor érdemes kezdeni, amikor a Phase 2 üzenetmodell stabil, különben később költséges adatmigráció szükséges.

**Mi van már kész:** A `World`, `City`, `Village`, `WorldLocation`, helyszínkiválasztás, egyedi helyszínazonosító-ellenőrzés és a `WorldChatCoordinator` összekötő réteg elkészült. Külön smoke teszt ellenőrizte a helyszínenkénti Agent-szűrést.

**Mi hiányzik még:** A Worldnek nincs saját azonosítója, neve vagy leírása; nincs World-jegyzék, perzisztencia, éles konfiguráció, beszélgetéskapcsolat vagy UI.

**Konkrét következő mérföldkő:** A Phase 2 üzenetmodell lezárása után meghatározni a World stabil identitását és a World–helyszín–beszélgetés kapcsolatot, migrálható adatmodelltesztekkel.

**A következő fázis elkezdésének feltételei:** A World, City, Village és beszélgetés stabil azonosítókkal rendelkezik; a kiválasztott helyszín kizárólag a saját Agentjeit adja; az éles és tesztkonfiguráció fizikailag elkülönül; a célhierarchia döntése dokumentált.

**Visszamaradható technikai adósság:** Az első tartós verzió egyetlen aktív Worldöt kezelhet, és a World-választó UI későbbre maradhat. Fontos: a jelenlegi kódban City és Village testvér `WorldLocation` típusok. A kért jövőbeli World → City → Village hierarchia külön, verziózott adatmodell-migrációt igényel; ezt nem szabad névleges átértelmezéssel elrejteni.

**Továbblépés előtti tesztek:** Egyedi és ütköző azonosítók; City/Village Agent-elszigetelés; helyszínváltás; hiányzó kiválasztás; törölt helyszínre mutató állapot; konfiguráció be-/kiolvasás; migráció; WorldChatCoordinator integráció; tesztadat éles betöltésének tiltása.

---

## Phase 4 – Memória

**Cél:** Minden Agent számára önálló, helyi és ellenőrizhető memória biztosítása, valamint a közös beszélgetési előzmények elkülönített kezelése.

**Szükséges komponensek:**

- `MemoryService` absztrakció;
- Agentenként külön memória-névtér vagy adatbázis;
- beszélgetés-, World- és helyszínazonosítókkal kapcsolt üzenettárolás;
- rövid távú kontextusépítő és hosszú távú visszakeresés;
- helyi migráció, mentés, visszaállítás és integritás-ellenőrzés;
- törlési, exportálási és hozzáférési szabályok;
- Liliom biztonsági és Sentinel felügyeleti szerepéhez később illeszthető auditpontok, identitásuk összevonása nélkül.

**Függőségek:** Stabil Agent-, World-, helyszín-, beszélgetés- és üzenetazonosítók a Phase 2–3-ból.

**Várható nehézség:** Magas.

**Kockázatok:** Agentek memóriájának összekeverése; adatvesztés vagy hibás migráció; túl sok irreleváns kontextus; érzékeny helyi adatok jogosulatlan elérése; mentések és aktív adatbázis eltérése.

**Mikor érdemes elkezdeni:** Csak az adatmodell lezárása és biztonsági mentés után. Először üzenetnapló, utána visszakeresés, végül automatikus hosszú távú memória.

**Mi van már kész:** Az Agentek stabil, külön azonosítóval rendelkeznek, az `AgentResponse` pedig rögzíti a válasz Agentjét, állapotát, időpontját és eredményét. Ez alapot ad a későbbi memóriarekordokhoz.

**Mi hiányzik még:** Nincs memóriaszolgáltatás, adatbázis, üzenetperzisztencia, Agentenkénti névtér, visszakeresés, migráció, mentés vagy törlési szabály.

**Konkrét következő mérföldkő:** A stabil beszélgetésazonosítók után elkészíteni egy kizárólag helyi, Agentenként elkülönített, menthető üzenetnapló specifikációját és migrációs tesztjét.

**A következő fázis elkezdésének feltételei:** Agentenkénti memóriahatár bizonyított; az adatbázis menthető és visszaállítható; a séma verziózott; a felhasználó törölheti és exportálhatja a saját helyi adatait; hibás migrációból vissza lehet állni.

**Visszamaradható technikai adósság:** Kezdetben elegendő lehet kulcsszavas vagy időalapú visszakeresés, és halasztható az embedding-alapú keresés. Nem maradhat közös, Agent-azonosító nélküli memóriatábla vagy ellenőrizetlen automatikus memóriaírás.

**Továbblépés előtti tesztek:** Agentek közötti memóriaelszigetelés; World/helyszín határok; mentés és visszaállítás; sémafrissítés és rollback; törlés; sérült adatbázis; nagy előzmény; konkurens olvasás/írás; érzékeny adatok helyi maradása.

---

## Phase 5 – Hang

**Cél:** Megbízható helyi beszédkimenet, majd opcionális beszédfelismerés Agentenként megőrzött hang- és nyelvi beállításokkal.

**Szükséges komponensek:**

- a meglévő `VoiceManager` felülvizsgálata és protokoll mögé helyezése;
- Agentenkénti hangprofil és magyar nyelvi fallback;
- lejátszási sor, megszakítás, némítás és állapotkezelés;
- később helyi vagy rendszer-szintű speech-to-text szolgáltatás;
- mikrofonengedélyek és látható rögzítési állapot;
- hangfunkciók tesztje a chatlogika módosítása nélkül.

**Függőségek:** Phase 2 stabil válaszobjektumai; iOS/macOS audioengedélyek; ellenőrzött helyi hangtechnológia.

**Várható nehézség:** Közepes kimenetnél, magas kétirányú hangnál.

**Kockázatok:** Rossz nyelv vagy hang; válaszok egymásra beszélése; mikrofon-adatvédelmi probléma; nagy késleltetés; platformonként eltérő viselkedés. A jelenlegi `VoiceManager` spanyol, majd angol fallbacket használ, ezért magyar hang előtt ezt ellenőrizni kell.

**Mikor érdemes elkezdeni:** A több-Agentes válaszsorrend stabilizálása után. Elsőként csak beszédkimenet, utána külön fáziskapuként beszédfelismerés.

**Mi van már kész:** A `VoiceManager` az `AVSpeechSynthesizer` használatával képes szöveget felolvasni, és a jelenlegi iOS `ContentView` példányosítja ezt a komponenst.

**Mi hiányzik még:** Nincs magyar elsődleges hangprofil, Agentenkénti hang, lejátszási sor, megszakítási állapot, protokollos absztrakció, beszédfelismerés vagy audio-teszt.

**Konkrét következő mérföldkő:** A `VoiceManager` jelenlegi viselkedésének tesztelése után meghatározni egy magyar beszédkimeneti szolgáltatási interfészt és az Agentenkénti hangprofil adatmodelljét.

**A következő fázis elkezdésének feltételei:** A hangfunkció kikapcsolható; magyar szöveg megfelelő hanggal olvasható; több Agent válasza sorba rendezhető és megszakítható; mikrofon használatakor az engedély és rögzítési állapot látható.

**Visszamaradható technikai adósság:** A beszédfelismerés és egyedi neurális hangok későbbre maradhatnak; az első verzió használhat rendszerhangokat. Nem maradhat rejtett mikrofonaktiválás vagy nem szabályozható automatikus felolvasás.

**Továbblépés előtti tesztek:** Magyar kiejtési próba; hangprofil Agentenként; sorba állítás és megszakítás; néma mód; háttér/előtérré váltás; hiányzó hang fallback; engedély megtagadása; hosszú szöveg; iOS/macOS regresszió.

---

## Phase 6 – Programvezérlés (Mac)

**Cél:** Engedélyezett Mac-alkalmazások és műveletek biztonságos, naplózott vezérlése, egyértelmű felhasználói jóváhagyással.

**Szükséges komponensek:**

- a meglévő macOS target és `AppLauncher` megőrzése;
- `ToolService`/műveleti protokoll a modell és az operációs rendszer közé;
- engedélylista, bemenetvalidálás és művelettípusok;
- jóváhagyási felület visszafordítható és kockázatos műveletekhez;
- auditnapló és eredményobjektum;
- Töki technikai feladatainak külön jogosultsági profilja;
- Liliom hozzáférés-ellenőrzési és Sentinel felügyeleti pontjai, ha később ténylegesen implementálva lesznek.

**Függőségek:** Stabil macOS alkalmazás; Phase 4 auditálható helyi tárolása; jogosultsági modell; macOS sandbox- és Automation-engedélyek.

**Várható nehézség:** Nagyon magas.

**Kockázatok:** Téves vagy destruktív művelet; prompt injection; túl széles jogosultság; alkalmazásnév-ütközés; adatvesztés; macOS engedélyek megváltozása.

**Mikor érdemes elkezdeni:** Csak a memória, naplózás, jóváhagyási és helyreállítási alapok után. Első verzió kizárólag alkalmazásindítás és olvasási jellegű diagnosztika legyen.

**Mi van már kész:** Külön macOS target létezik. Az `AppLauncher` az `NSWorkspace` segítségével alkalmazásokat tud indítani, a macOS nézet pedig több konkrét alkalmazáshoz kínál indítást.

**Mi hiányzik még:** Nincs általános tool-protokoll, Agenthez kötött jogosultság, műveleti jóváhagyás, auditnapló, diagnosztikai eredményobjektum vagy biztonsági szabálymotor.

**Konkrét következő mérföldkő:** Dokumentálni és tesztelni egy szűk, csak alkalmazásindítást engedélyező műveleti szerződést, amely engedélylistát és minden kéréshez felhasználói jóváhagyást követel.

**A következő fázis elkezdésének feltételei:** A tool-réteg csak engedélyezett műveletet hajt végre; minden állapotváltoztató kérés jóváhagyható vagy elutasítható; az eredmény naplózott; hibás modellkimenet nem válhat közvetlen rendszerparanccsá; helyreállítás dokumentált.

**Visszamaradható technikai adósság:** Az első verzió támogathat kevés, kézzel regisztrált alkalmazást, és maradhat egyfelhasználós. Nem maradhat tetszőleges shell-végrehajtás, korlátlan fájlhozzáférés vagy jóváhagyás nélküli destruktív művelet.

**Továbblépés előtti tesztek:** Engedélyezett/tiltott app; hiányzó alkalmazás; jóváhagyás és elutasítás; prompt injection; hibás argumentum; ismételt kérés; auditnapló; macOS jogosultság megtagadása; sandbox; alkalmazásindítási regresszió.

---

## Phase 7 – Képek és videók

**Cél:** Helyi képek és videók ellenőrzött elemzése, előállítása és szerkesztési munkafolyamatokba illesztése, az eredeti fájlok megőrzésével.

**Szükséges komponensek:**

- médiaeszköz- és projektmodell;
- helyi fájlimport, metaadatok és előnézet;
- képi/videós szolgáltatási protokollok;
- helyi modellek vagy engedélyezett Mac-alkalmazások adapterei;
- nem destruktív munkafolyamat, verziók és export;
- feladatsor, folyamatjelzés, megszakítás és tárhelyfigyelés;
- később DaVinci Resolve-integráció külön, korlátozott adapterként.

**Függőségek:** Phase 6 biztonságos programvezérlése; helyi médiaeszközök; elegendő tárhely/GPU; mentési stratégia.

**Várható nehézség:** Nagyon magas.

**Kockázatok:** Nagy fájlok és tárhelyhiány; hosszú GPU-terhelés; eredeti média felülírása; inkompatibilis formátumok; alkalmazásautomatizálási törékenység; személyes média kiszivárgása.

**Mikor érdemes elkezdeni:** A biztonságos tool-réteg elkészülte után. Először csak import és elemzés, majd nem destruktív képszerkesztés, végül videó és külső alkalmazásintegráció.

**Mi van már kész:** A projekt rendelkezik képi assetekkel, az Agentekhez képnevek tartoznak, a macOS indítófelület pedig már hivatkozik a DaVinci Resolve alkalmazásra. Ez még nem jelent médiafeldolgozó architektúrát.

**Mi hiányzik még:** Nincs médiaadatmodell, fájlimport, képelemző vagy generáló szolgáltatás, videós feladatsor, verziózás, nem destruktív export vagy DaVinci-adapter.

**Konkrét következő mérföldkő:** A Phase 6 biztonsági rétege után elkészíteni egy csak olvasási jogosultságú helyi médiaimport- és metaadatmodellt, amely soha nem módosítja az eredeti fájlt.

**A következő fázis elkezdésének feltételei:** Az eredeti média változatlansága garantált; az import és export külön útvonal; a hosszú feladat megszakítható; tárhely- és erőforráskorlátok mérhetők; minden külső alkalmazásművelet jóváhagyott.

**Visszamaradható technikai adósság:** Az első verzió kevés formátumot és csak képelemzést támogathat; videógenerálás és DaVinci-automatizálás halasztható. Nem maradhat eredeti fájlt felülíró vagy automatikusan feltöltő folyamat.

**Továbblépés előtti tesztek:** Fájltípusok és hibás média; nagy fájl; tárhelyhiány; megszakítás; eredeti hash változatlansága; verziózott export; GPU/CPU korlát; személyes média hozzáférése; DaVinci nélkül működő alapút.

---

## Phase 8 – Több gépből álló világ

**Cél:** A Mac, ASUS és későbbi helyi szerver együttműködése egységes World-rendszerben, úgy, hogy minden Agent, memória és szolgáltatás tulajdonosa egyértelmű maradjon.

**Szükséges komponensek:**

- `Node`/gépmodell stabil azonosítóval, képességekkel és állapottal;
- szolgáltatásfelderítés vagy statikus helyi node-jegyzék;
- LAN + privát Tailscale útvonalak, nyilvános publikálás nélkül;
- hitelesítés, titkosítás és node-onkénti jogosultság;
- health check, timeout, circuit breaker és feladatátirányítás;
- modell- és Agent-elhelyezési jegyzék;
- Sentinelhez illeszthető felügyelet, naplózás és helyreállítás;
- mentési és konfliktuskezelési stratégia; alapértelmezetten nincs automatikus közös memória.

**Függőségek:** Az összes korábbi fázis stabil interfészei; ellenőrzött Mac és ASUS infrastruktúra; Tailscale/LAN elérés; helyi biztonsági modell.

**Várható nehézség:** Nagyon magas, rendszerintegrációs szintű.

**Kockázatok:** Hálózati kiesés és részleges válasz; eltérő modellverziók; node-azonosítási hiba; jogosulatlan hozzáférés; adatkonfliktus; egy gép hibájának tovaterjedése; nem ellenőrzött automatikus failover.

**Mikor érdemes elkezdeni:** Tervezése korán elkezdhető az interfészek miatt, éles megvalósítása azonban csak a Phase 1–7 stabil, naplózott és helyreállítható állapota után. Első mérföldkő: Mac–ASUS health check és kézi node-választás; automatikus ütemezés csak később.

**Mi van már kész:** Az `Agent` jelenleg megkülönbözteti a Mac és ASUS szervert, a `ChatCoordinator` ezek alapján választ hostot, az Ollama-kliens pedig paraméterként kapott helyi hosthoz kapcsolódik.

**Mi hiányzik még:** Nincs általános Node-modell, gépazonosítás, képességjegyzék, hitelesítés, health check, Tailscale-kezelés, circuit breaker, feladatátirányítás vagy többgépes felügyelet.

**Konkrét következő mérföldkő:** Létrehozni egy írásmentes Mac–ASUS állapotellenőrzési tervet és Node-adatmodellt, majd kézi hostválasztással igazolni, hogy a két gép hibája egymástól elkülöníthető.

**A következő fázis lezárásának és későbbi kliensmunka elkezdésének feltételei:** Minden node hitelesített, azonosítható és izolálható; hálózati kiesés nem okoz adatvesztést; az Agent–modell–node tulajdonjog egyértelmű; nincs nyilvános szolgáltatás; a mobil vagy internetes kliens kizárólag külön biztonsági felülvizsgálat után kapcsolódhat.

**Visszamaradható technikai adósság:** Kezdetben maradhat statikus node-jegyzék, kézi feladatkiosztás és aktív-passzív működés. Nem maradhat hitelesítés nélküli Ollama-port, automatikus konfliktusfeloldás vagy ellenőrizetlen failover.

**Továbblépés előtti tesztek:** Mac és ASUS health check; node-kiesés és visszatérés; timeout/circuit breaker; hibás hitelesítés; Tailscale- és LAN-útvonal; modellhiány; részleges válasz; naplókorreláció; mentés-visszaállítás; hálózati leválasztás; terhelési és biztonsági teszt.

---

## Ajánlott sorrend és fáziskapuk

1. **Phase 1 → 2:** csak stabil egyszereplős modellút és tesztelt hibakezelés után.
2. **Phase 2 → 3:** csak stabil üzenet- és beszélgetésazonosítók után.
3. **Phase 3 → 4:** csak lezárt World/helyszín kapcsolatok és mentés után.
4. **Phase 4 → 5–6:** csak elkülönített Agent-memória, audit és helyreállítás után.
5. **Phase 6 → 7:** csak jóváhagyott, korlátozott és naplózott tool-végrehajtás után.
6. **Phase 7 → 8:** csak stabil szolgáltatási protokollok és node-onként meghatározott tulajdonjog után.

A hang részben párhuzamosítható a memória késői munkáival, de a programvezérlés, médiaautomatizálás és többgépes működés nem kerülhet a biztonsági, naplózási és visszaállítási alapok elé.

## 12 hónapos végrehajtási terv

Az ütemezés egy kis fejlesztői csapatra és kapuvezérelt átadásra készült. A hónapok irányadó időablakok: egy fázis csak a saját kilépési tesztjei és a következő fázis belépési feltételei után tekinthető lezártnak.

### 1. hónap – Alaprendszer-felmérés és egységesítés

- A közvetlen és szolgáltatási Ollama-hívások feltérképezése.
- Az egyszereplős chat átvezetése az `AgentModelService` rétegre.
- Agent–modell–host regressziós tesztek és helyi hibadiagnosztika.
- Mérföldkő: Phase 1 szolgáltatási út stabil, a régi szereplők működése változatlan.

### 2–3. hónap – Több szereplős chat alapja

- Beszélgetés- és üzenetmodell, résztvevőválasztás, közös előzmény.
- `ChatCoordinator` integráció és külön válaszállapotok.
- Első közös chat UI, kezdetben soros válaszokkal.
- Mérföldkő: kiválasztott Agentek stabil közös beszélgetése részleges hibatűréssel.

### 4. hónap – World, City és Village domain lezárása

- World-identitás és beszélgetéskapcsolatok meghatározása.
- Döntés és ADR a jelenlegi testvér City/Village modell és a célként kért World → City → Village hierarchia között.
- Teszt- és éles konfiguráció elkülönítése, migrációs terv.
- Mérföldkő: verziózott, tesztelt domainmodell, amely nem igényli a koordinátor átírását.

### 5–6. hónap – Helyi memória

- Agentenként elkülönített üzenetnapló és adatbázisséma.
- Mentés, visszaállítás, törlés, export és migráció.
- Korlátozott kontextus-visszakeresés, automatikus hosszú távú memória nélkül.
- Mérföldkő: bizonyítható memóriaelszigetelés és visszaállítható helyi adattár.

### 7. hónap – Hang

- Magyar beszédkimeneti szolgáltatás és Agent-hangprofilok.
- Lejátszási sor, megszakítás, némítás és engedélykezelés.
- Beszédfelismerési technológiai próba külön kísérleti ágon.
- Mérföldkő: stabil, kikapcsolható és több Agenttel sorrendtartó beszédkimenet.

### 8–9. hónap – Biztonságos Mac-programvezérlés

- Tool-protokoll, engedélylista, jóváhagyási folyamat és auditnapló.
- Alkalmazásindítás, majd csak olvasási diagnosztika.
- Liliom és Sentinel tényleges integrációja csak külön, ellenőrzött Agent- és jogosultsági specifikáció után.
- Mérföldkő: korlátozott, jóváhagyott és naplózott Mac-műveletek tetszőleges parancsvégrehajtás nélkül.

### 10. hónap – Multimédia alap

- Csak olvasási helyi médiaimport, metaadatok és előnézet.
- Nem destruktív képelemzési/exportálási próba.
- Videós és DaVinci-integrációs kockázati prototípus éles automatizálás nélkül.
- Mérföldkő: eredeti fájlt megőrző, megszakítható médiafolyamat.

### 11. hónap – Mac + ASUS node-réteg

- Node-modell, képességjegyzék, health check és kézi feladatkiosztás.
- LAN + privát Tailscale kapcsolat, hitelesítés és kieséskezelés.
- ASUS külön világ/kutatóközpont szerepének dokumentált adat- és Agent-határai.
- Mérföldkő: a Mac és ASUS hibája elkülöníthető, a szolgáltatások kézzel irányíthatók.

### 12. hónap – Stabilizálás és kliens-előkészítés

- Teljes regressziós, helyreállítási, terhelési és biztonsági teszt.
- Későbbi helyi szerverekhez verziózott node-regisztrációs szerződés.
- Mobil klienshez platformfüggetlen domain- és szolgáltatási interfészek kijelölése.
- Internetes klienshez fenyegetésmodell és hozzáférési terv készítése; nyilvános telepítés még nem része ennek a roadmapnek.
- Mérföldkő: dokumentált 1.0 architektúra, stabil helyi többgépes mag és jóváhagyott következő éves kliensstratégia.

## Internetes és mobil kliens – előkészítési irány

Az internetes és mobil támogatás keresztmetszeti képesség, nem engedély a Closed World nyilvános közzétételére. A 12 hónapos időszakban csak az alábbi előkészítés tervezett:

- platformfüggetlen azonosítók és adatátviteli objektumok;
- verziózott, hitelesített szolgáltatási szerződés;
- legkisebb jogosultságú hozzáférés és eszközpárosítás;
- végpontok közötti titkosítás és visszavonható hozzáférés;
- offline/gyenge hálózati állapot és konfliktuskezelés terve;
- külön threat model, adatvédelmi és biztonsági kapu minden internetes elérés előtt.

A mobil kliens kezdetben csak megjelenítő és jóváhagyó felület lehet. Memória, modell és érzékeny rendszervezérlés a helyi gépeken marad. Külső API, felhőmemória vagy nyilvános adatbázis csak új, kifejezett architekturális döntéssel kerülhetne szóba; ezek a jelenlegi Closed World tervnek nem részei.

## Összesített állapottábla

A százalékok 2026. július 31-i, ténylegesen megtalált projektállapotra alapozott konzervatív becslések, nem automatikus mérőszámok. Csak az számít kész résznek, ami forrásfájlban jelen van, a jelenlegi projekttel lefordul, vagy célzott teszttel ellenőrzött. Dokumentált terv, asset, nem integrált protokollváz, jövőbeli modell vagy feltételezett infrastruktúra nem növeli a százalékot. A teljes fáziscélhoz UI, perzisztencia, biztonság, integráció és tesztelés is hozzátartozik.

**Ellenőrzési alap:** Az iOS `TuskeAI` target kódaláírás nélkül sikeresen lefordult. A World-helyszínválasztás külön smoke tesztet kapott. A `ChatCoordinator` és a szolgáltatási réteg lefordul, de még nincs bekötve a közös chat UI-ba. A macOS programindítást, a tényleges többgépes hálózatot, a hang minőségét és Ollama összes modelljének futását ebben az ellenőrzési körben nem igazolta végponttól végpontig futó teszt; ezek ezért csak minimális rész-készültséget kapnak.

| Phase | Állapot | Készültség (%) | Következő lépés | Függőségek |
|--------|---------|----------------|-----------------|------------|
| Phase 1 – Alap rendszer | Részben működő, integráció hiányos | 45% | Az egyszereplős UI átvezetése az `AgentModelService` rétegre | Helyi Ollama, ellenőrzött modellek és hostok |
| Phase 2 – Több szereplős chat | Csak koordinációs alap | 20% | Beszélgetés- és üzenetmodell létrehozása | Phase 1 stabil szolgáltatási út |
| Phase 3 – Világok, Városok, Falvak | Tesztelt adatmodell-prototípus | 20% | World-identitás és célhierarchia lezárása | Phase 2 stabil üzenetazonosítók |
| Phase 4 – Memória | Nem található implementáció | 0% | Agentenkénti helyi üzenetnapló specifikációja | Phase 2–3 stabil azonosítók és mentés |
| Phase 5 – Hang | Minimális beszédkimeneti kód | 10% | Magyar hangszolgáltatás és Agent-hangprofil tervezése | Phase 2 válaszsorrend, platformengedélyek |
| Phase 6 – Programvezérlés (Mac) | Minimális alkalmazásindító kód | 10% | Engedélylistás tool-szerződés és jóváhagyási modell | Phase 4 audit, macOS jogosultságok |
| Phase 7 – Képek és videók | Nem található médiafunkció | 0% | Nem destruktív médiaimport-adatmodell | Phase 6 biztonságos tool-réteg |
| Phase 8 – Több gépből álló világ | Csak statikus hostválasztási alap | 5% | Node-modell és Mac–ASUS health check | Stabil Phase 1–7 interfészek, LAN/Tailscale |

## Állandó architektúra-szabályok

- Az Agentek identitása, promptja, memóriája és feladata külön marad.
- Meglévő modelleket nem nevezünk át, nem egyesítünk és nem helyettesítünk ellenőrzés nélkül.
- A koordinátorok szolgáltatási protokolloktól függnek, nem konkrét hálózati kliensektől.
- UI, domainmodell, tárolás, modellkapcsolat és operációsrendszer-vezérlés külön réteg.
- Egy Agent, modell vagy node hibája nem állíthatja le a többi résztvevőt.
- Minden külső hatású művelet korlátozott, ellenőrzött, naplózott és szükség esetén jóváhagyott.
- A Closed World adatai helyben maradnak; nincs felhőmemória, külső API, nyilvános adatbázis vagy automatikus feltöltés.
- Migráció előtt mentés és integritás-ellenőrzés szükséges.
- Tesztadat nem válhat automatikusan éles konfigurációvá.

## Ellenőrzött projektforrások

- `Architecture.md`
- `TuskeAI/Brain/Agent.swift`
- `TuskeAI/Brain/AgentModelService.swift`
- `TuskeAI/Brain/OllamaClient.swift`
- `TuskeAI/Brain/ChatCoordinator.swift`
- `TuskeAI/Brain/World.swift`
- `TuskeAI/Brain/ContentView.swift`
- `TuskeAI/Brain/VoiceManager.swift`
- `TuskeAI/Brain/AppLauncher.swift`
- `TuskeAI Mac/ContentView.swift`
