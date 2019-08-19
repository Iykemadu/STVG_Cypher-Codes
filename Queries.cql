 //////
 CALL algo.triangleCount('User', 'FRIEND',
{concurrency:4, write:true, writeProperty:'triangles', 
clusteringCoefficientProperty:'coefficient'})
YIELD nodeCount, triangleCount, averageClusteringCoefficient,
loadMillis, computeMillis, writeMillis

 ////Evolving betweenness

MATCH (d:Day)-[:HAS_HOUR]-(h:Hour)-[:HAS_MINUTE]-(m:Minute)-[:HAS_SECOND]-(s:Second)<-[r1:HAPPENS_AT]-(to:Stops)
Where d.dayid = 7 WITH to
MATCH p = allShortestPaths((to)-[]-(bs:BusStop)) 
RETURN bs.sName, count(*) as betweeness ORDER BY betweeness DESC;

/////////////////////////////////////////////////////

MATCH (d:Day)-[:HAS_HOUR]-(h:Hour)-[:HAS_MINUTE]-(m:Minute)-[:HAS_SECOND]-(s:Second)<-[r1:HAPPENS_AT]-(to:Moves)
Where d.dayid = 7 WITH to
MATCH p = allShortestPaths((to)-[]-(bs:Streets))
RETURN bs.sName, count(*) as betweeness ORDER BY betweeness DESC;

////////////// Pagerank/Stops


call apoc.algo.pageRankWithCypher({
 write:true,
  property: 'pagerankTEST',
node_cypher:'none',
rel_cypher:'MATCH (d:Day)-[:HAS_HOUR]-(h:Hour)-[:HAS_MINUTE]-(m:Minute)-[:HAS_SECOND]-(s:Second)<-[r1:HAPPENS_AT]-(t:Stops)
Where d.dayid = 8 
AND h.hourid = 8  WITH st
MATCH (st)-[r]-(bs:BusStop) 
RETURN id(st) AS source, id(bs) AS target, count(*) AS weight'})
//////////////////////

call apoc.algo.pageRankWithCypher({
 write:true,
  property: 'pagerankTEST111',
node_cypher:'MATCH (d:Day)-[:HAS_HOUR]-(h:Hour)-[:HAS_MINUTE]-(m:Minute)-[:HAS_SECOND]-(s:Second)<-[r1:HAPPENS_AT]-(st:Stops)
Where d.dayid = 8 
AND h.hourid = 8 RETURN id(st) as id',
rel_cypher:'MATCH (st1:Stops)-[r]-(bs:BusStop) 
RETURN id(st1) AS source, id(bs) AS target, count(*) AS weight ORDER BY weight DESC LIMIT 10'})


///////////////////////Evolving Pagerank / Busy streets

call apoc.algo.pageRankWithCypher({
 write:true,
  property: 'pagerankst_7_12_16M',
node_cypher:'none',
rel_cypher:'MATCH (d:Day)-[:HAS_HOUR]-(h:Hour)<-[r1:HAPPENS_AT]-(st:Moves)
Where d.dayid = 7 
AND h.hourid > 12 OR h.hourid <17 WITH st
MATCH (st)-[r]-(bs:Streets) 
RETURN id(st) AS source, id(bs) AS target, count(*) AS weight ORDER BY weight DESC LIMIT 10'})

///////////////////// Pagerank Congestion


call apoc.algo.pageRankWithCypher({
 write:true,
  property: 'pagerankst_7_8_12',
node_cypher:'none',
rel_cypher:'MATCH (d:Day)-[:HAS_HOUR]-(h:Hour)<-[r1:HAPPENS_AT]-(st:Stops)
Where d.dayid = 7 
AND h.hourid > 7 OR h.hourid <13 WITH st
MATCH (st)-[r]-(bs:Streets) 
RETURN id(st) AS source, id(bs) AS target, count(*) AS weight ORDER BY weight DESC LIMIT 10'})


///////////////////////Evolving degree

MATCH (y:Year)-[:HAS_MONTH]-(m:Month)-[:HAS_DAY]-(d:Day)-[:HAS_HOUR]-(h:Hour)<-[r1:HAPPENS_AT]-(to:Stops)
Where d.dayid = 9
AND h.hourid = 16 WITH to
MATCH p = (to)-[r]-(st:BusStop) 
RETURN st.SName, count(r)+1 as degree ORDER BY degree DESC LIMIT 10

///////////////////

MATCH (y:Year)-[:HAS_MONTH]-(m:Month)-[:HAS_DAY]-(d:Day)-[:HAS_HOUR]-(h:Hour)<-[r1:HAPPENS_AT]-(to:Stops)
Where y.yearid = 2016 AND m.monthid = 6 AND d.dayid = 14
 WITH to
MATCH p = (to)-[r]-(st:BusStop) 
RETURN st.SName, count(r)+1 as degree ORDER BY degree DESC LIMIT 10
///////////////

MATCH (d:Day)-[:HAS_HOUR]-(h:Hour)<-[r1:HAPPENS_AT]-(t:Stops)
Where d.dayid = 7 
AND h.hourid = 20 WITH t
MATCH p = (t)-[r]-(st:BusStop) 
RETURN st.sName, count(r)+1 as degree ORDER BY degree DESC LIMIT 10

/////////////////

MATCH (d:Day)-[:HAS_HOUR]-(h:Hour)-[:HAS_MINUTE]-(m:Minute)-[:HAS_SECOND]-(s:Second)<-[r1:HAPPENS_AT]-(t:Stops)
Where d.dayid = 7  WITH t
MATCH (t)-[r]-(st:BusStop) 
RETURN st.sName, count(r)+1 as degree ORDER BY degree DESC;

/////////////////////

MATCH (d:Day)-[:HAS_HOUR]-(h:Hour)-[:HAS_MINUTE]-(m:Minute)-[:HAS_SECOND]-(s:Second)<-[r1:HAPPENS_AT]-(t:Moves)
Where d.dayid = 7 
AND h.hourid = 18 WITH t
MATCH p = (t)-[r]-(st:Streets) 
RETURN st.streetName, count(r)+1 as degree ORDER BY degree DESC LIMIT 10

///////////////////////evolving shortest path

MATCH (y:Year)-[:HAS_MONTH]-(m:Month)-[:HAS_DAY]-(d:Day)-[:HAS_HOUR]-(h:Hour)<-[r1:HAPPENS_AT]-(to:Origin)
Where y.yearid = 2016 AND m.monthid = 6 AND d.dayid = 15
 WITH to
MATCH p = shortestPath((to:Origin)-[:NEXT*..]-(td:Destination))
RETURN p 
ORDER BY LENGTH(p) ASC
LIMIT 1;

MATCH (st:Streets)-[r]-(mv:Moves)
Return distinct(st.streetName), count(r)+1 AS degree ORDER BY degree DESC
//////////////////////

/////////////////// good
call apoc.algo.pageRankWithCypher({
 write:true,
  property: 'pagerank_day7',
node_cypher:'none',
rel_cypher:'MATCH (d:Day)-[:HAS_HOUR]-(h:Hour)-[:HAS_MINUTE]-(m:Minute)-[:HAS_SECOND]-(s:Second)<-[r1:HAPPENS_AT]-(st:Stops)
Where d.dayid = 7 WITH st
MATCH (st)-[r]-(bs:BusStop) 
RETURN id(st) AS source, id(bs) AS target, count(*) AS weight'})

////////////////////////////////////////////////////////////////////////////////////////
call apoc.algo.pageRankWithCypher({
 write:true,
  property: 'pagerankT_day7',
node_cypher:'none',
rel_cypher:'MATCH (d:Day)-[:HAS_HOUR]-(h:Hour)<-[r1:HAPPENS_AT_T]-(st:Trip)
Where d.dayid = 7 WITH st
MATCH (st)-[r]-(bs:Line) 
RETURN id(st) AS source, id(bs) AS target, count(*) AS weight'})

////////////////////////////////////////////

CALL apoc.algo.betweennessCypher({
 write:true,
 property_cypher: 'betweenness_day7',
node_cypher:'none',
rel_cypher:'MATCH (d:Day)-[:HAS_HOUR]-(h:Hour)-[:HAS_MINUTE]-(m:Minute)-[:HAS_SECOND]-(s:Second)<-[r1:HAPPENS_AT]-(st:Stops)
Where d.dayid = 7 WITH st
MATCH (st)-[r]-(bs:BusStop) 
RETURN id(st) AS source, id(bs) AS target, count(*) AS weight'})

///////////////////////////////////////////
call algo.pageRank.stream(
'MATCH (int:BusStop) RETURN id(int) as id',
'MATCH (d:Day)-[:HAS_HOUR]-(h:Hour)-[:HAS_MINUTE]-(m:Minute)-[:HAS_SECOND]-(s:Second)<-[r1:HAPPENS_AT]-(st:Stops)
Where d.dayid = 7 WITH st
MATCH (st)-[r]-(bs:BusStop) 
RETURN id(st) AS source, id(bs) AS target, count(*) AS weight',
{graph:'cypher'}
) yield node,score 
return node.sName, size((node)--()) as deg, score order by score desc 
////////////////////////////////////////////

call algo.pageRank.stream(
'MATCH (h:Hour)<-[r1:HAPPENED_AT]-(cr:Crashes)
Where h.hourid = 22 RETURN id(cr) as id',
'MATCH (cr1)-[r]-(int:Intersections) RETURN id(cr1) as source, id(int) as target',
{graph:'cypher'}
) yield node,score with node,score order by score desc limit 10
return node {.IntersectionName},score;
////////////////////////////

'MATCH (d:Day)-[:HAS_HOUR]-(h:Hour)<-[r1:HAPPENS_AT]-(st:Stops)
Where d.dayid = 7 
AND h.hourid > 7 OR h.hourid <13 WITH st
MATCH (st)-[r]-(bs:Streets) 


MATCH (h:Hour)<-[r1:HAPPENED_AT]-(cr:Crashes)
Where h.hourid = 22 WITH cr



////////////////////////////////
CALL algo.pageRank(label:String, relationship:String, {iterations:20, dampingFactor:0.85,
write: true,writeProperty:'pagerank', concurrency:4})
YIELD nodes, iterations, loadMillis, computeMillis, writeMillis, dampingFactor, write, writeProperty
- calculates page rank and potentially writes back

//////////////////////////////

call algo.pageRank.stream(
'MATCH (u:User) WHERE exists( (u)-[:FRIENDS]-() ) RETURN id(u) as id',
'MATCH (u1:User)-[:FRIENDS]-(u2:User) RETURN id(u1) as source, id(u2) as target',
{graph:'cypher'}
) yield node,score with node,score order by score desc limit 10
return node {.name, .review_count, .average_stars,.useful,.yelping_since,.funny},score;

//////////
CALL algo.pageRank.stream('Streets', 'OCCURED_ON',
{iterations:20, dampingFactor:0.85, concurrency:4})
YIELD node, score - calculates page rank and streams results
/////////////////////

CALL algo.pageRank(
'MATCH (p:Page) RETURN id(p) as id',
'MATCH (p1:Page)-[:Link]->(p2:Page) RETURN id(p1) as source, id(p2) as target',
{graph:'cypher', iterations:5, write: true});

MATCH (st:Streets)
WITH collect(st) AS nodes
CALL algo.pageRank.streamCALL algo.pageRank.stream('Streets', 'OCCURED_ON') YIELD node, score
RETURN node.streetName, score
ORDER BY score DESC


