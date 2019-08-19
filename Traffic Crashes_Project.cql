/// Add constraints to ensure unique IDs

create constraint on (st:Streets) assert st.StreetID is unique;
create constraint on (int:Intersections) assert int.IntersectionID is unique;
create constraint on (cr:Crashes) assert cr.CrashID is unique;
create constraint on (inf:InF_Factor) assert inf.InF_FactorID is unique;
create constraint on (sf:Severity_Factor) assert sf.Severity_FactorID is unique;

////load streets
LOAD CSV WITH HEADERS FROM 'file:///Streets.csv' AS st
CREATE (:Streets {StreetID: st.FID, StreetName: st.ST_NAME});

////////////////////////
//////load intersections
LOAD CSV WITH HEADERS FROM 'file:///Intersections.csv' AS int
CREATE (:Intersections {IntersectionID: int.FID, IntersectionName: int.Names});

////////////////// Add street names to the intersection nodes
LOAD CSV WITH HEADERS FROM 'file:///Intersections2.csv' AS int
MERGE (r:Intersections {IntersectionID: int.FID}) SET
r.Street1 = int.Street1,
r.Street2 = int.Street2,
r.Street3 = int.Street3,
r.Street4 = int.Street4,
r.Street5 = int.Street5,
r.Street6 = int.Street6,
r.Street7 = int.Street7,
r.Street8 = int.Street8,
r.Street9 = int.Street9,
r.Street10 = int.Street10,
r.Street11= int.Street11,
r.Street12 = int.Street12;

//////////////////// Connect the streets and intersections
match (st: Streets), (int:Intersections) where st.StreetName = int.Street1
merge (int)-[:LOCATED_AT]->(st);


////////////////// Create the traffic crash nodes

load csv with headers from
'file:///Crashes_Whole_Edited.csv' as cr
CREATE (:Crashes {CrashID: cr.FID, CrashTime: cr.CRASH_TM,Sequence: cr.Sequence,CrashAge: cr.AGE, Hour:toInt(cr.CRASH_HOD), WDay: cr.CRASH_DOW, Month: toInt(cr.CRASH_MOY)
	, Year: toInt(cr.CRASH_YEAR), Fatalities: toInt(cr.Fatalities),Injuries: toInt(cr.Injuries), Alcohol_Re: cr.Alcohol_Re, Distraction: cr.Distraction,
	Weather_Condition: cr.Weather_Co, StreetName: cr.ST_NAME, IntName: cr.INT_Names, Day: toInt(substring(cr.CRASH_DT,0,2))});


//////////////////// Create Influencing factor nodes
load csv with headers from
'file:///InF_Factor.csv' as cr
CREATE (:InF_Factor {ID: cr.Id, Name: cr.Name});

/////////////////////////// Create Severity factor nodes
load csv with headers from
'file:///Severity_Factor.csv' as cr
CREATE (:Severity_Factor {ID: cr.Id, Name: cr.Name});

/////////////// Create indexes on the attributes to be used in matching operations
CREATE INDEX ON :Streets(StreetName);
CREATE INDEX ON :Intersections(IntersectionName);
CREATE INDEX ON :Crashes(StreetName);
CREATE INDEX ON :Crashes(IntName);
CREATE INDEX ON :Crashes(Hour);
CREATE INDEX ON :Crashes(Day);
CREATE INDEX ON :Crashes(Month);
CREATE INDEX ON :Crashes(Year);

///connect crashes and streets
MATCH (cr:Crashes), (st:Streets) where cr.StreetName = st.StreetName
MERGE (cr)-[:LOCATED_AT]->(st);

///connect crashes and intersection
MATCH (cr:Crashes), (int:Intersections) where cr.IntName = int.IntersectionName
MERGE (cr)-[:LOCATED_AT]->(int);
////////////
MATCH (cr:Crashes), (int:Intersections) where cr.IntName = int.IntersectionName
MERGE (cr)-[:LOCATED_AT]->(int);

//crash_time-tree connection
MATCH (cr:Crashes) WITH cr 
MATCH (yy:Year {yearid:cr.Year}) WITH cr,yy
MATCH (yy)-[r1]->(mm:Month {monthid:cr.Month}) WITH cr,yy,mm
MATCH (mm)-[r2]->(dd:Day {dayid:cr.Day}) WITH cr,yy,mm,dd
MATCH (dd)-[r3]->(hh:Hour {hourid:cr.Hour}) WITH cr,yy,mm,dd, hh
CREATE (cr)-[:HAPPENED_AT]->(hh);

///////////////////// connect crashes and Influencing and severity factors

load csv with headers from
'file:///Crashes_Whole_Edited.csv' as cr
MATCH (st:Crashes{CrashID: cr.FID} )
SET st.Distraction = cr.Distraction


///////////////////
load csv with headers from
'file:///Crashes_Whole_Edited.csv' as cr
MATCH (st:Crashes{CrashID: cr.FID} )
SET st.Injuries= toInt(cr.Injuries)
////////////////////


/////New

MATCH (cr:Crashes), (sf:Severity_Factor) where cr.Injuries > 0
AND sf.Name = "Injuries"
MERGE (cr)-[:HAS{Injuries:toInt(cr.Injuries)}]->(sf)

/////////

MATCH (cr:Crashes), (inf:InF_Factor) where cr.Alcohol = "Y" 
AND inf.Name = "Alcohol"
MERGE (cr)-[:RELATED_TO]->(inf);

MATCH (cr:Crashes), (inf:InF_Factor) where cr.Alcohol_Re = "Y" 
AND inf.Name = "Alcohol"
MERGE (cr)-[:RELATED_TO]->(inf);

MATCH (cr:Crashes), (inf:InF_Factor) where cr.Weather_Condition =inf.Name
MERGE (cr)-[:RELATED_TO]->(inf);

/////////////
MATCH (cr:Crashes), (sf:Severity_Factor) where cr.Fatalities > 0
AND sf.Fatalities = "Y"
MERGE (cr)-[:HAS{Fatalities:cr.Fatalities}]->(sf);

/////////////////////
MATCH (cr:Crashes), (sf:Severity_Factor) where cr.Injuries > 0
AND sf.Injuries = "Y"
MERGE (cr)-[:HAS{Injuries:cr.Injuries}]->(sf);
/////////////////
MATCH (cr:Crashes), (inf:InF_Factor) where cr.Distraction_Re = inf.Distraction_Re 
AND inf.Distraction_Re = "Y"
MERGE (cr)-[:RELATED_TO]->(inf);
////////////////////
MATCH (cr:Crashes), (inf:InF_Factor) where cr.Alcohol_Re = inf.Alcohol_Re
AND inf.Alcohol_Re = "Y"
MERGE (cr)-[:RELATED_TO]->(inf);
//////////////////
MATCH (cr:Crashes), (inf:InF_Factor) where cr.Weather_Condition = inf.Weather_Co
MERGE (cr)-[:RELATED_TO]->(inf);
//////////////////
MATCH (cr:Crashes), (sf:Severity_Factor) where cr.Injuries > 0
AND sf.Name = "Injuries"
MERGE (cr)-[:HAS{Injuries:cr.Injuries}]->(sf);
/////////////////

///// Add sequences to the crash nodes for the "NEXT"  edges to be created
load csv with headers from
'file:///Crashes_Whole_Edited.csv' as cr
MERGE (r:Crashes {CrashID: cr.FID}) ON CREATE SET
r.Sequence = toInteger(cr.sequence);

//////////////// Create the "NEXT" edges between crashes
MATCH (cr1:Crashes),(cr2:Crashes)
WHERE cr1.Sequence = cr2.Sequence+1 
MERGE (cr1)-[:NEXT]->(cr2);
/////

MATCH (cr1:Crashes),(cr2:Crashes), (ss:Streets), (ss1:Streets)
WHERE cr1.Sequence = cr2.Sequence+1 
AND cr1.StreetName = ss.StreetName 
AND cr2.StreetName = ss1.StreetName
MERGE (ss)-[:NEXT]->(ss1)

/////////////////////
CALL apoc.periodic.iterate(
"MATCH (cr1:Crashes),(cr2:Crashes), (ss:Intersections), (ss1:Intersections)
WHERE cr2.Sequence = cr1.Sequence+1 
AND cr1.IntName = ss.IntersectionName
AND cr2.IntName = ss1.IntersectionName
RETURN ss, ss1",
"MERGE (ss)-[:NEXT]->(ss1)",{batchSize:1000, parallel:true})
////////////////////
CALL apoc.periodic.iterate(
"MATCH (cr1:Crashes),(cr2:Crashes), (ss:Streets), (ss1:Intersections)
WHERE cr2.Sequence = cr1.Sequence+1 
AND cr1.StreetName = ss.StreetName
AND cr2.IntName = ss1.IntersectionName
RETURN ss, ss1",
"MERGE (ss1)-[:NEXT]->(ss)",{batchSize:1000, parallel:true})

////////////////
CALL apoc.periodic.iterate(
"MATCH (cr1:Crashes),(cr2:Crashes), (ss:Streets), (ss1:Intersections)
WHERE cr2.Sequence = cr1.Sequence+1 
AND cr1.StreetName = ss.StreetName
AND cr2.IntName = ss1.IntersectionName
RETURN ss, ss1",
"MERGE (ss)-[:NEXT]->(ss1)",{batchSize:1000, parallel:true})
/////////////
CALL apoc.periodic.iterate(
"MATCH (cr1:Crashes),(cr2:Crashes)
WHERE cr1.Sequence = cr2.Sequence+1 
RETURN cr1, cr2",
 "MERGE (cr2)-[:NEXT]->(cr1)", {batchSize:1000, parallel:true})


/////////////// Connect with infs
MATCH (cr:Crashes), (inf:InF_Factor) where cr.Weather_Condition = inf.Name
MERGE (cr)-[:RELATED_TO]->(inf);
////////////
MATCH (cr:Crashes), (inf:InF_Factor) where cr.Alcohol_Re = "Y" 
AND inf.Name = "Alcohol"
MERGE (cr)-[:RELATED_TO]->(inf);
////////////




