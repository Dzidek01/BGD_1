1. Ingestion Problem (Niestabilność typowania i brak checkpointów w Pandasie)
   Do załadowania danych użyliśmy biblioteki pandas i metody to_sql w pętli dzielącej plik na paczki (chunks po 50 000 wierszy).

Ryzyko: Pandas domyślnie wnioskuje typy danych na podstawie wczytywanej paczki (Type Inference). Jeśli w pierwszych paczkach kolumna wygląda na liczby całkowite (INT), baza utworzy taką kolumnę. Jeśli w 150. paczce w tej samej kolumnie nagle pojawi się tekst (np. zepsuty log), skrypt rzuci błędem i przerwie działanie w połowie wielogodzinnego procesu. Ponadto, skrypt nie posiada mechanizmu "checkpointów" – przerwanie połączenia sieciowego oznacza konieczność ładowania dziesiątek milionów wierszy od nowa.

2. Transformation Problem (Braki danych i zafałszowana analityka biznesowa)
   Płaskie pliki z logami zachowań użytkowników (jak nasz plik CSV) są z natury bardzo "brudne". W surowych danych ogromna liczba wierszy posiada wartość NULL w kluczowych kolumnach wymiarów, takich jak brand (marka). Dodatkowo mogą zdarzyć się anomalie w kolumnie price (ceny zerowe lub ujemne).

Ryzyko: Jeśli nie zastosujemy rygorystycznych filtrów (klauzule WHERE brand IS NOT NULL i price > 0) na etapie tworzenia warstwy Srebrnej (Cleaned), nasze złączenia (JOIN) i agregacje w warstwie Złotej będą błędne. Pusta kategoria NULL zebrałaby gigantyczną część ruchu, całkowicie niszcząc czytelność raportu lejka sprzedażowego dla konkretnych marek.

3. Scale & Sharing Problem (Wydajność zapytań przy rosnącym wolumenie)
   Obecnie w warstwie Brązowej (Raw) posiadamy dziesiątki milionów wierszy załadowanych miesiąc po miesiącu. W naszej architekturze w PostgreSQL brakuje zaawansowanych mechanizmów optymalizacyjnych.

Ryzyko: Gdy udostępnimy gotową warstwę Złotą (Gold) lub Srebrną (Silver) użytkownikom biznesowym (np. analitykom podpinającym aplikację PowerBI / Tableau), zaczną oni filtrować dane po dacie (event_time) lub marce (brand). Ponieważ nie założyliśmy indeksów (np. B-Tree Indexes) na tych kolumnach, baza będzie zmuszona wykonywać tzw. Full Table Scan (skanowanie każdego z 40 milionów wierszy przy każdym odświeżeniu raportu). Doprowadzi to do drastycznego spadku wydajności, tzw. timeoutów, i może zablokować bazę dla innych procesów.
