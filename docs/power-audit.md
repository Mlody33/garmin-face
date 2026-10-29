# Audyt energetyczny — 2026-10-29

Profil: Forerunner 955 / Solar, Connect IQ SDK 9.3.0, API urządzenia 5.2.0.
Punkt odniesienia: tag `1.1`, commit `caaa367`. Zachowano wygląd i ustawienia.

Ten raport opisuje optymalizację wydaną jako `1.2`. Późniejsza poprawka godzin
słonecznych zastępuje odczyt pól `SUNRISE`/`SUNSET` obliczeniami `Weather.getSunrise`
i `Weather.getSunset` dla konkretnych dat. Dodaje pasywny odczyt zapisanej pozycji
i uprawnienie `Positioning`, bez uruchamiania GPS ani połączenia sieciowego.
Obliczenia są buforowane według dnia i pozycji; opis bieżącej logiki jest w README.

## Co zmieniono

- Gotowy ekran bez sekundnika jest przechowywany w `BufferedBitmap`. Powstaje ponownie po zmianie wyświetlanej wartości, konfiguracji, alarmu, połączenia, daty/języka, minuty lub widocznego stopnia wypełnienia łuku. Przy niezmiennych danych pełne wywołanie `onUpdate` kopiuje gotowy ekran i dodaje sekundy.
- Każde `onUpdate` nadal odtwarza cały ekran. Pozwala to poprawnie wracać po menu i nakładkach systemowych. `onShow` unieważnia bufor oraz odczyty pogody i godzin słonecznych.
- Dane aktywności i statusy nadal są sprawdzane przy pełnych aktualizacjach. Powtarzające się pola korzystają z jednego odczytu. Formatowanie odbywa się po zmianie surowej wartości; przebudowa obrazu dopiero po zmianie widocznego tekstu.
- Pogoda i natywne godziny słoneczne są pobierane najwyżej raz na minutę oraz po powrocie do tarczy. Ukryte godziny słoneczne nie są odczytywane. Przy ukrytych wszystkich polach i łukach pomijany jest również odczyt aktywności.
- Cyfrowe sekundy korzystają z dziesięciu gotowych obrazów cyfr. Ich przygotowanie i weryfikacja szerokości fontu odbywają się poza `onPartialUpdate`. Proporcjonalny font awaryjny zachowuje natywne rysowanie i odstępy.
- Zwykły krok analogowego sekundnika korzysta z przygotowanych współrzędnych i prostokąta odświeżania. Nie tworzy tablic ani napisów. Obsłużono 59 → 00 oraz pominięte wywołania. Przy nieciągłym skoku czasu obszar jest wyliczany na nowo.
- Obszar kropki w zwykłym kroku mieści się w 20 × 20 px; wycinanie uwzględnia oba położenia i cały promień kropki. Piksele pod poprzednią pozycją odtwarza gotowy ekran, więc nie znika fragment ikony ani tekstu.
- W częściowych aktualizacjach nie ma odczytów pogody, aktywności, baterii, Storage, tworzenia fontów ani ponownego wyznaczania palety.
- Skrypt budowania stosuje `-O 3p`. Zmienna `CIQ_OPTIMIZATION` pozwala nadpisać tę opcję.

## Przegląd pozostałych modułów

`MetricFields` korzysta z pomiarów już wykonanych przez zegarek. Nie uruchamia czujnika tętna. `DataIcons` ładuje zasoby leniwie i zachowuje je w pamięci. `FaceFonts`, kolory i ustawienia również są przechowywane w pamięci. Menu i nawigacja działają w reakcji na użytkownika, nie w pętli sekundnika. `ProgressArc` ogranicza wypełnienie do 72°.

Nie dodano timera, aktywnego GPS, żądania sieciowego, usługi w tle ani wybudzania zegarka. Jedynym uprawnieniem pozostaje `ComplicationSubscriber`.

## Porównanie czasu wykonania

Test `renderingPerformance` korzysta z `System.getTimer()` w symulatorze na tym samym komputerze. Przed pomiarem wykonywana jest klatka rozgrzewająca. Dwa dolne pola: kroki i kalorie; dane pozostają niezmienne. Pełny widok, fonty i rozmiary jak w wersji 1.1. Wyniki to pojedyncze przebiegi, a nie średnia statystyczna.

| 50 pełnych aktualizacji | Wersja 1.1 | Po optymalizacji i `-O 3p` |
| --- | ---: | ---: |
| Ciemne tło, cyfrowe sekundy | 795 ms | 113 ms |
| Ciemne tło, kropka | 700 ms | 94 ms |
| Jasne tło, cyfrowe sekundy | 779 ms | 122 ms |
| Jasne tło, kropka | 714 ms | 97 ms |

W tym scenariuszu czas wykonania i rysowania w symulatorze jest około 6,4–7,4 razy krótszy. Przy zmianie danych ekran trzeba przebudować, więc ten wynik nie opisuje każdej klatki.

Osobny mikrotest 1200 odrysowań cyfr, w tej samej kompilacji:

| Cyfrowe sekundy | Natywne rysowanie z formatowaniem | Gotowe obrazy cyfr |
| --- | ---: | ---: |
| Ciemne tło | 742 ms | 468 ms |
| Jasne tło | 718 ms | 486 ms |

Pomiary nie obejmują energii transmisji obrazu do fizycznego wyświetlacza. Nie należy przeliczać ich na procent mniejszego zużycia baterii.

W końcowej zwykłej wersji PRG, w trybie **Always-Active**, okno **Watchface Diagnostics**
pokazało dla pojedynczej próbki analogowego sekundnika: `Total Time: 4248`,
`Execution Time: 681`, `Graphics Time: 31`, `Display Time: 3536` (wartości odczytane
z narzędzia). Potwierdzono dalszy ruch kropki w tym trybie. Koszt zależy od położenia
kropki i nie jest to średnia z całej minuty ani pomiar prądu.

## Pamięć

Bufor sceny ma 260 × 260 pikseli i pełną paletę urządzenia; pozwala zachować wygładzanie istniejących fontów. Przy 8 bitach na piksel sam obraz to około 67 600 bajtów pamięci grafiki. Dodatkowo przechowywanych jest dziesięć małych obrazów cyfr i geometria sekundnika. Zasoby te są ponownie używane.

W normalnym symulatorze FR955 obserwowano około 28–32 KiB w liczniku pamięci programu przy przełączaniu widoków i obu rodzajów sekundnika. To odczyt pamięci programu, nie suma wszystkich buforów grafiki. Test runner ma inny limit pamięci niż normalnie uruchomiona tarcza, dlatego sprawdzono także zwykły plik `GarminFace.prg` na profilu FR955.

## Weryfikacja

- Kompilacja `bash scripts/build.sh -w -l 1` i oddzielna kompilacja testów z `--tests`, obie z `-O 3p`.
- 29 testów przeszło: ustawienia, oba widoki, formaty i brak danych, geometria wszystkich 60 pozycji, prostokąty odświeżania, przejście minuty, pominięty tick, unieważnianie bufora i test wydajności.
- Test bufora potwierdza ponowne użycie niezmiennej sceny oraz odświeżenie po zmianie tła, rodzaju sekundnika, prostego widoku, pola, akcentu i po powrocie do tarczy.
- W normalnym symulatorze potwierdzono cyfrowe i analogowe sekundy na jasnym i ciemnym tle, oba widoki oraz zmianę kroków 0 → 1234 i kalorii 0 → 98 wraz z łukiem, bez restartu. Przywrócono dane testowe i ustawienia.
- Kod testów i pomiarów jest oznaczony `(:test)` i nie trafia do zwykłego PRG.

## Granice wniosków

Częściowe odświeżanie co sekundę nadal wymaga pracy procesora i wyświetlacza. Zachowano tę funkcję zgodnie z wybranym wyglądem. Symulator nie mierzy poboru prądu ani długości pracy baterii. Nie sprawdzono tej wersji na fizycznym zegarku.

Porównanie baterii wymaga tej samej konfiguracji zegarka i równych okresów obserwacji wersji 1.1 oraz wersji zoptymalizowanej, z podobną liczbą treningów, powiadomień, gestów i użyciem podświetlenia. Zysk zależy też od tego, jak często zmieniają się widoczne pomiary.

## Dokumentacja Garmina

- [Aktualizowanie tarczy co sekundę](https://developer.garmin.com/connect-iq/connect-iq-faq/how-do-i-get-my-watch-face-to-update-every-second/) — ograniczanie obszaru `setClip` i przygotowywanie buforów poza częściowym odświeżaniem.
- [Typy aplikacji i cykl życia tarczy](https://developer.garmin.com/connect-iq/articles/connect-iq-basics/App_Types.html) — pełne aktualizacje po wybudzeniu i częściowe aktualizacje w spoczynku.
- [Graphics i BufferedBitmap](https://developer.garmin.com/connect-iq/api-docs/Toybox/Graphics.html) — bufory grafiki. Przeanalizowano również lokalny przykład `samples/Analog` z SDK oraz `monkeyc --help`.
