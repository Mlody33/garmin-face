# Źródła ikon

Oryginalne pliki PNG pobrane 2026-10-28 i 2026-10-29 z oficjalnego serwera pomocy Garmina.
Pliki źródłowe PNG pozostawiono bez zmian. Ponieważ mają nieprzezroczyste białe
tło, odpowiadające im pliki SVG zawierają monochromatyczną maskę ich sylwetek:
ciemne piksele źródła są jasnoszarym kształtem, a tło jest przezroczyste.
Kompilator zasobów skaluje SVG proporcjonalnie do wysokości około 20 px.
Wyjątkiem jest szeroki piktogram baterii, pozostawiony w rozmiarze 24 × 12 px.

Artykuł: [What Do the Icons on My Garmin Watch Face Mean?](https://support.garmin.com/en-US/?faq=agZJiZRjhX2adgWkBVOHI9).

- [Steps Icon](https://atlaske-content.garmin.com/%2Fasset%2Fimages%2FSteps_Time1785338182616.png) → `steps.png`
- [Calories Icon](https://atlaske-content.garmin.com/%2Fasset%2Fimages%2FCalories_Time1785335444509.png) → `calories.png`
- [Stress Icon](https://atlaske-content.garmin.com/%2Fasset%2Fimages%2FStress_Time1785338230491.png) → `stress.png`
- [Heart Rate Icon](https://atlaske-content.garmin.com/%2Fasset%2Fimages%2FHeart_Rate_Time1785336913513.png) → `heart_rate.png`
- [Battery Level Icon](https://atlaske-content.garmin.com/%2Fasset%2Fimages%2Fbattery_level_Time1785335088705.png) → `battery.png`
- [Floors Climbed Icon](https://atlaske-content.garmin.com/%2Fasset%2Fimages%2FFloors_Climbed_Time1785336869719.png) → `floors.png`
- [Weekly Running Distance Icon](https://atlaske-content.garmin.com/%2Fasset%2Fimages%2FWeekly_Running_Distance_Time1785339012464.png) → `distance.png`

Grafika baterii zawiera przykładowe „23%” wewnątrz czarnego koła. Do `battery.svg`
wyodrębniono sam biały piktogram baterii: prostokąt źródła od (28, 18) do (52, 30).
Jego maska ma ten sam szary kolor co pozostałe ikony; przykładowy procent nie jest
wyświetlany, bo rzeczywisty poziom baterii podaje tarcza.

Symbol biegnącej postaci z grafiki Weekly Running Distance jest używany dla
dziennego dystansu. Zmienia się tylko ikona; odczyt nadal pochodzi z dziennego
`ActivityMonitor.Info.distance`, bez zmiany okresu ani rodzaju danych.

To zasoby graficzne z Garmin Support, nie ikony udostępnione bezpośrednio przez
Connect IQ SDK. `Complication.getIcon()` zwraca `null` dla natywnych pól systemowych.

## Wschód i zachód słońca

Gotowy wspólny symbol Garmin „Sunrise & Sunset” z [instrukcji Venu X1](https://www8.garmin.com/manuals/webhelp/GUID-C144B465-A0C8-4FE9-AFE6-41A3FE3F1D9A/EN-US/GUID-6CA02868-A131-4F6E-BEED-D89FC04DE048.html).

- [Oryginalny SVG](https://www8.garmin.com/manuals/webhelp/GUID-C144B465-A0C8-4FE9-AFE6-41A3FE3F1D9A/Shared/GUID-E5D1DB09-0F11-4699-A1EF-DCCEE9A40CE3-high.svg) → `sunrise_sunset.original.svg`.
- `sunrise_sunset.svg` zachowuje geometrię oryginału, dodając szare wypełnienie. Kompilator skaluje go do około 26 × 18 px.
- To jeden symbol dla obu zdarzeń; nie zawiera osobnych strzałek wschodu i zachodu.
