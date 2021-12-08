# Код к курсу "Функциональное программирование". Осень 2021

## du (du - дедлайн 2021-11-05)
- [du](du/README.md)

## простые (в proj2 - дедлайн 2021-11-12)
- суммировать в несколько потоков **простые** числа от 1 до заданного N

## csv - (в proj3 - дедлайн 2021-11-19) 
- написать парсер для CSV 
``` csv
col1,col2,col3
r2 c1,r2 c2,r2 c3
"r3,c1","r3,c2","r3,c3"
"r4\",\"\\c1","r4\",\"c2","r4\",\"c3"
```
Должен получиться `csvParser :: Parser [[String]]`.
В примере он должен вернуть
`[["col1","col2","col3"],["r2 c1","r2 c2","r3 c3"],["r3,c1","r3,c2","r3,c3"],["r4\",\"\\c1","r4\",\"c2","r4\",\"c3"]]`

## sumAndTabulate (в proj4 - дедлайн 2021-11-26) 
- написать `sumAndTabulate` 

## lens and streaming (дедлайн 2021-12-10)
- взять данные из Our World in Data: https://github.com/owid/covid-19-data/blob/master/public/data/owid-covid-data.csv (данные отсортированы по странам и по датам)
- распарсить ежедневные случаи COVID-19 (new_cases_smoothed), ежедневные смерти (new_deaths_smoothed), ежедневные вакцинации (new_vaccinations_smoothed) и, собственно, страну (iso_code), континент (continent) и население (population). Достаточно парсить столбцы с нужными индексами
- записать эти данные в соответствующий тип данных
- просуммировать (в другой тип данных) и вывести на экран указанные данные, сгруппировав их по континенту и в целом по миру
- использовать streaming, streaming-attoparsec (для связи с парсингом csv), streaming-bytestring (для чтения данных из файла), lens (для доступа к компонентам типов данных)

## api (дедлайн 2021-12-17)

- приготовить клиента для https://anapioficeandfire.com/, используя servant
- продемонстрировать работу, сделав несколько запросов в main

# Дальнейшие действия

Если вы хотите добрать баллы: сделайте доклад (10-15 минут) по одной из следующих тем. Можно добрать до 28 (если меньше 18 баллов), или не более 10 баллов в противном случае. 
В докладе необходимо объяснить, зачем нужна библиотека, на каких она основана принципах и какие использует абстракции, и продемонстрировать пример кода, работающего с ней.

## Темы 

- QuickCheck (и отличия от hedgehog, если про неё уже было)
- hedgehog (и отличия от QuickCheck, если про неё уже было)
- smallcheck (и отличия от QuickCheck, если про неё уже было)
- gauge
- beam (набор пакетов)
- opaleye
- polysemy (и отличия от других пакетов)
- free (и отличия от других пакетов)
- freer-effects (и отличия от других пакетов)
- fused-effects (и отличия от других пакетов)
- co-log
- ... (если нужно ещё - напишите в Teams)
