# Garmin Face — Forerunner 955

Tarcza Connect IQ w Monkey C dla **Forerunnera 955 / Solar (`fr955`)**,
okrągły ekran MIP 260 × 260 px, minimum API 4.2.2.

## Wygląd i dane

- Godzina 24 h (`HH:MM`) pośrodku, z małymi sekundami po prawej.
- Na górze szare ikony alarmu i braku połączenia z telefonem, wyśrodkowane
  razem; pojedyncza aktywna ikona zajmuje środek.
- Wschód słońca po lewej, zachód po prawej, w formacie 24 h.
- Niżej wspólny wyśrodkowany wiersz: data i bieżąca pogoda, z odstępem 14 px.
  Data ma postać `Cz, Paź 29`, zgodną z językiem zegarka; temperatura jest w °C.
- Trzy dolne pola z ikonami, domyślnie: kroki, dzienne kilokalorie i stres.
- Dolny łuk pokazuje cel kroków, górny — postęp bieżącego dnia lub nocy.
  Oba zajmują 72° obwodu, mają grubość 4 px i przylegają do krawędzi.

Temperatura, data, sekundy i dolne wartości mają wspólną regularną czcionkę
o wysokości 25 px — o 1 px większą od standardowej `FONT_GLANCE` na FR955.
Godzina słoneczna używa regularnej czcionki wektorowej o rozmiarze 21.
Układ i obszary dotyku są zapisane wspólnie w `source/FaceLayout.mc`.

Brak pomiaru jest oznaczany `--` lub `--:--`. Stres jest prawidłowy w zakresie
0–100. Kalorie to dzienna suma Garmina, obejmująca spoczynkowe i aktywne.
Brakujący lub zerowy cel kroków pozostawia pusty łuk; przekroczenie celu
wypełnia go maksymalnie do 100%.

## Dostosowanie na zegarku

Przytrzymaj **UP/MENU → Tarcza zegarka → Garmin Face → START → Dostosuj**.

Dla **Lewego pola**, **Środkowego pola** i **Prawego pola** dostępne są:
**Kroki**, **Kalorie**, **Stres**, **Tętno**, **Bateria**, **Dystans (km)**
i **Pokonane piętra**. Pola są niezależne i mogą powtarzać tę samą wartość.
Dystans jest dzienny, w kilometrach z jednym miejscem po przecinku.
Dolny łuk zawsze pokazuje cel kroków.

**Kolor akcentu** wybiera wspólny pastelowy kolor dużej godziny i wypełnień obu
łuków: biały, szary, czerwony, pomarańczowy, żółty, zielony, niebieski, fioletowy
lub różowy. Sekundy i pozostałe dane pozostają szare.

START zapisuje wybór, BACK wraca bez zmiany. Ustawienia są przechowywane przez
`Application.Storage`. Zachowano zgodność z wcześniejszymi kluczami ustawień;
stary osobny kolor godziny jest przejmowany jako akcent, jeśli akcentu jeszcze
nie zapisano. Nieprawidłowy zapis przywraca wartość domyślną.

Przytrzymanie ikony lub liczby dolnego pola wywołuje natywny widok Garmina przez
`WatchFaceDelegate.onPress()` i `Complications.exitTo()`. Skrót uwzględnia wybraną
wartość. Dzienny dystans otwiera widok kroków, ponieważ API nie udostępnia osobnego
skrótu do dziennego dystansu. Dotyk na zegarku musi być włączony.
Otwieranie natywnych ekranów wymaga jeszcze potwierdzenia na fizycznym FR955:
w lokalnych próbach symulator nie przekazywał gestu przytrzymania do tarczy.

## Źródła danych i odświeżanie

Pogoda pochodzi z `Weather.getCurrentConditions()` i wymaga aktualnych danych
Garmin Connect. Bez danych widoczna jest temperatura `--°` i kreska zamiast ikony.
Wschód i zachód pochodzą z natywnych pól `SUNRISE` i `SUNSET`; tarcza nie uruchamia
GPS ani nie czyta lokalizacji. Tętno również pochodzi z natywnego pola zegarka,
bez osobnej sesji czujnika. Jedynym uprawnieniem jest `ComplicationSubscriber`.

Ikona alarmu zależy od `alarmCount > 0`, a braku połączenia od `!phoneConnected`.
Licznik powiadomień nie jest wyświetlany.

`onUpdate()` rysuje pełną tarczę: raz na minutę w trybie oszczędnym i co sekundę
przez krótki czas po wybudzeniu. `onPartialUpdate()` odświeża wyłącznie mały
prostokąt sekund, w ramach limitu energii FR955. Nie ma timerów ani usług w tle.

Kod przechowuje wynik pomiaru godziny do zmiany minuty, datę do zmiany dnia lub
języka, szerokości tekstów do ich zmiany oraz ostatnie napisy wschodu i zachodu.
Ikony Garmina są ładowane dopiero przy pierwszym użyciu. Aktualne pomiary i stan
połączenia nadal są pobierane przy pełnym odświeżeniu.

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
2. Skopiuj `bin/GarminFace.prg` do `GARMIN/APPS` w pamięci zegarka.
3. Odłącz zegarek i wybierz **Garmin Face** w menu tarcz.

Na macOS FR955 korzysta z MTP. Można użyć [OpenMTP](https://openmtp.ganeshrvel.com/);
zamknij Garmin Express, jeśli blokuje połączenie. Publikacja w sklepie nie jest
potrzebna do testów na własnym zegarku.

## Kod projektu

| Plik | Odpowiedzialność |
| --- | --- |
| `source/GarminFaceApp.mc` | Start tarczy i wejście do dostosowania |
| `source/GarminFaceView.mc` | Składanie ekranu, godzina, sekundy i dolne pola |
| `source/FaceLayout.mc` | Współrzędne pól, wierszy i obszarów dotyku |
| `source/FaceFonts.mc` | Wspólna powiększona czcionka regularna |
| `source/ProgressArc.mc` | Wspólne rysowanie i ograniczanie wypełnienia łuków |
| `source/SunArc.mc` | Wschód, zachód i postęp dnia/nocy |
| `source/WeatherRow.mc` | Wyśrodkowany wiersz daty i pogody |
| `source/MetricFields.mc` | Odczyt danych, formatowanie i zapis wyborów |
| `source/MetricNavigation.mc` | Przytrzymanie pól i natywne skróty |
| `source/SettingsMenu.mc` | Menu danych i koloru akcentu |
| `source/FaceColors.mc` | Paleta pastelowa i zapis akcentu |
| `source/DataIcons.mc` | Ikony danych i statusu |
| `tests/` | Testy słońca, łuków, ustawień, jednostek i obszarów dotyku |

Wszystkie siedem ikon dolnych pól pochodzi z Garmin Support. Źródła oraz sposób
przygotowania SVG są opisane w `resources/drawables/garmin/SOURCES.md`.
W baterii wykorzystano sam piktogram, bez przykładowego procentu z ilustracji.
Dystans używa gotowego symbolu biegnącej postaci; odczyt pozostaje dzienny.
Ikony statusu i pogody są rysunkami wektorowymi.

Po refaktoryzacji 2026-10-29: czysta kompilacja SDK 9.3.0 z `-w -l 1` i wszystkie
18 testów przeszły. W symulatorze sprawdzono zachowanie wyglądu, odświeżanie
sekund i minut, zmianę języka polski/angielski, wybór trzech pól i akcentu oraz
ładowanie oryginalnych ikon. Potwierdzono brak funkcji pomocniczych testów
w normalnym pliku na zegarek.

Kompilacja i symulator nie zastępują sprawdzenia czytelności, skrótów dotykowych
i zużycia baterii na fizycznym zegarku.
