// part5_gds.cypher

// ---------- 5.1 PageRank ----------

// матеріалізуємо CO_RATED ребра між фільмами
MATCH (m1:Movie)<-[r1:RATED]-(u:User)-[r2:RATED]->(m2:Movie)
WHERE r1.rating >= 4 AND r2.rating >= 4 AND elementId(m1) < elementId(m2)
WITH m1, m2, count(u) AS weight
WHERE size([(m1)<-[:RATED]-() | 1]) > 20
  AND size([(m2)<-[:RATED]-() | 1]) > 20
WITH m1, m2, weight
ORDER BY weight DESC
LIMIT 50000
MERGE (m1)-[co:CO_RATED]-(m2)
SET co.weight = weight;

// проекція
CALL gds.graph.project(
  'movieGraph',
  'Movie',
  { CO_RATED: { orientation: 'UNDIRECTED', properties: 'weight' } }
)
YIELD graphName, nodeCount, relationshipCount;

// pagerank
CALL gds.pageRank.stream('movieGraph', {
  relationshipWeightProperty: 'weight',
  maxIterations: 20,
  dampingFactor: 0.85
})
YIELD nodeId, score
WITH gds.util.asNode(nodeId) AS movie, score
ORDER BY score DESC
LIMIT 15
RETURN movie.title AS title, round(score, 4) AS pageRank;

// cleanup -- видалити проекцію та тимчасові ребра
CALL gds.graph.drop('movieGraph');
MATCH ()-[co:CO_RATED]-() DELETE co;


// ---------- 5.2 Louvain ----------

// матеріалізація SIMILAR ребер між юзерами
// rating = 5 та LIMIT 20000 -- щоб heap не вибухнув
CALL apoc.periodic.iterate(
  "MATCH (u1:User)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
   WHERE r1.rating = 5 AND r2.rating = 5 AND elementId(u1) < elementId(u2)
   WITH u1, u2, count(m) AS weight
   ORDER BY weight DESC
   LIMIT 20000
   RETURN u1, u2, weight",
  "MERGE (u1)-[sim:SIMILAR]-(u2) SET sim.weight = weight",
  {batchSize: 1000, parallel: false}
)
YIELD batches, total, errorMessages;

// graph projection на SIMILAR
CALL gds.graph.project(
  'userGraph',
  'User',
  { SIMILAR: { orientation: 'UNDIRECTED', properties: 'weight' } }
)
YIELD graphName, nodeCount, relationshipCount;

// louvain community detection
CALL gds.louvain.stream('userGraph', {
  relationshipWeightProperty: 'weight'
})
YIELD nodeId, communityId
WITH communityId, gds.util.asNode(nodeId) AS node
WITH communityId, collect(node.userId) AS members
RETURN communityId, size(members) AS memberCount
ORDER BY memberCount DESC
LIMIT 10;

// top genres per cluster -- sanity check
CALL gds.louvain.stream('userGraph', {
  relationshipWeightProperty: 'weight'
})
YIELD nodeId, communityId
WITH communityId, gds.util.asNode(nodeId) AS u
WITH communityId, collect(u) AS users
WHERE size(users) >= 10
UNWIND users AS u
MATCH (u)-[r:RATED]->(m:Movie)-[:HAS_GENRE]->(g:Genre)
WHERE r.rating >= 4
WITH communityId, g.name AS genre, count(*) AS cnt
ORDER BY communityId, cnt DESC
WITH communityId, collect({genre: genre, cnt: cnt})[..3] AS top3
RETURN communityId, top3;

CALL gds.graph.drop('userGraph');
MATCH ()-[sim:SIMILAR]-() DELETE sim;


// ---------- 5.3 Dijkstra ----------

// знову матеріалізуємо SIMILAR (видалили в попередній секції)
CALL apoc.periodic.iterate(
  "MATCH (u1:User)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
   WHERE r1.rating = 5 AND r2.rating = 5 AND elementId(u1) < elementId(u2)
   WITH u1, u2, count(m) AS weight
   ORDER BY weight DESC
   LIMIT 20000
   RETURN u1, u2, weight",
  "MERGE (u1)-[sim:SIMILAR]-(u2) SET sim.weight = weight",
  {batchSize: 1000, parallel: false}
)
YIELD batches, total, errorMessages;

CALL gds.graph.project(
  'userGraphDijkstra',
  'User',
  { SIMILAR: { orientation: 'UNDIRECTED', properties: 'weight' } }
)
YIELD graphName, nodeCount, relationshipCount;

// пара 1: два найактивніших юзери
MATCH (src:User {userId: 4277}), (tgt:User {userId: 3391})
CALL gds.shortestPath.dijkstra.stream('userGraphDijkstra', {
  sourceNode: src,
  targetNode: tgt,
  relationshipWeightProperty: 'weight'
})
YIELD index, sourceNode, targetNode, totalCost, nodeIds, costs, path
RETURN
  [nId IN nodeIds | gds.util.asNode(nId).userId] AS userChain,
  totalCost,
  size(nodeIds) - 1 AS hops;

// пара через 2 хопи
MATCH (src:User {userId: 10}), (tgt:User {userId: 3713})
CALL gds.shortestPath.dijkstra.stream('userGraphDijkstra', {
  sourceNode: src,
  targetNode: tgt,
  relationshipWeightProperty: 'weight'
})
YIELD nodeIds, totalCost
RETURN
  [nId IN nodeIds | gds.util.asNode(nId).userId] AS userChain,
  totalCost,
  size(nodeIds) - 1 AS hops;

MATCH (src:User {userId: 10}), (tgt:User {userId: 949})
CALL gds.shortestPath.dijkstra.stream('userGraphDijkstra', {
  sourceNode: src,
  targetNode: tgt,
  relationshipWeightProperty: 'weight'
})
YIELD nodeIds, totalCost
RETURN
  [nId IN nodeIds | gds.util.asNode(nId).userId] AS userChain,
  totalCost,
  size(nodeIds) - 1 AS hops;

// drop projection + edges
CALL gds.graph.drop('userGraphDijkstra');
MATCH ()-[sim:SIMILAR]-() DELETE sim;
