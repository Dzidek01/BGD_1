1. Ingestion Problem (Niestabilność typowania i brak checkpointów w Pandasie)
   Do załadowania surowych danych użyłem biblioteki pandas i metody to_sql w pętli dzielącej plik na paczki (chunks po 50 000 wierszy).

Ryzyko: Pandas domyślnie wnioskuje typy danych na podstawie aktualnie wczytywanej paczki (Type Inference). Jeśli w pierwszych paczkach kolumna wygląda na liczby całkowite (INT), baza utworzy taką kolumnę. Jeśli w 150. paczce w tej samej kolumnie nagle pojawi się tekst (np. zepsuty log), mój skrypt rzuci błędem i przerwie działanie w połowie procesu. Ponadto, skrypt nie posiada mechanizmu "checkpointów" – przerwanie połączenia oznacza dla mnie konieczność ładowania dziesiątek milionów wierszy od nowa.

2. Transformation Problem (Braki danych i zafałszowana analityka biznesowa)
   Płaskie pliki z logami zachowań użytkowników (jak analizowany przeze mnie plik CSV) są z natury bardzo "brudne". Podczas eksploracji surowych danych zauważyłem, że ogromna liczba wierszy posiada wartość NULL w kluczowej kolumnie wymiaru, takiej jak brand (marka). Dodatkowo zidentyfikowałem anomalie w kolumnie price (ceny zerowe lub ujemne).

Ryzyko: Gdybym nie zastosował rygorystycznych filtrów (klauzule WHERE brand IS NOT NULL i price > 0) na etapie tworzenia warstwy Srebrnej (Cleaned), moje złączenia (JOIN) i agregacje w warstwie Złotej byłyby błędne. Pusta kategoria NULL zebrałaby gigantyczną część ruchu, całkowicie niszcząc czytelność mojego raportu lejka sprzedażowego dla konkretnych marek.

3. Scale & Sharing Problem (Wydajność zapytań przy rosnącym wolumenie)
   Obecnie w warstwie Brązowej (Raw) oraz Srebrnej (Silver) posiadam dziesiątki milionów wierszy. W mojej aktualnej architekturze w PostgreSQL celowo pominąłem zaawansowane mechanizmy optymalizacyjne dla zapytań analitycznych.

Ryzyko: Gdybym udostępnił warstwę Złotą (Gold) lub Srebrną (Silver) bezpośrednio użytkownikom biznesowym (np. w celu podpięcia pulpitu PowerBI / Tableau), zaczęliby oni filtrować dane po dacie (event_time) lub marce (brand). Ponieważ nie założyłem indeksów (np. B-Tree Indexes) na tych kolumnach, baza byłaby zmuszona wykonywać tzw. Full Table Scan (skanowanie wszystkich rekordów przy każdym odświeżeniu raportu). Doprowadziłoby to do drastycznego spadku wydajności, tzw. timeoutów, i zablokowałoby bazę dla innych zapytań.
