//Introducing unique constraints on the id of the major nodes of the graph model

CREATE CONSTRAINT ON (ph:Physician) ASSERT ph.PhysicianID is unique;
CREATE CONSTRAINT ON (pr:Procedure) ASSERT pr.ProcedureID is unique;
CREATE CONSTRAINT ON (sp:Specialty) ASSERT sp.SpecialtyID is unique;

// Loading the Physician csv file
Load csv WITH headers from 'file:///physicians.csv' as csv 
MERGE (ph:Physician {PhysicianID: csv.id}) ON CREATE SET
ph.Specialty = csv.specialty;

// Loading the Procedure csv file
USING PERIODIC COMMIT 10000
Load csv WITH headers from 'file:///Procedure.csv' as csv 
MERGE (pr:Procedure {ProcedureID: csv.id}) ON CREATE SET
pr.PhysicianID= csv.physician_id, pr.Detail = csv.procedure, pr.Code = csv.procedure_code,
pr.Num_Patient = toInt(csv.number_of_patients);

// load the Specialty csv file, this file was created from the Physician file from an initial data wrangling process
Load csv WITH headers from 'file:///Specialty.csv' as csv 
MERGE (sp:Specialty {SpecialtyID: csv.id}) ON CREATE SET
sp.Name = csv.name;

// Creating Indexes on some node properties that would be used for pattern matching
CREATE INDEX ON :Procedure(Detail);
CREATE INDEX ON :Specialty(Name);
CREATE INDEX ON :Physician(Specialty);

// Adding Specialty context to the procedure nodes. 
// "Most frequent words" for the specialties were generated from 
// data wrangling exercise on a merged table from Physician and Procedure table
MATCH (pr: Procedure)
WHERE pr.Detail CONTAINS "heart" // "Most frequent word for Cardiology"
SET pr.Specialty = "Cardiology";

// creating index on the just added specialty property of the procedure node
CREATE INDEX ON :Procedure(Specialty);

//Create relationship betwwen the physician and the procedure nodes
MATCH (ph:Physician), (pr:Procedure)
WHERE ph.PhysicianID = pr.PhysicianID
CREATE (ph)<-[:PERFORMED_BY]-(pr);

//Create relationship betwwen the physician and the specialty nodes
MATCH (ph:Physician),(sp:Specialty)
WHERE ph.Specialty = sp.Name
CREATE (ph)-[:SPECIALISES_IN]->(sp);

//Create relationship betwwen the procedure and the specialty nodes
MATCH (pr:Procedure),(sp:Specialty)
WHERE pr.Specialty = sp.Name
CREATE (pr)-[:BELONGS_TO]->(sp);

//QUERIES

//A simple to retrieve the number of physicians whose specialities are unknown that are likely to be Cardiologist.

MATCH (pr: Procedure)-[r:PERFORMED_BY]->(ph:Physician)
WHERE pr.Specialty = "Cardiology"
AND ph.Specialty = "Unknown"
RETURN Count(distinct ph);

//Result [3879] 
// That is 3879 physicians from the "Unknowns" are Cardiologist

//.............................................................................................

// A graph clustering algorithm, for example, Louvain algorithm (unsupervised) can 
// be used to classify all the physicians to their respective specialties including the "unknown" ones
// based on this graph model.

// A sample Cypher encoded Louvain algorithm to do that based on this model
CALL algo.louvain.stream(
'MATCH (ph:Physician) RETURN id(ph) as id',
'MATCH (ph:Physician)-[:SPECIALISES_IN]->(sp:Specialty)<-[:BELONGS_TO]-(pr:Procedure)
RETURN id(pr) as source, id(ph) as target', 
{graph:'cypher'})
YIELD nodeId, community
MATCH (ph:Physician) WHERE id(ph) = nodeId
RETURN community, count(*) as communitysize, collect(ph.Specialty) as members
ORDER by communitysize DESC limit 5;


