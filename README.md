# Garmin Face — Forerunner 955

Tarcza Connect IQ w Monkey C dla **Forerunnera 955 / Solar (`fr955`)**,
okrągły ekran MIP 260 × 260 px, minimum API 4.2.2.

## Wygląd i dane

- Godzina 24 h (`HH MM`) pośrodku, bez dwukropka, domyślnie z małymi sekundami po prawej.
- Na górze szare ikony alarmu i braku połączenia z telefonem, wyśrodkowane
  razem; pojedyncza aktywna ikona zajmuje środek.
- W dzień: wschód po lewej, zachód po prawej. W nocy: ostatni zachód po lewej,
  następny wschód po prawej, w formacie 24 h.
  Przy każdej godzinie jest zmiana w minutach względem tego samego zdarzenia
  poprzedniego dnia kalendarzowego, np. `16:16 -2` lub `06:25 +2`.
  Plus oznacza późniejszą godzinę, minus — wcześniejszą. Porównywane są lokalne
  godziny widoczne na tarczy, z uwzględnieniem zmiany czasu. Brak poprzedniego
  zdarzenia pozostawia samą godzinę. Wyniki korzystają z istniejącego bufora zdarzeń.
- Niżej wspólny wyśrodkowany wiersz: data i bieżąca pogoda, z odstępem 14 px.
  Data ma postać `Cz, 29 Paź`, zgodną z językiem zegarka; temperatura jest w °C.
- Trzy dolne pola, z wartościami nad ikonami, domyślnie: kroki, dzienne kilokalorie i stres.
- Dolny łuk pokazuje cel kroków, górny — postęp bieżącego dnia lub nocy.
  Oba zajmują 72° obwodu, mają grubość 4 px i przylegają do krawędzi.
  Górny łuk wypełnia się od lewego zdarzenia do prawego: w dzień od wschodu
  do zachodu, w nocy od zachodu do wschodu przez północ. O wschodzie i zachodzie
  zaczyna nowy odcinek od zera; o północy nie resetuje się.
- Drugi, wewnętrzny dolny łuk pokazuje tygodniowe aktywne minuty względem celu
  ustawionego w Garminie. Korzysta z gotowej sumy Garmina, w której intensywne
  minuty są liczone podwójnie. Ma ten sam kolor i długość 72°, promień 122 px
  i odstęp 2 px od łuku kroków. Analogowy sekundnik biegnie po ich wewnętrznej stronie.

Temperatura, data i dolne wartości mają wspólną pogrubioną czcionkę o wysokości 26 px.
Sekundy używają tej samej rodziny czcionki w rozmiarze 25 px.
Godzina słoneczna używa regularnej czcionki wektorowej o rozmiarze 21.
Układ i obszary dotyku są zapisane wspólnie w `source/FaceLayout.mc`.

Brak pomiaru jest oznaczany `--` lub `--:--`. Stres jest prawidłowy w zakresie
0–100. Kalorie to dzienna suma Garmina, obejmująca spoczynkowe i aktywne.
Brakujący lub zerowy cel kroków lub aktywnych minut pozostawia pusty łuk; przekroczenie celu
wypełnia go maksymalnie do 100%.

## Dostosowanie na zegarku

Przytrzymaj **UP/MENU → Tarcza zegarka → Garmin Face → START → Dostosuj**.

Dla **Lewego pola**, **Środkowego pola** i **Prawego pola** dostępne są:
**Kroki**, **Kalorie**, **Stres**, **Tętno**, **Bateria**, **Dystans (km)**
i **Pokonane piętra** oraz **Brak**. Pola są niezależne i mogą powtarzać tę samą wartość.
**Brak** ukrywa dane pole razem z ikoną. Pozostałe pola zachowują kolejność
i automatycznie się wyśrodkowują: trzy, dwa lub jedno. Można ukryć wszystkie pola.
Obszary przytrzymania przesuwają się razem z polami i nadal prowadzą do właściwych danych.
Dystans jest dzienny, w kilometrach z jednym miejscem po przecinku.
Zewnętrzny dolny łuk zawsze pokazuje cel kroków, wewnętrzny — cel aktywnych minut.

**Kolor akcentu** wybiera wspólny pastelowy kolor dużej godziny i wypełnień wszystkich
łuków: biały, szary, czerwony, pomarańczowy, żółty, zielony, niebieski, fioletowy
lub różowy. Sekundy i pozostałe dane pozostają szare.

**Dostosuj → Jasne tło** przełącza tło na białe, a dane i ikony na ciemnoszare.
Akcent zachowuje wybrany kolor w ciemniejszym odcieniu dla czytelności;
biały akcent staje się czarny. Powrót do ciemnego tła przywraca pastelowy odcień.
Ustawienie jest zapamiętywane, działa w obu widokach i domyślnie jest wyłączone.

START zapisuje wybór, BACK wraca bez zmiany. Ustawienia są przechowywane przez
`Application.Storage`. Zachowano zgodność z wcześniejszymi kluczami ustawień;
stary osobny kolor godziny jest przejmowany jako akcent, jeśli akcentu jeszcze
nie zapisano. Nieprawidłowy zapis przywraca wartość domyślną.

**Dostosuj → Prosty widok** ukrywa wszystkie łuki oraz godziny
wschodu i zachodu słońca. Znikają całe łuki, razem z ciemnoszarymi torami.
Nie zmienia liczby dolnych pól ani ich położenia; o ich widoczności decyduje wyłącznie **Brak**.
W obu widokach data z pogodą i dolne wartości mają symetryczny odstęp od godziny:
52 px nad jej środkiem i 52 px pod nim. Obszary przytrzymania odpowiadają położeniu pól.
Wybór jest zapamiętywany; domyślnie prosty widok jest wyłączony.

**Dostosuj → Analogowy sekundnik** zastępuje cyfrowe sekundy kropką o promieniu
3 px, w kolorze akcentu. Jej środek porusza się w odległości 116 px od środka
tarczy, z odstępem od górnego i dolnego łuku. Przesuwa się co sekundę
zgodnie z ruchem wskazówek: 0 u góry, 15 po prawej, 30 na dole, 45 po lewej.
Godzina bez cyfrowych sekund jest wyśrodkowana. Sekundnik działa niezależnie od
**Prostego widoku**; zmiana jednej opcji nie przełącza drugiej. Jest rysowany na
wierzchu, po wewnętrznej stronie łuków. Ustawienia są zapamiętywane.

Oba rodzaje sekundnika są widoczne tylko po wybudzeniu tarczy, np. gestem
nadgarstka. W spoczynku sekundy znikają, a godzina pozostaje w tym samym miejscu.
Po ponownym wybudzeniu sekundnik wraca z aktualną sekundą.

Przytrzymanie ikony lub liczby dolnego pola wywołuje natywny widok Garmina przez
`WatchFaceDelegate.onPress()` i `Complications.exitTo()`. Skrót uwzględnia wybraną
wartość. Dzienny dystans otwiera widok kroków, ponieważ API nie udostępnia osobnego
skrótu do dziennego dystansu. Dotyk na zegarku musi być włączony.
Otwieranie natywnych ekranów wymaga jeszcze potwierdzenia na fizycznym FR955:
w lokalnych próbach symulator nie przekazywał gestu przytrzymania do tarczy.

## Źródła danych i odświeżanie

Pogoda pochodzi z `Weather.getCurrentConditions()` i wymaga aktualnych danych
Garmin Connect. Bez danych widoczna jest temperatura `--°` i kreska zamiast ikony.
Wschód i zachód są obliczane przez `Weather.getSunrise()` i `Weather.getSunset()`
dla konkretnych dat i ostatniej dostępnej pozycji. Zdarzenia mają pełne znaczniki
czasu: po zachodzie pasek łączy dzisiejszy zachód z jutrzejszym wschodem;
przed wschodem — wczorajszy zachód z dzisiejszym wschodem. Długość nocy wynika
z różnicy tych znaczników, także podczas zmiany czasu i przejścia roku.

Tarcza odczytuje istniejącą pozycję przez `Position.getInfo()`, a gdy jej brak,
korzysta z pozycji zapisanej w danych pogody lub ostatniej poprawnej pozycji
zachowanej lokalnie. Wymagane jest uprawnienie `Positioning`. GPS i zdarzenia
lokalizacyjne nie są uruchamiane; współrzędne nie są wysyłane. Bez pozycji lub
pełnego przedziału zdarzeń wyświetlane jest `--:--` i pusty łuk.
Tętno pochodzi z natywnego pola zegarka, bez osobnej sesji czujnika;
pozostaje uprawnienie `ComplicationSubscriber`.

Ikona alarmu zależy od `alarmCount > 0`, a braku połączenia od `!phoneConnected`.
Licznik powiadomień nie jest wyświetlany.

`onUpdate()` rysuje pełną tarczę: raz na minutę w trybie oszczędnym i co sekundę
przez krótki czas po wybudzeniu. `onEnterSleep()` ukrywa sekundnik i zleca
odrysowanie ekranu z bufora, aby usunąć ostatnią cyfrę lub kropkę.
`onExitSleep()` przywraca sekundnik. Tarcza nie implementuje `onPartialUpdate()`:
w spoczynku nie wykonuje własnego kodu rysowania co sekundę.
Nie ma timerów ani usług w tle.

Kod przechowuje wynik pomiaru godziny do zmiany minuty, datę do zmiany dnia lub
języka, szerokości tekstów do ich zmiany oraz ostatnie napisy wschodu i zachodu.
Gotowy ekran bez sekundnika jest buforowany i składany ponownie dopiero po zmianie
wyświetlanych danych, ustawień, statusu, minuty lub stopnia wypełnienia łuku.
Każde `onUpdate()` nadal odtwarza cały ekran, również po powiadomieniach i menu.
Ikony Garmina są ładowane dopiero przy pierwszym użyciu. Aktualne pomiary i stan
połączenia nadal są sprawdzane przy pełnym odświeżeniu; powtarzane pola współdzielą odczyt.
Pogoda i dostępna zapisana pozycja są sprawdzane raz na minutę oraz po powrocie
do tarczy. Zdarzenia słoneczne są buforowane dla okolicznych dat i obliczane
ponownie po zmianie lokalnego dnia lub pozycji (z dokładnością ok. 0,001°).
Ukryte wszystkie pola w prostym widoku nie powodują odczytu aktywności.

Cyfry sekund są rasteryzowane raz po zmianie tła. Kropka korzysta z gotowych
współrzędnych. Przygotowanie sekundnika i jego rysowanie są pomijane w spoczynku.
Raport porównawczy i zakres pomiarów: [docs/power-audit.md](docs/power-audit.md).

## Uruchomienie projektu

1. Zainstaluj [Connect IQ SDK Manager](https://developer.garmin.com/connect-iq/sdk/),
   SDK oraz profil **Forerunner 955 / Solar**. Ustaw SDK jako aktywne.
2. W VS Code zainstaluj **Monkey C** od Garmina (`garmin.monkey-c`), otwórz cały
   folder projektu i uruchom **Monkey C: Verify Installation**. Potrzebna jest Java.
3. Skonfiguruj **Monkey C: Developer Key Path**. Na tym Macu istniejący klucz jest
   w `.keys/developer_key.der`, a lokalne ustawienie w `.vscode/settings.json`.
4. Uruchom F5, wybierając `fr955`, albo zbuduj tarczę poleceniem poniżej.

Po przeniesieniu projektu odtwórz istniejący klucz z kopii. Dla nowego projektu
można użyć `bash scripts/generate-key.sh`; skrypt nie nadpisuje istniejącego klucza.
Klucze i lokalne ustawienia są wyłączone z Gita. Zachowaj prywatną kopię klucza.

## Budowanie i testy

```sh
bash scripts/build.sh -w -l 1
```

Wynik: `bin/GarminFace.prg`. W VS Code to samo zadanie uruchamia **Cmd+Shift+B**.
Dla wersji release dodaj `-r`. Skrypt wykrywa aktywne SDK lub `monkeyc` z PATH.
Ścieżki można nadpisać zmiennymi `CIQ_SDK_HOME` i `CIQ_DEVELOPER_KEY`.
Domyślnie stosowana jest optymalizacja wydajności `-O 3p`; można ją zmienić przez
`CIQ_OPTIMIZATION` (np. `CIQ_OPTIMIZATION=0 bash scripts/build.sh`).

```sh
bash scripts/build.sh --tests -w -l 1
```

Wynik: `bin/GarminFaceTests.prg`, bez nadpisywania pliku na zegarek.
Testy można uruchomić w VS Code przez **Monkey C: Run Tests** albo po uruchomieniu
symulatora narzędziem SDK: `monkeydo bin/GarminFaceTests.prg fr955 -t`.
Folder `tests/` jest uwzględniany przez Jungle; oznaczenie `(:test)` wyklucza
zarówno testy, jak i ich pomocniczy moduł z normalnej kompilacji.

W symulatorze:

- **Settings → Trigger App Settings** otwiera „Dostosuj”.
- **Settings → Set Position** ustawia pozycję dla godzin słonecznych;
  dla Warszawy użyj `52.2297, 21.0122` zamiast domyślnej pozycji w USA.
- **Settings → Set Weather** ustawia pogodę testową.
- **Simulation → Activity Monitoring → Set Activity Monitor Info** zmienia kroki i cel.
- **Settings → Connection Type → BLE** zmienia stan połączenia z telefonem.

## Wgranie na FR955

1. Podłącz zegarek kablem USB obsługującym dane.
2. Wgraj `bin/GarminFace.prg` do `GARMIN/Apps` przez `libmtp`, zgodnie z procedurą poniżej.
3. Odłącz zegarek i wybierz **Garmin Face** w menu tarcz.

Na macOS FR955 korzysta z MTP. Do wykrywania zegarka, odczytu folderów i transferu
używaj wyłącznie `libmtp` z terminala lub bezpośrednio przez API biblioteki.
Nie używaj OpenMTP ani aplikacji graficznych do deployu. Publikacja w sklepie
nie jest potrzebna do testów na własnym zegarku.

### Procedura deployu

Gdy użytkownik prosi o **deploy**, wykonaj całą procedurę:

1. Sprawdź stan repozytorium i zakres zmian przeznaczonych do wdrożenia.
   Zachowaj niezwiązane zmiany i nie dodawaj ich do commita.
2. Podbij `version` aplikacji w `manifest.xml`. Domyślnie zwiększ numer patch
   (np. `0.1.0` → `0.1.1`), chyba że użytkownik wskazał konkretną wersję.
3. Zbuduj wersję release dla `fr955`: `bash scripts/build.sh -r -w -l 1`.
   Wykonaj odpowiednie sprawdzenia; przy błędzie przerwij deploy.
4. Zrób commit zmian wdrożenia wraz z podbitą wersją, np.
   `Release 0.1.1`. Deploy sam w sobie nie obejmuje pushowania ani tworzenia taga.
5. Wgraj na podłączony zegarek **plik `.prg` wskazany przez użytkownika**.
   Jeśli nie wskazano innego pliku, użyj świeżo zbudowanego `bin/GarminFace.prg`.
   Nie wgrywaj `bin/GarminFaceTests.prg`. Przed transferem sprawdź, czy plik istnieje
   i czy jest przeznaczony dla FR955.
6. Pobierz wgrany plik kontrolnie przez `libmtp` i porównaj SHA-256 z lokalnym
   plikiem release. Podaj wersję, hash commita, wgrany plik i wynik porównania.
   Nie zgłaszaj udanego deployu, jeśli transfer się nie powiódł; działanie tarczy
   na fizycznym zegarku wymaga osobnego potwierdzenia.

Na tym Macu zainstalowane jest `libmtp` (`brew install libmtp`). Połączenie USB
musi być wolne od innych klientów MTP, np. Garmin Express. Nie uruchamiaj
aplikacji graficznej, aby wykryć zegarek lub przesłać plik.
Wykrycie urządzenia i listę folderów sprawdź w terminalu:

```sh
mtp-detect
mtp-folders
```

Transfer sprawdzony na fizycznym FR955 Solar podczas deployu `0.1.3`:

1. Otwórz właściwe urządzenie przez `LIBMTP_Open_Raw_Device_Uncached`.
   Odczytaj bieżący identyfikator pamięci oraz folderu `Apps` wewnątrz `GARMIN`;
   nie zapisuj identyfikatorów na stałe. `LIBMTP_Get_Files_And_Folders` wymaga
   urządzenia otwartego w tym trybie.
2. Wywołaj `LIBMTP_Send_File_From_File` dla wybranego pliku `.prg`.
   W metadanych ustaw nazwę docelową (domyślnie `GarminFace.prg`), rozmiar pliku,
   `storage_id` odczytanej pamięci i `parent_id` folderu `Apps`.
3. Sprawdź wynik funkcji i zachowaj zwrócony `item_id`. Następnie pobierz ten
   obiekt przez `LIBMTP_Get_File_To_File` i porównaj SHA-256 obu plików.
4. Zwolnij połączenie przez `LIBMTP_Release_Device`. Odłącz zegarek i sprawdź tarczę.

Nie polegaj na samym kodzie wyjścia `mtp-sendfile`: podczas tego deployu polecenie
ze ścieżką `/GARMIN/Apps/GarminFace.prg` zwróciło kod `0`, ale komunikat
`Parent folder could not be found, skipping` oznaczał brak transferu.
Bezpośredni transfer przez API z identyfikatorem folderu oraz kontrolny odczyt
zakończyły się powodzeniem i zgodnymi sumami SHA-256.

## Kod projektu

| Plik | Odpowiedzialność |
| --- | --- |
| `source/GarminFaceApp.mc` | Start tarczy i wejście do dostosowania |
| `source/GarminFaceView.mc` | Składanie ekranu, godzina, sekundy i dolne pola |
| `source/FaceLayout.mc` | Współrzędne pól, wierszy i obszarów dotyku |
| `source/FaceFonts.mc` | Pogrubiona czcionka danych i regularne sekundy |
| `source/AnalogSeconds.mc` | Wskaźnik sekund przy krawędzi i odświeżanie jego pozycji |
| `source/DigitalSeconds.mc` | Bufor cyfr sekund i ich częściowe odświeżanie |
| `source/ProgressArc.mc` | Wspólne rysowanie i ograniczanie wypełnienia łuków |
| `source/SunArc.mc` | Wschód, zachód i postęp dnia/nocy |
| `source/SolarTimes.mc` | Datowane zdarzenia słoneczne i dokładny przedział dnia/nocy |
| `source/SolarPosition.mc` | Odczyt i lokalne zachowanie istniejącej pozycji bez uruchamiania GPS |
| `source/WeatherRow.mc` | Wyśrodkowany wiersz daty i pogody |
| `source/MetricFields.mc` | Odczyt danych, formatowanie i zapis wyborów |
| `source/MetricNavigation.mc` | Przytrzymanie pól i natywne skróty |
| `source/SettingsMenu.mc` | Menu danych i koloru akcentu |
| `source/FaceColors.mc` | Kolory obu teł i zapis akcentu |
| `source/FaceOptions.mc` | Zapamiętane przełączniki prostego widoku i jasnego tła |
| `source/DataIcons.mc` | Ikony danych i statusu |
| `tests/` | Testy słońca, łuków, ustawień, jednostek i obszarów dotyku |

Wszystkie siedem ikon dolnych pól pochodzi z Garmin Support. Źródła oraz sposób
przygotowania SVG są opisane w `resources/drawables/garmin/SOURCES.md`.
W baterii wykorzystano sam piktogram, bez przykładowego procentu z ilustracji.
Dystans używa gotowego symbolu biegnącej postaci; odczyt pozostaje dzienny.
Ikony statusu i pogody są rysunkami wektorowymi.

Po refaktoryzacji 2026-10-29: czysta kompilacja SDK 9.3.0 z `-w -l 1` i wszystkie
30 testów przeszło. W symulatorze sprawdzono zachowanie wyglądu, odświeżanie
sekund i minut, zmianę języka polski/angielski, wybór trzech pól i akcentu oraz
ładowanie oryginalnych ikon, przełączanie prostego widoku i jego zapis po restarcie,
opcję „Brak” oraz wyśrodkowanie jednego i dwóch pól w obu widokach, a także ukrycie wszystkich pól.
Sprawdzono również jasne tło w obu widokach, ciemne ikony i zapis ustawienia po restarcie.
Analogowy sekundnik sprawdzono na obu tłach, wraz z niezależnym przełączaniem prostego
widoku, powrotem cyfr sekund i zapisem opcji. Kropka omija oba łuki we wszystkich
60 pozycjach; częściowe odświeżanie usuwa jej poprzednią pozycję.
Potwierdzono brak funkcji pomocniczych testów
w normalnym pliku na zegarek.

Kompilacja i symulator nie zastępują sprawdzenia czytelności, skrótów dotykowych
i zużycia baterii na fizycznym zegarku.
