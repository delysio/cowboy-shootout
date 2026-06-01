# 🌵 COWBOY SHOOTOUT — INSTRUKCJA GRACZA 🌵
### *Klasyczny Pojedynek Rewolwerowców dla Atari 8-bit (XL/XE)*

Witaj w **Cowboy Shootout**! Zostałeś przeniesiony na Dziki Zachód, gdzie naprzeciwko siebie staje dwóch rewolwerowców: ty oraz bezwzględny przeciwnik sterowany przez sztuczną inteligencję (AI). Zasady są proste, ale przetrwanie w chmurze pyłu i ołowiu wymaga zręczności, taktyki i stalowych nerwów!

Poniżej znajdziesz kompletny przewodnik, który wyjaśni Ci zasady gry, sterowanie, mechanikę przeszkód, pojawianie się niebezpieczeństw oraz sposoby na pokonanie wroga.

---

## 🎮 1. Jak Wystartować Grę?

Po załadowaniu gry na komputerze Atari (lub emulatorze), zobaczysz grę w **trybie demonstracyjnym (Attract Mode)**. 
* W tym trybie kowboje poruszają się automatycznie, a na dolnym pasku przewija się napis zachęcający do gry: `PRESS START TO PLAY - COWBOY SHOOTOUT`.
* Aby rozpocząć pojedynek, musisz wcisnąć fizyczny (lub zmapowany w emulatorze) przycisk **START** na konsoli Atari.
* > [!IMPORTANT]
  > Gra ignoruje wszelkie inne klawisze (takie jak OPTION czy SELECT) oraz przycisk FIRE na joysticku w trybie demo. Rozgrywkę można zainicjować **wyłącznie przyciskiem START**! Zapobiega to przypadkowemu wciśnięciu klawiszy podczas uruchamiania systemu.
* Po wciśnięciu **START**:
  1. Ekran natychmiast się wyczyści.
  2. Liczniki punktów na górze ekranu zostaną wyzerowane.
  3. Na polu walki wyrośnie losowo **5 krzaków (drzew-przeszkód)**.
  4. Dolny pasek zacznie przewijać bojowe hasło: `* FIGHT! *  AVOID THE DEADLY BULLETS!`.
  5. Usłyszysz sygnał wystrzału obwieszczający start pojedynku.

---

## 🕹️ 2. Sterowanie i Ruch

Grasz jako **złoto-brązowy kowboj po lewej stronie ekranu** (Player 0). Twój przeciwnik (AI) steruje **niebieskim kowbojem po prawej stronie** (Player 1).

| Akcja | Kontroler (Joystick 0 w Porcie 1) | Opis |
| :--- | :--- | :--- |
| **Ruch w górę** | Wychylenie drążka w **GÓRĘ** | Przesunięcie kowboja w kierunku górnej granicy ekranu. |
| **Ruch w dół** | Wychylenie drążka w **DÓŁ** | Przesunięcie kowboja w kierunku dolnej granicy ekranu. |
| **Strzał** | Wciśnięcie przycisku **FIRE** | Wystrzelenie pocisku lecącego poziomo w prawo. |

* > [!TIP]
  > **Granice Ruchu**: Twoje ruchy są zablokowane fizycznymi granicami ekranu (zakres współrzędnych pionowych od 16 do 96 linii). Nie możesz wyjść poza te bariery.
  > 
  > **Wysokość lufy**: Pamiętaj, że pocisk wylatuje dokładnie z wysokości lufy pistoletu (klatka piersiowa kowboja, czyli pozycja kowboja powiększona o 7 linii). Celuj uważnie!
  > 
  > **Ograniczenie pocisków**: Na ekranie może znajdować się tylko **jeden Twój aktywny pocisk naraz**. Kolejny strzał możesz oddać dopiero wtedy, gdy poprzedni opuści planszę lub uderzy w przeszkodę/przeciwnika.

---

## 🌲 3. Zasady Gry i Dynamiczne Przeszkody

Pojedynek toczy się na pustynnej arenie porośniętej krzakami/drzewami oznaczonymi symbolem `Y` (kod ATASCII 123). Są one kluczowym elementem taktycznym!

* **Osłona przed pociskami**: Drzewa blokują pociski. Strzał uderzający w drzewo nie rani kowboja stojącego za nim.
* **Destrukcja przeszkód**: Drzewa są zniszczalne! Każde drzewo ma **3 punkty wytrzymałości (HP)**. Każde trafienie pociskiem (Twoim lub przeciwnika) zabiera mu 1 HP. Po trzech trafieniach drzewo znika z planszy.
* **Dynamiczna Regeneracja**: Co **3 sekundy** (150 klatek) gra podejmuje próbę wyhodowania nowego drzewka w losowym miejscu na środku planszy (kolumny centralne od 23 do 33, wiersze od 5 do 20).
  * Nowe drzewo nie wyrośnie, jeśli na ekranie znajduje się już maksymalna dopuszczalna liczba **8 drzew**.
  * Gra automatycznie sprawdza, czy nowe drzewo nie nakłada się na już istniejące – każde ma swoje unikalne współrzędne!

---

## 🧠 4. Zachowanie Przeciwnika (AI)

Niebieski kowboj po prawej stronie to sprytny rewolwerowiec sterowany przez komputer:
* **Sprytne unikanie przeszkód**: AI nie strzeli na oślep, jeśli na drodze jego kuli stoi drzewo. Zanim naciśnie spust, system sprawdza całą linię strzału (trajektorię). Jeśli stoi tam przeszkoda, AI powstrzymuje się od strzału i przemieszcza się dalej w poszukiwaniu czystej pozycji.
* **Błyskawiczny strzał (Smart Shoot)**: Gdy tylko przeciwnik zrówna się z Tobą w linii poziomej (różnica wysokości wynosi maksymalnie 6 linii), AI natychmiast spróbuje Cię zastrzelić! Ignoruje wtedy standardowy czas oczekiwania, zachowując jedynie minimalny, konieczny czas na przeładowanie (30 klatek, czyli ok. 0.6 sekundy).

---

## 📈 5. Wzrost Poziomu Trudności

Poziom trudności rośnie dynamicznie wraz z Twoimi sukcesami. Im więcej punktów zdobędziesz, tym szybszy i bardziej agresywny staje się przeciwnik w swoich standardowych odstępach strzeleckich:

| Poziom | Twój Wynik (Punkty) | Częstotliwość Strzałów AI | Szacowany Czas przeładowania AI |
| :---: | :---: | :---: | :---: |
| **1** | **Poniżej 10** | Co 200 klatek | ~4.0 sekundy (przy 50 Hz) |
| **2** | **Od 10 do 19** | Co 100 klatek | ~2.0 sekundy (przy 50 Hz) |
| **3** | **20 i więcej** | Co 50 klatek | ~1.0 sekunda (przy 50 Hz) |

---

## 🦅 6. Zagrożenie z Powietrza: Złoty Ptak (Bird Hazard)

Gdy myślisz, że kontrolujesz pole bitwy, z nieba nadlatuje śmiertelny hazard – **żółty, dynamicznie machający skrzydłami ptak** (Player 2)!

* **Kiedy się pojawia?**: Ptak nadlatuje regularnie co **15 sekund** (dokładnie co 750 klatek obrazu).
* **Trasa lotu (Swoop)**:
  * Spawnuje się na samej górze ekranu (Y=12) na losowej pozycji po prawej lub środkowej stronie (X od 110 do 205).
  * Leci po skosie w lewo i w dół z precyzyjną prędkością subpikselową (opadanie pionowe wynosi stałe `1.25` piksela na klatkę).
  * > [!WARNING]
    > **Zabójcza Precyzja Lotu**: Pozioma prędkość ptaka jest matematycznie wyliczana przy każdym spawnie tak, aby ptak **zawsze przecinał tor ruchu gracza (X=60) dokładnie na wysokości jego klatki piersiowej (Y=92)** po upływie 64 klatek! Oznacza to, że ptak stanowi bezpośrednie, spersonalizowane zagrożenie dla Ciebie i musisz aktywnie go unikać!
* **Animacja**: Ptak realistycznie macha skrzydłami w 3-fazowej animacji (skrzydła w górę, w poziomie, w dół) zmieniającej się co 6 klatek.
* **Kolizja z ptakiem**: Zderzenie ptaka z Twoim kowbojem powoduje **natychmiastową śmierć i natychmiastowy koniec gry (Instant Game Over)**! Ponadto przeciwnik AI otrzymuje darmowy punkt.

---

## ☠️ 7. Kiedy Gra się Kończy?

Rozgrywka dobiega końca w dwóch przypadkach:
1. **Zwycięstwo AI przez punkty**: Gdy przeciwnik (AI) jako pierwszy zdobędzie **10 punktów** (poprzez postrzelenie Twojego kowboja).
2. **Kolizja z ptakiem**: Niezależnie od aktualnego stanu punktów, uderzenie ptaka w Twojego kowboja natychmiast kończy grę.

**Po ogłoszeniu końca gry**:
* Ekran przechodzi w stan spoczynku (Attract Mode).
* Przewijany tekst u dołu zmienia się na: `GAME OVER - PRESS START TO TRY AGAIN`.
* Ramka ekranu staje się głęboko czarna.
* Dowolne aktywne pociski na ekranie są czyszczone.
* Możesz ponownie nacisnąć **START**, aby podjąć wyzwanie na nowo.

---

## 🎨 8. Dodatkowe Smaczki i Efekty

* **Sygnalizacja Trafienia**: Po udanym trafieniu, kowboj, który ucierpiał, miga gwałtownie na **czerwono** i **biało** przez 15 klatek, a w tle rozlega się dynamiczny szum wybuchu generowany sprzętowo za pomocą rejestru `RANDOM`.
* **Dźwięk strzału**: Każdy strzał generuje czysty, wznoszący się dźwięk laserowego sweepu na 1 kanale dźwiękowym POKEY.
* **Dynamiczny Scroller**: Podczas aktywnej gry dolny pasek nie jest nudny! Co **30 sekund** (1500 klatek) gra losuje jedno z 10 bojowych, zagrzewających do walki haseł, takich jak:
  * `* FIGHT! *  AVOID THE DEADLY BULLETS!`
  * `* KEEP GOING! *  YOU ARE DOING GREAT!`
  * `* DRAW FAST! *  THE AI IS GETTING MAD`
  * `* SHOW NO MERCY! *  DUEL TO THE DEATH`
  * `* DODGE THOSE SHOTS! *  STAY IN GAME!`
  * `* AWESOME PLAY! *  KEEP PUSHING HARD!`
  * `* VICTORY AWAITS! *  BECOME THE HERO!`
  * `* DUST AND BULLETS! *  WHO WILL WIN??`
  * `* UNSTOPPABLE! *  UNLEASH THE FURY!`
  * `* FOCUS! *  THE FINAL STAND IS HERE!`

---
*Powodzenia, rewolwerowcu! Trzymaj palec na spuście i miej oczy szeroko otwarte – niebo i pustynia nie znają litości!*
---
