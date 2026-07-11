// part4 - supernodes

// фільми з найбільшою к-стю оцінок
MATCH (m:Movie)
WITH m, size([(m)<-[:RATED]-() | 1]) AS rels
ORDER BY rels DESC
LIMIT 10
RETURN m.title AS movie, rels AS ratingCount;

// юзери-рецензенти
MATCH (u:User)
WITH u, size([(u)-[:RATED]->() | 1]) AS rels
ORDER BY rels DESC
LIMIT 10
RETURN u.userId AS user, rels AS ratingCount;

// жанри теж можуть бути supernodes
MATCH (g:Genre)<-[:HAS_GENRE]-(m:Movie)
WITH g.name AS genre, count(m) AS movieCount
ORDER BY movieCount DESC
RETURN genre, movieCount;

// розподіл по бакетах
MATCH (m:Movie)
WITH m, size([(m)<-[:RATED]-() | 1]) AS cnt
RETURN
  CASE
    WHEN cnt < 10   THEN '<10'
    WHEN cnt < 50   THEN '10-49'
    WHEN cnt < 200  THEN '50-199'
    WHEN cnt < 500  THEN '200-499'
    WHEN cnt < 1000 THEN '500-999'
    ELSE '1000+'
  END AS bucket,
  count(*) AS movies
ORDER BY bucket;
