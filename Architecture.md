# TüskeAI architektúra

Ez a dokumentum a projekt jelenlegi, fájlokból ellenőrzött állapotát írja le. Nem definiál új éles konfigurációt, és nem változtatja meg a futó rendszert.

## 1. World

A `World` a helyszínek felső szintű tárolója. Egy `World`:

- `WorldLocation` elemek listáját tartalmazza;
- egy opcionális `selectedLocationID` értékkel nyilvántartja a kiválasztott helyszínt;
- csak létező helyszínt enged kiválasztani;
- nem enged azonos azonosítójú helyszínt hozzáadni;
- a `selectedLocationAgents` tulajdonságon keresztül kizárólag a kiválasztott helyszín Agentjeit adja vissza.

A jelenlegi `World` típusnak nincs saját neve vagy azonosítója. Több World létrehozható több, egymástól független `World` példányként, de ezek nyilvántartására még nincs külön tároló vagy szolgáltatás.

## 2. City és Village

A `City` és a `Village` két külön helyszíntípus. Mindkettő megfelel az `AgentCommunity` protokollnak, ezért rendelkezik:

- egyedi `String` azonosítóval;
- névvel;
- rövid leírással;
- önálló `[Agent]` listával.

A `WorldLocation` enum típusbiztosan fogja össze a két változatot (`city` és `village`), miközben egységes hozzáférést biztosít az azonosítóhoz, névhez, leíráshoz és Agent-listához. A City és Village jelenleg szerkezetileg azonos, de a külön típus megőrzi a helyszínek jelentését és lehetővé teszi későbbi, eltérő bővítésüket.

## 3. Agentek

Az `Agent` egy önálló szereplő konfigurációja. Minden Agenthez a kód jelenleg az alábbiakat rendeli:

- stabil azonosító és megjelenített név;
- futtató szerver (`mac` vagy `asus`);
- Ollama-modellnév;
- képnév és SwiftUI-szín;
- saját szerep- vagy alkalmazásprompt (`role`).

A jelenlegi Agentek: Csajos, Oli, Töki, Kai, Suna és Marci. Liliom a jelenlegi éles `Agent` enumban még nem szerepel. Egy helyszín Agent-listája meglévő Agent-értékekre hivatkozik; ettől az Agentek identitása és modellkonfigurációja nem olvad össze a helyszínnel.

## 4. ChatCoordinator

A `ChatCoordinator` egy megkapott Agent-listát sorrendben dolgoz fel. Agentenként:

1. elkészíti az `AgentModelRequest` objektumot;
2. kiválasztja a megfelelő Mac- vagy ASUS-hostot;
3. meghívja az `AgentModelService` szolgáltatást;
4. külön `AgentResponse` objektumot hoz létre.

Az `AgentResponse` tárolja a válaszoló Agentet, az időpontot, a sikerességet, az állapotot, a választ vagy hibát, valamint a futási időt. Egy Agent hibája vagy időtúllépése külön eredménnyé válik, és a következő Agent feldolgozása folytatódik.

A `WorldChatCoordinator` a World és a változatlan `ChatCoordinator` közötti összekötő réteg: a `world.selectedLocationAgents` listát adja át a koordinátornak. Ha nincs kiválasztott helyszín, üres lista kerül továbbításra.

## 5. AgentModelService

Az `AgentModelService` a modellhívás absztrakciója. Egyetlen aszinkron műveletet ír elő:

```swift
func generate(request: AgentModelRequest) async throws -> String
```

Az `AgentModelRequest` tartalmazza az Agentet, a teljes promptot, a hostot és az időkorlátot. Emiatt a `ChatCoordinator` nem függ közvetlenül az Ollama HTTP-megvalósításától; más helyi modellszolgáltatás vagy tesztimplementáció ugyanazon protokoll mögé illeszthető.

## 6. OllamaClient

Az `OllamaClient` az `AgentModelService` jelenlegi helyi implementációja. HTTP `POST` kérést küld a kiválasztott host `11434` portján az `/api/generate` végpontra. A kérés az Agent `modelName` értékét, a promptot, az időkorlátot és a generálási beállításokat használja.

A kliens ellenőrzi a hostot, a HTTP-választ, a státuszkódot és a válaszszöveget. A hibákat `OllamaClientError` vagy hálózati hiba formájában továbbadja a `ChatCoordinator` részére. A jelenlegi megvalósítás helyi HTTP-kapcsolatot használ; külső API-t vagy felhőmemóriát nem tartalmaz.

## 7. Az adatok útja

```text
Felhasználó
  → World
  → kiválasztott WorldLocation (City vagy Village)
  → a helyszín Agent-listája
  → WorldChatCoordinator
  → ChatCoordinator
  → AgentModelService
  → OllamaClient
  → az Agenthez rendelt helyi Ollama-modell
  → szöveges modellválasz vagy hiba
  → AgentResponse
  → ChatCoordinator eredménylistája
  → UI
```

Megjegyzés: a jelenlegi UI még nincs összekötve a `WorldChatCoordinator` réteggel. A fenti út az elkészített architektúra célzott végpontját is jelöli; a ténylegesen implementált World-adatút a `WorldChatCoordinator` bemenetétől az `AgentResponse` listáig tart.

## 8. Bővítési szabályok

### Új World létrehozása

Hozz létre egy új, önálló `World` példányt a hozzá tartozó `WorldLocation` listával és opcionális kiválasztott helyszínazonosítóval. A helyszínazonosítóknak az adott Worldön belül egyedinek kell lenniük. Éles alapkonfigurációhoz külön konfigurációs vagy adattárolási réteg szükséges; ilyen jelenleg nincs a projektben.

### Új City hozzáadása

1. Hozz létre egy `City` értéket egyedi azonosítóval, névvel, leírással és Agent-listával.
2. Csomagold `WorldLocation.city(...)` értékbe.
3. Add a Worldhöz az `addLocation` metódussal.
4. Kezeld a `false` eredményt, amely azonosítóütközést jelez.

### Új Village hozzáadása

1. Hozz létre egy `Village` értéket egyedi azonosítóval, névvel, leírással és Agent-listával.
2. Csomagold `WorldLocation.village(...)` értékbe.
3. Add a Worldhöz az `addLocation` metódussal.
4. Kezeld az esetleges azonosítóütközést.

### Új Agent hozzáadása

1. Adj új, külön esetet az `Agent` enumhoz; meglévő Agentet ne nevezz át és ne vonj össze vele.
2. Rendeld hozzá a saját szerverét, pontos helyi modellnevét, képnevét, színét és saját promptját.
3. Biztosítsd a szükséges képi erőforrást, ha az UI megjeleníti.
4. Csak ezután hivatkozz rá City vagy Village Agent-listájában.
5. Ellenőrizd külön a modell helyi elérhetőségét és az Agent identitásának sértetlenségét.

Új Agent adatainál tilos nem ellenőrzött modellnevet vagy szerver-hozzárendelést feltételezni.

## 9. Alapelvek

- **Single Responsibility:** a World helyszíneket választ, a ChatCoordinator válaszokat koordinál, az OllamaClient HTTP-modellhívást végez.
- **Dependency Inversion:** a ChatCoordinator az `AgentModelService` protokolltól függ, nem közvetlenül az OllamaClienttől.
- **Modularitás:** a helyszínmodell, a koordináció, a szolgáltatási protokoll és az Ollama-kliens külön típusokban és fájlokban található.
- **Bővíthetőség:** új City és Village példányok a koordinátor átírása nélkül hozzáadhatók; új modellszolgáltatás a protokoll implementálásával illeszthető be.
- **Típusbiztonság:** a `WorldLocation` enum csak támogatott helyszíntípust enged.
- **Identitásmegőrzés:** minden Agent külön eset, külön konfigurációval és prompttal; az Agentek nem egyesíthetők.
- **Hibatűrés:** egy Agent hibája vagy időtúllépése nem állítja le a további Agentek feldolgozását.
- **Sorrendtartás:** a válaszok az átadott Agent-lista sorrendjében készülnek el.
- **Egyedi helyszínek:** a World visszautasítja a már létező helyszínazonosító hozzáadását.
- **Visszafelé kompatibilitás:** a World-réteg a meglévő ChatCoordinator fölött helyezkedik el, ezért az egy-Agentes és közvetlen több-Agentes hívás továbbra is használható.
- **Closed World:** a dokumentált modellkapcsolat helyi Ollama-hostokat használ; nem vezet be felhős tárolást, külső API-t vagy automatikus feltöltést.

## Ellenőrzött forrásfájlok

- `TuskeAI/Brain/World.swift`
- `TuskeAI/Brain/Agent.swift`
- `TuskeAI/Brain/ChatCoordinator.swift`
- `TuskeAI/Brain/AgentModelService.swift`
- `TuskeAI/Brain/OllamaClient.swift`
