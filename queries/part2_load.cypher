// part2_load.cypher -- індекси, вузли, ребра

// індекси -- до завантаження ребер

CREATE INDEX user_id IF NOT EXISTS FOR (u:User) ON (u.userId);
CREATE INDEX movie_id IF NOT EXISTS FOR (m:Movie) ON (m.movieId);
CREATE INDEX genre_name IF NOT EXISTS FOR (g:Genre) ON (g.name);

// users

LOAD CSV WITH HEADERS FROM 'file:///users.csv' AS row
MERGE (u:User {userId: toInteger(row.userId)})
SET u.gender = row.gender,
    u.age = toInteger(row.age),
    u.occupation = toInteger(row.occupation);

// movies

LOAD CSV WITH HEADERS FROM 'file:///movies.csv' AS row
MERGE (m:Movie {movieId: toInteger(row.movieId)})
SET m.title = row.title,
    m.year = toInteger(row.year);

// жанри - розбити genres по '|' і зв'язати з Movie

LOAD CSV WITH HEADERS FROM 'file:///movies.csv' AS row
WITH toInteger(row.movieId) AS mid, split(row.genres, '|') AS gs
MATCH (m:Movie {movieId: mid})
UNWIND gs AS gName
MERGE (g:Genre {name: gName})
MERGE (m)-[:HAS_GENRE]->(g);

// ratings -- батчами через apoc, бо мільйон рядків в одну транзакцію не влізе

CALL apoc.periodic.iterate(
  "LOAD CSV WITH HEADERS FROM 'file:///ratings.csv' AS row RETURN row",
  "MATCH (u:User {userId: toInteger(row.userId)})
   MATCH (m:Movie {movieId: toInteger(row.movieId)})
   MERGE (u)-[r:RATED]->(m)
   SET r.rating = toInteger(row.rating),
       r.timestamp = toInteger(row.timestamp)",
  {batchSize: 5000, parallel: false}
);

// check
MATCH (u:User) RETURN count(u) AS users;
MATCH (m:Movie) RETURN count(m) AS movies;
MATCH (g:Genre) RETURN count(g) AS genres;
MATCH ()-[r:RATED]->() RETURN count(r) AS ratings;
