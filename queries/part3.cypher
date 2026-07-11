// part3.cypher

// Q1 - thriller фільми з avg > 4.0
MATCH (m:Movie)-[:HAS_GENRE]->(g:Genre {name: 'Thriller'})
MATCH (m)<-[r:RATED]-()
WITH m.title AS title, avg(r.rating) AS avgRat, count(r) AS cnt
WHERE avgRat > 4.0
RETURN title, round(avgRat, 2) AS avgRating, cnt
ORDER BY avgRat DESC
LIMIT 15;

// Q2 - користувачі з 50+ п'ятірками
MATCH (u:User)-[r:RATED]->(m:Movie)
WHERE r.rating = 5
WITH u.userId AS uid, count(m) AS fives
WHERE fives > 50
RETURN uid, fives
ORDER BY fives DESC;

// Q3
MATCH (u1:User {userId: 1})-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User {userId: 2})
WHERE r1.rating >= 4 AND r2.rating >= 4
RETURN m.title AS title,
       r1.rating AS user1rating,
       r2.rating AS user2rating
ORDER BY (r1.rating + r2.rating) DESC;

// Q4 - жанри: середній рейтинг + кількість
MATCH (g:Genre)<-[:HAS_GENRE]-(m:Movie)<-[r:RATED]-()
WITH g.name AS genre, avg(r.rating) AS avgRat, count(r) AS total
RETURN genre, round(avgRat, 2) AS avgRating, total
ORDER BY avgRat DESC;

// Q5 - рекомендація для userId=1

// перший варіант без overlap порога повертав занадто багато шуму
// MATCH (target:User {userId: 1})-[:RATED]->(m:Movie)<-[:RATED]-(other:User)
// MATCH (other)-[r:RATED]->(rec:Movie) WHERE NOT exists((target)-[:RATED]->(rec))
// RETURN rec.title, count(*) AS cnt ORDER BY cnt DESC LIMIT 10;

// з overlap >= 3 набагато краще
MATCH (target:User {userId: 1})-[r1:RATED]->(m:Movie)<-[r2:RATED]-(other:User)
WHERE r1.rating >= 4 AND r2.rating >= 4
WITH target, other, count(m) AS overlap
WHERE overlap >= 3
MATCH (other)-[r3:RATED]->(rec:Movie)
WHERE r3.rating >= 4
  AND NOT exists((target)-[:RATED]->(rec))
RETURN rec.title AS recommendation,
       count(DISTINCT other) AS supporters,
       round(avg(r3.rating), 2) AS avgRat
ORDER BY supporters DESC, avgRat DESC
LIMIT 15;

// Q6 - shortest path
// TODO: якщо шлях не знаходиться, спробувати інших юзерів
MATCH path = shortestPath(
  (u1:User {userId: 1})-[:RATED*]-(u2:User {userId: 2})
)
RETURN length(path) AS pathLen,
       [n IN nodes(path) |
         CASE WHEN 'Movie' IN labels(n) THEN n.title
              ELSE 'User ' + toString(n.userId)
         END
       ] AS chain;
