# Rechenrunde

Kopfrechen-Päckchen für die Klasse. Die Kinder rechnen auf dem Tablet oder Handy, die Lehrkraft sieht auf einem anderen Gerät sofort, wer was wie gerechnet hat.

Die App besteht aus einer einzigen Webseite (`index.html`) und läuft **nur über GitHub Pages**. Die Daten liegen in einem kostenlosen Supabase-Projekt in Frankfurt.

## Was die App kann

- **Päckchen anlegen:** Rechenart (Addition, Subtraktion, Multiplikation, Division, Mischung), Anzahl der Aufgaben und eine automatische Zeitgrenze in Minuten. Die Aufgaben legst du auf eine von zwei Arten fest:
  - **Nach Zahlenraum:** bis 10, 20, 100, 1000, 10 000, 100 000 oder 1 000 000.
  - **Genau einstellen:** Für jede Zahl der Aufgabe (z. B. 1. und 2. Summand) wählst du, wie viele Stellen sie hat (nur Einer, bis Zehner, bis Hunderter … bis Hunderttausender) und welche Ziffern an jeder Stelle vorkommen dürfen. Beispiele: Zehnerzahlen wie 20 + 70 = „bis Zehner“, Einer „immer 0“. Hunderter plus Einer = erste Zahl „bis Hunderter“ mit Zehnern und Einern „immer 0“, zweite Zahl „nur Einer“. Zusätzlich wählst du den Zahlenraum (oder „ohne Begrenzung“): Alle Zahlen der Aufgabe und das Ergebnis bleiben darunter, und es gibt nur Stellen, die in den Zahlenraum passen. Unter der Einstellung siehst du sofort Beispielaufgaben. In der Mischung kannst du die Rechenarten einzeln ein- und ausschalten und für jede eigene Regeln setzen.
- **Versuche pro Tag:** Beim Anlegen oder später an jedem Päckchen stellst du ein, wie oft ein Kind es pro Tag rechnen darf (1, 2, 3, 4, 5, 10 Versuche oder unbegrenzt). Die Kinder sehen, wie viele Versuche heute noch übrig sind. Ist das Limit erreicht, gibt es keinen Start-Knopf mehr, sondern den Hinweis „Morgen geht es weiter“.
  - **Ändern löscht nichts.** Das Limit lässt sich jederzeit erhöhen, senken oder entfernen. Bereits gemachte Versuche bleiben immer gespeichert und zählen für heute mit. Beispiel: Ein Kind hat heute schon 2 Versuche gemacht. Stellst du auf 3, hat es noch einen übrig. Stellst du auf 1, darf es heute nicht mehr, seine 2 Versuche bleiben aber erhalten.
  - **Zählweise:** Pro Kind und Päckchen. Ein Versuch zählt ab der ersten beantworteten Aufgabe (ein sofort abgebrochener Versuch ohne Antwort verbraucht nichts). Ein Versuch, der gerade läuft, wird immer zu Ende gerechnet. Ein neuer Tag beginnt um Mitternacht deutscher Zeit. Die Datenbank prüft das Limit beim Speichern. Es hilft also nicht, die Seite neu zu laden oder ein anderes Gerät zu nehmen.
- **Antwort in der Aufgabenzeile:** Die Kinder tragen das Ergebnis direkt hinter dem Gleichheitszeichen ein, auf Kästchenpapier. Nur bei sehr langen Aufgaben bricht die Zeile um.
- **QR-Code pro Päckchen:** Die Kinder scannen den Code und rechnen genau dieses Päckchen. In der nächsten Woche legst du ein neues Päckchen mit neuem QR-Code an.
- **Üben über mehrere Tage:** Dieselben Aufgaben können beliebig oft gerechnet werden. Die Kinder sehen ihren Verlauf und bekommen einen Hinweis bei einem neuen Bestwert.
- **Zeit wird gestoppt:** pro Aufgabe und insgesamt. Die Kinder sehen die vergangene Zeit groß, die Restzeit klein daneben. Läuft die Zeitgrenze ab, bricht die App ab und speichert, was bis dahin gerechnet wurde.
- **Live-Ansicht für dich:** Jede Antwort erscheint sofort auf deinem Gerät, mit Zeit, Fehlern und Auswertung nach Kind und Päckchen.

## Einmalig einrichten

Die Datenbank ist schon angelegt und abgesichert (Supabase-Projekt `rechenrunde`, Region Frankfurt). Es fehlen nur diese Schritte:

### 1. Dein Lehrer-Konto anlegen

1. Supabase-Dashboard öffnen → Projekt **rechenrunde**.
2. **Authentication → Users → Add user → Create new user.**
3. E-Mail und ein langes Passwort eintragen und **„Auto Confirm User“ anhaken**.

Das erste bestätigte Konto wird automatisch zum Lehrer-Konto. Alle späteren Konten bekommen keinen Zugriff auf Kinder und Ergebnisse.

### 2. Neue Registrierungen abschalten

**Authentication → Sign In / Providers →** die Option **„Allow new users to sign up“** ausschalten. Dann kann sich niemand sonst ein Konto anlegen.

### 3. Auf GitHub hochladen

1. Auf github.com ein neues Repository anlegen, z. B. `rechenrunde`.
2. **Add file → Upload files** und den **gesamten Inhalt dieses Ordners** hineinziehen, also `index.html`, `config.js`, `README.md` sowie die Ordner `vendor/`, `fonts/` und `supabase/`. Wichtig: Die Ordner müssen mit hoch, sonst fehlen Schrift, QR-Code und Datenbank-Anbindung.
3. **Commit changes** klicken.

### 4. GitHub Pages einschalten

**Settings → Pages → Source: „Deploy from a branch“ → Branch `main`, Ordner `/ (root)` → Save.**

Nach ein bis zwei Minuten steht oben die Adresse deiner App, etwa `https://DEINNAME.github.io/rechenrunde/`. Öffne sie, tippe auf **Lehrer-Ansicht**, melde dich an und lege dein erstes Päckchen an.

Der QR-Code wird aus der Adresse gebaut, unter der du die App gerade geöffnet hast. Öffne die Lehrer-Ansicht deshalb immer über die GitHub-Pages-Adresse und nicht aus einer lokalen Datei.

## Was die Kinder brauchen

Nichts außer dem QR-Code. Kein Konto, kein Passwort. Du trägst die Vornamen unter **Kinder verwalten** ein, die Kinder tippen auf ihren Namen und rechnen.

Kinder können sich nicht selbst anlegen. So entstehen keine doppelten oder falsch geschriebenen Namen.

## Datenschutz

- Nur Vornamen oder Kürzel verwenden, keine Nachnamen.
- Die Daten liegen bei Supabase in Frankfurt (EU). Frag bei Bedarf kurz bei der Schulleitung nach, ob der Einsatz freigegeben ist. Je nach Bundesland braucht es dafür eine Freigabe oder einen Auftragsverarbeitungsvertrag mit Supabase.
- Die App lädt keine Schriften und keine Skripte von fremden Servern. Alles liegt im Repository.
- Über **Kind und alle Versuche löschen** entfernst du ein Kind samt Ergebnissen endgültig.

## Wie die Absicherung funktioniert

Der Schlüssel in `config.js` (`sb_publishable_…`) ist **öffentlich gedacht**. Er steht in jeder Webseite, die Supabase benutzt. Geschützt sind die Daten durch Zugriffsregeln in der Datenbank (`supabase/schema.sql`):

| Wer | Darf |
|---|---|
| Kinder (nicht angemeldet) | Namen und Päckchen lesen, einen eigenen Versuch speichern, den eigenen Verlauf abrufen. Mehr nicht. |
| Du (angemeldet) | Alles lesen, anlegen, ändern und löschen. |
| Alle anderen | Nichts. |

Ergebnisse anderer Kinder können Kinder **nicht** auslesen. Der Supabase-Sicherheitscheck zeigt zwei Hinweise zu `save_session` und `kid_history`. Das ist gewollt, denn genau diese zwei Funktionen dürfen die Kinder aufrufen.

Das **Passwort** und der **secret key** gehören nie in eine Datei im Repository.

## Gut zu wissen

- **Kostenloses Supabase pausiert nach 7 Tagen ohne Aktivität**, zum Beispiel in den Ferien. Die Daten bleiben erhalten. Im Dashboard auf **Resume project** klicken (bis 90 Tage nach der Pause möglich), dann läuft alles wieder. Vor einem Einsatz nach den Ferien einmal die App öffnen.
- **Passwort vergessen:** Im Supabase-Dashboard unter Authentication → Users beim Konto ein neues Passwort setzen.
- **Sicherung:** Für eine Sicherung aller Daten im Dashboard unter Table Editor die Tabellen als CSV exportieren.
- **Neues Supabase-Projekt?** `supabase/schema.sql` im SQL Editor ausführen (das Skript lässt sich gefahrlos wiederholen), danach Project URL und Publishable key in `config.js` ersetzen.
- **Altes Datenbank-Skript eingespielt?** Dann einmal die aktuelle `supabase/schema.sql` ausführen. Sie ergänzt die Spalte `spec` (für „Genau einstellen“) sowie `max_per_day` und die Funktion `kid_today` (für „Versuche pro Tag“). In deinem Projekt „rechenrunde“ ist beides schon angelegt. Ohne diese Ergänzung kann das Limit nicht gespeichert werden.

## Dateien

| Datei | Zweck |
|---|---|
| `index.html` | die ganze App |
| `config.js` | Adresse und öffentlicher Schlüssel deines Supabase-Projekts |
| `supabase/schema.sql` | Tabellen, Zugriffsregeln, Funktionen |
| `vendor/supabase.js` | supabase-js 2.119.2 (MIT) |
| `vendor/qrcode.js` | qrcode-generator (MIT) |
| `fonts/` | Kalam (Überschriften), Atkinson Hyperlegible (Text), Andika (alle Ziffern und die Aufgaben). Alle unter SIL Open Font License, Texte in `fonts/LIZENZEN.txt` |
