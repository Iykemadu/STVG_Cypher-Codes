
//Cypher code used to build the STVG - Transit Mobility Graph

// We first create the Time-Tree

//Create Time Tree Indexes
CREATE INDEX ON :Year(yearid);
CREATE INDEX ON :Month(monthid);
CREATE INDEX ON :Day(dayid);	
CREATE INDEX ON :Hour(hourid);


// Adding NEXT relationship from the Years to the Hours in 2016

WITH range(2016, 2016) AS YEARS, range(6,12) AS MONTHS,range(1,24) as HOURS
FOREACH(year IN YEARS |
  CREATE (y:Year {yearid: year})
  FOREACH(month IN MONTHS |
    CREATE (m:Month {monthid: month})
    MERGE (y)-[:HAS_MONTH]->(m)
    FOREACH(day IN (CASE
                      WHEN month IN [1,3,5,7,8,10,12] THEN range(1,31)
                      WHEN month = 2 THEN range(1,28)
                      ELSE range(1,30)
                    END) |
      CREATE (d:Day {dayid: day})
      MERGE (m)-[:HAS_DAY]->(d)
       FOREACH(hour in HOURS | CREATE (h:Hour {hourid:hour})
        MERGE (h)<-[:HAS_HOUR]-(d)))));
         ////////////////////////////////////

//We do the same as above for 2017

WITH range(2017, 2017) AS YEARS, range(1,12) AS MONTHS, range(1,24) as HOURS
FOREACH(year IN YEARS |
  CREATE (y:Year {yearid: year})
  FOREACH(month IN MONTHS |
    CREATE (m:Month {monthid: month})
    MERGE (y)-[:HAS_MONTH]->(m)
    FOREACH(day IN (CASE
                      WHEN month IN [1,3,5,7,8,10,12] THEN range(1,31)
                      WHEN month = 2 THEN range(1,28)
                      ELSE range(1,30)
                    END) |
      CREATE (d:Day {dayid: day})
      MERGE (m)-[:HAS_DAY]->(d)
      FOREACH(hour in HOURS | CREATE (h:Hour {hourid:hour})
        MERGE (h)<-[:HAS_HOUR]-(d)))));
         

// We then extend the time Time-tree to minutes and seconds granularity.

//CREATE minutes
MATCH (h:Hour) WITH range(1,60) as MINUTES, h
FOREACH (minute in MINUTES | CREATE (mm:Minute {muniteid:minute})
  MERGE (mm)<-[:HAS_MINUTE]-(h));

//CREATE SECONDS
MATCH (h:Hour)-[:HAS_MINUTE]->(mm: Minute) WITH h, mm, range(1,60) as SECONDS
FOREACH (second in SECONDS | CREATE (ss:Second {secondid:second})
MERGE (ss)<-[:HAS_SECOND]-(mm));

//Sequential 

//Connect Years Sequentially
MATCH (year:Year)
WITH year
ORDER BY year.yearid
WITH collect(year) AS years
FOREACH(i in RANGE(0, length(years)-2) |
    FOREACH(year1 in [years[i]] |
        FOREACH(year2 in [years[i+1]] |
            CREATE UNIQUE (year1)-[:NEXT_YEAR]->(year2))));



//Connect Months Sequentially
MATCH (year:Year)-[:HAS_MONTH]->(month:Month)
WITH year, month
ORDER BY year.yearid, month.monthid
WITH collect(month) AS months
FOREACH(i in RANGE(0, length(months)-2) |
    FOREACH(month1 in [months[i]] |
        FOREACH(month2 in [months[i+1]] |
            CREATE UNIQUE (month1)-[:NEXT_MONTH]->(month2))));


//Connect Days Sequentially
MATCH (year:Year)-[:HAS_MONTH]->(month:Month)-[:HAS_DAY]->(day:Day)
WITH year, month, day
ORDER BY year.yearid, month.monthid, day.dayid
WITH collect(day) AS days
FOREACH(i in RANGE(0, length(days)-2) |
    FOREACH(day1 in [days[i]] |
        FOREACH(day2 in [days[i+1]] |
            CREATE UNIQUE (day1)-[:NEXT_DAY]->(day2))));

///////////////////////////////// Hours

MATCH (year:Year)-[:HAS_MONTH]->(month:Month)-[:HAS_DAY]->(day:Day)-[:HAS_HOUR]->(hour:Hour)
WITH year, month, day, hour
ORDER BY year.yearid, month.monthid, day.dayid, hour.hourid
WITH collect(hour) AS hours
FOREACH(i in RANGE(0, length(hours)-2) |
    FOREACH(hour1 in [hours[i]] |
        FOREACH(hour2 in [hours[i+1]] |
            CREATE UNIQUE (hour1)-[:NEXT_HOUR]->(hour2))));



// =========================================================== ADDING THE SPACE DIMENSION NODES
		
//Create the constrains
create constraint on (r:Line) assert r.LineID is unique;
create constraint on (t:Trips) assert t.TripID is unique;
create constraint on (c:Calendar) assert c.cal_serviceID is unique;
create constraint on (bs:BusStop) assert s.BusStopID is unique;
create constraint on (o:Origin) assert o.OriginID is unique;
create constraint on (d:Destination) assert d.DestinationID is unique;
create constraint on (m:Moves) assert m.MoveID is unique;
create constraint on (s:Stops) assert s.StopID is unique;
create constraint on (st:Streets) assert st.StreetID is unique;
create constraint on (int:Intersection) assert int.IntersectionID is unique;

// add the  Bus Line nodes

load csv with headers from
'file:///D:/data/routes.csv' as csv
create (r:Line {LineID: csv.route_id, SName: csv.SName, LName: csv.Lname});

// add the Trips (linked by LineId (this info must or present on trips.txt) - this file must be built manually)

load csv with headers from
'file:///D:/data/Trips.csv' as csv 
match (r:Line {LineID: csv.Routeid})
merge (r)<-[:HAS]-(t:Trips {TripID: csv.Trip_fid, TripDesc: csv.Tripid,
    Date: csv.Date, Starttime: csv.Time, LineID:csv.Routeid});

//////////////////////
CREATE INDEX ON :Trips(TripDesc);
/////////////////
USING PERIODIC COMMIT 1000
LOAD CSV WITH HEADERS FROM “file://blabla.csv” AS csvLine
WITH toInt(csvLine.twitterid) as twitterid, csvLine
WHERE twitterid IS NOT NULL
MERGE (u :USER { twitterid: twitterid }) ON CREATE SET
u.seat=toInt(csvLine.seat), u.firstname=csvLine.first name, u.lastname=csvLine.lastname,
 u.party=csvLine.party, u.region=csvLine.region, u.type = csvLine.type
////////////
USING PERIODIC COMMIT 10000
load csv with headers from
'file:///D:/data/Origin.csv' as csv
MERGE (t:Trips {TripDesc: csv.Tripid}) 
MERGE (t)-[:STARTS_AT]->(r:Origin {OriginID: csv.Originid}) ON CREATE SET
r.TripID = csv.Tripid, r.latitude=toFloat(csv.lat), r.longitude=toFloat(csv.long), 
r.Date=csv.Date, r.Time=csv.Time, r.Sequence=toInt(csv.sequence),r.State=csv.state,
 r.Street=csv.Street, r.BusStop=csv.Busstop;
//
load csv with headers from
'file:///D:/data/Origin.csv' as csv
MERGE (r:Origin {OriginID: csv.Originid, TripID: csv.Tripid, latitude: toFloat(csv.lat), longitude: toFloat(csv.long), 
        Date: csv.Date, Time: csv.Time, Sequence: toInt(csv.sequence),State: csv.state, Street: csv.Street, 
        BusStop: csv.Busstop});

//////////////////////
match (o:Origin), (t:Trips) where o.TripID = t.TripDesc
merge (t)-[:STARTS_AT]->(o);

///////////////
load csv with headers from
'file:///D:/data/Destination.csv' as csv
MERGE (t:Trips {TripDesc: csv.Tripid}) 
MERGE (t)-[:ENDS_AT]->(r:Destination {DestinationID: csv.Destinationid}) ON CREATE SET
r.TripID = csv.Tripid, r.latitude=toFloat(csv.lat), r.longitude=toFloat(csv.long), 
r.Date=csv.Date, r.Time=csv.Time, r.Sequence=toInt(csv.sequence),r.State=csv.state, r.Street=csv.Street, r.BusStop=csv.Busstop;
///////////

load csv with headers from
'file:///D:/data/Destination.csv' as csv
MERGE (t:Trips {TripDesc: csv.Tripid})
create (t)-[:ENDS_AT]->(d:Destination {DestinationID: csv.Destinationid, TripID: csv.Tripid, latitude: csv.lat, longitude: csv.long, 
    Date: csv.Date, Time: csv.Time, Sequence: toInt(csv.sequence),State: csv.state, Street: csv.Street, BusStop: csv.Busstop});

//Adding Calendar (depends on the Trip Node)

//load csv with headers from
//'file:///calendar.txt' as csv
//MATCH (t:Trip {service_id: csv.service_id})
//CREATE (t)-[:SCHEDULED_AT]-> (c:Calendar {cal_serviceID:csv.service_id, mon:csv.monday, tue:csv.tuesday, wed:csv.wednesday, thu:csv.thursday, fri:csv.friday, sat:csv.saturday, sun:csv.sunday, startDate: csv.start_date, endDate: csv.end_date});
/////////////////////////////////
//Adding Streets

USING PERIODIC COMMIT 10000
LOAD CSV WITH HEADERS FROM 'file:///D:/data/Streets1.csv' AS line
CREATE (st:Streets {StreetID: line.FID, STName: line.STNAME, STType: line.STTYPE, STNoSpace:line.NOSPACE});

CREATE INDEX ON :Streets(STNoSpace);
CREATE INDEX ON :Streets(STName);

//add the Bus stops (BusStops)

load csv with headers from
'file:///D:/data/BusStop_IsAt_Road.csv' as csv
MATCH (st:Streets{STNoSpace: csv.NoSpace} )
create (st)<-[:IS_AT]-(bs:BusStop{BusStopID: csv.UNIQUEID, SName: csv.Descriptio, latitude: toFloat(csv.lat), sLon: toFloat(csv.long), 
    Street: csv.STNAME});

//Add Households as an attribute of a BusStops

///load csv with headers from
//'file:///Civic_Address_PerStop.csv' as csv
//MATCH (bs:BusStop{BusStopID: csv.UNIQUEID} )
//SET bs.Households = csv.Count;

//add Stops and Moves 
USING PERIODIC COMMIT 10000
load csv with headers from
'file:///D:/data/Stops-2.csv' as csv
merge (s:Stops {StopID: csv.stopid, TripID: csv.Tripid, latitude: toFloat(csv.lat), longitude: toFloat(csv.long), Date: csv.Date, 
    Time: csv.Time, Sequence: toInt(csv.sequence), Busevent: csv.BusEvent, Street: csv.Street, BusStop: csv.Busstop});

//////////////////////////////
load csv with headers from
'file:///D:/data/Stops-1.csv' as csv
MERGE (r:Stops {StopID: csv.stopid}) ON CREATE SET
r.TripID = csv.Tripid, r.latitude=toFloat(csv.lat), r.longitude=toFloat(csv.long), 
r.Date=csv.Date, r.Time=csv.Time, r.Sequence=toInt(csv.sequence),r.State=csv.state, r.Street=csv.Street, r.BusStop=csv.Busstop;
////////////////////

USING PERIODIC COMMIT 10000
load csv with headers from
'file:///D:/data/Moves-1.csv' as csv
merge (m:Moves {MoveID: csv.moveid,TripID: csv.Tripid, 
    latitude: toFloat(csv.lat), longitude: toFloat(csv.long), Date: csv.Date, 
    Time: csv.Time, Sequence: toInt(csv.sequence), Busevent: csv.BusEvent, Street: csv.Street, BusStop: csv.Busstop});


CREATE INDEX ON :Origin(Street);
CREATE INDEX ON :Origin(Sequence);
CREATE INDEX ON :Origin(BusStop);
CREATE INDEX ON :Destination(Street);
CREATE INDEX ON :Destination(Sequence);
CREATE INDEX ON :Destination(BusStop);
CREATE INDEX ON :Moves(Sequence);
CREATE INDEX ON :Stops(Sequence);

CREATE INDEX ON :Stops(Street);
CREATE INDEX ON :Stops(Busevent);
CREATE INDEX ON :Stops(BusStop);

CREATE INDEX ON :Moves(Street);
CREATE INDEX ON :Moves(BusStop);
CREATE INDEX ON :Moves(Busevent);

//creating relationship with the Trip

//match (t:Trip),(st:Stops) where t.tripID = st.tripID
//create (t)-[:COMPOSED_OF]->(st);

//match (t:Trip),(st:Moves) where t.tripID = st.tripID
//create (t)-[:COMPOSED_OF]->(st);

// Create relationship with BusStops
match (bs:BusStop), (st:Stops) where bs.BusStopID = st.BusStop
merge (st)-[:STOPS_AT]->(bs);

//match (st:Stops)-[r:STOPS_AT]->(bs:BusStop)
//where st.ArvDep = 'Arrival'
//set r.Arrivaltime = "Arrivaltime" + ":" + st.time;

//match (st:Stops)-[r:STOPS_AT]->(bs:BusStop)
//where st.ArvDep = 'Departure'
//set r.Departuretime = "Departuretime" + ":" + st.time;

match (ss:Streets), (st:Stops) where ss.STNoSpace = st.Street
merge (st)-[:SUSPENSION_OF_MOVEMENT]->(ss);

match (ss:Streets), (st:Moves) where ss.STNoSpace = st.Street
merge (st)-[:MOVES_ON]->(ss);

match (bs:BusStop), (st:Moves) where bs.BusStopID = st.BusStop
merge (st)-[:DID_NOT_STOP_AT]->(bs);


//Creating the busStop_isAT_Road relationship = Using another file

    

// ===============================


// Sequences of Stops and Moves with Origin and Destination (pay attention in every situation!)

// 


MATCH (st:Stops),(mv:Moves)
WHERE st.TripID = mv.TripID
AND mv.Sequence = st.Sequence+1 
MERGE (mv)-[:NEXT]->(st);

/////////////////////////////////
MATCH (st:Stops),(mv:Moves)
WHERE st.TripID = mv.TripID
AND mv.Sequence = st.Sequence+1
MERGE (st)-[:NEXT]->(mv);

//////////////////////////////////
MATCH (st:Stops),(st1:Stops)
WHERE st.TripID = st1.TripID
AND st.Sequence = st1.Sequence+1 
MERGE (st1)-[:NEXT]->(st);

/////////////////////////////////////////////////

MATCH (mv:Moves),(mv1: Moves)
WHERE mv.TripID = mv1.TripID
AND mv.Sequence = mv1.Sequence+1
MERGE (mv1)-[:NEXT]->(mv);

///////////////////////////////////////   MATCH (mv:Moves)-[r:NEXT]->(mv1: Moves) DELETE r;

MATCH (or:Origin),(mv: Moves)
WHERE mv.TripID = or.TripID
AND mv.Sequence = or.Sequence+1 
MERGE (or)-[:NEXT]->(mv);

//////////////////////////////////////////////

MATCH (or:Origin),(st:Stops)
WHERE st.TripID = or.TripID 
AND st.Sequence = or.Sequence+1 
MERGE (or)-[:NEXT]->(st);

//////////////////////////////////////////
MATCH (dt:Destination),(mv:Moves)
WHERE dt.TripID = mv.TripID
AND dt.Sequence = mv.Sequence+1
MERGE (mv)-[:NEXT]->(dt);

///////////////////////////////////////

MATCH (dt:Destination),(st:Stops)
WHERE dt.TripID = st.TripID
AND dt.Sequence = st.Sequence+1 
MERGE (st)<-[:NEXT]->(dt);

/////////////////////////////////////

//Sequences of places (pay attention in every situation!)
///////////////////////////

MATCH (st:Stops),(mv:Moves), (ss:Streets), (ss1:Streets)
WHERE st.Sequence = mv.Sequence+1
AND st.TripID = mv.TripID
AND st.Street = ss.STNoSpace
AND mv.Street = ss1.STNoSpace
MERGE (ss)-[:NEXT_PLACE]->(ss1);

/////////////////////////////////

MATCH (st:Stops),(mv:Stops), (ss:Streets), (ss1:Streets)
WHERE st.Sequence = mv.Sequence+1
AND st.TripID = mv.TripID
AND st.Street = ss.STNoSpace 
AND mv.Street = ss1.STNoSpace
MERGE (ss)-[:NEXT_PLACE]->(ss1);

////////////////////////////////////
MATCH (st:Moves),(mv:Moves), (ss:Streets), (ss1:Streets)
WHERE st.Sequence = mv.Sequence+1
AND st.TripID = mv.TripID
AND st.Street = ss.STNoSpace 
AND mv.Street = ss1.STNoSpace
MERGE (ss)-[:NEXT_PLACE]->(ss1);
/////////////////////////////////


MATCH (st:Stops),(mv:Stops), (ss:Streets), (ss1:BusStop)
WHERE st.Sequence = mv.Sequence+1
AND st.TripID = mv.TripID
AND st.Street = ss.STNoSpace 
AND mv.BusStop = ss1.BusStopID
MERGE (ss)-[:NEXT_PLACE]->(ss1);
/////////////////////////////////

MATCH (st:Moves),(mv:Moves), (ss:Streets), (ss1:BusStop)
WHERE st.Sequence = mv.Sequence+1
AND st.TripID = mv.TripID
AND st.Street = ss.STNoSpace 
AND mv.BusStop = ss1.BusStopID
MERGE (ss)-[:NEXT_PLACE]->(ss1);

//////////////////////////////////


MATCH (st:Moves),(mv:Stops), (ss:Streets), (ss1:BusStop)
WHERE st.Sequence = mv.Sequence+1
AND st.TripID = mv.TripID
AND st.Street = ss.STNoSpace 
AND mv.BusStop = ss1.BusStopID
MERGE (ss)-[:NEXT_PLACE]->(ss1);

/////////////////////////////////////////////////

MATCH (st:Stops),(mv:Moves), (ss:Streets), (ss1:BusStop)
WHERE st.Sequence = mv.Sequence+1
AND st.TripID = mv.TripID
AND st.Street = ss.STNoSpace 
AND mv.BusStop = ss1.BusStopID
MERGE (ss)-[:NEXT_PLACE]->(ss1);
///////////////////////////////////////


//Adding the hour, min and sec,year, month and day to link to the Time Tree

MERGE (t:Trips)
ON MATCH SET t.year = toInt(substring(t.Date,6,4));
MERGE (t:Trips)
ON MATCH SET t.month = toInt(substring(t.Date,3,2));
MERGE (t:Trips)
ON MATCH SET t.day = toInt(substring(t.Date,0,2));
MERGE (t:Trips)
ON MATCH SET t.hour = toInt(substring(t.Starttime,0,2));


//On Origin, Destination, Moves and Stops
MERGE (or:Origin)
ON MATCH SET or.year = toInt(substring(or.Date,6,4));
MERGE (or:Origin)
ON MATCH SET or.month = toInt(substring(or.Date,3,2));
MERGE (or:Origin)
ON MATCH SET or.day = toInt(substring(or.Date,0,2));
MERGE (or:Origin)
ON MATCH SET or.hour = toInt(substring(or.Time,0,2));
//////
MERGE (dt:Destination)
ON MATCH SET dt.year = toInt(substring(dt.Date,6,4));
MERGE (dt:Destination)
ON MATCH SET dt.month = toInt(substring(dt.Date,3,2));
MERGE (dt:Destination)
ON MATCH SET dt.day = toInt(substring(dt.Date,0,2));
MERGE (dt:Destination)
ON MATCH SET dt.hour = toInt(substring(dt.Time,0,2));
////////

MERGE (mv:Moves)
ON MATCH SET mv.year = toInt(substring(mv.Date,6,4));
MERGE (mv:Moves)
ON MATCH SET mv.month = toInt(substring(mv.Date,3,2));
MERGE (mv:Moves)
ON MATCH SET mv.day = toInt(substring(mv.Date,0,2));
MERGE (mv:Moves)
ON MATCH SET mv.hour = toInt(substring(mv.Time,0,2));
//////////////////////////
MERGE (st:Stops)
ON MATCH SET st.year = toInt(substring(st.Date,6,4));
MERGE (st:Stops)
ON MATCH SET st.month = toInt(substring(st.Date,3,2));
MERGE (st:Stops)
ON MATCH SET st.day = toInt(substring(st.Date,0,2));
MERGE (st:Stops)
ON MATCH SET st.hour = toInt(substring(st.Time,0,2));
//////////////////////////////////////////////////
CREATE INDEX ON :Trips(year);
CREATE INDEX ON :Trips(month);
CREATE INDEX ON :Trips(day);
CREATE INDEX ON :Trips(hour)

CREATE INDEX ON :Origin(year);
CREATE INDEX ON :Origin(month);
CREATE INDEX ON :Origin(day);
CREATE INDEX ON :Origin(hour);


CREATE INDEX ON :Destination(year);
CREATE INDEX ON :Destination(month);
CREATE INDEX ON :Destination(day);
CREATE INDEX ON :Destination(hour);

CREATE INDEX ON :Moves(year);
CREATE INDEX ON :Moves(month);
CREATE INDEX ON :Moves(day);
CREATE INDEX ON :Moves(hour);


CREATE INDEX ON :Stops(year);
CREATE INDEX ON :Stops(month);
CREATE INDEX ON :Stops(day);
CREATE INDEX ON :Stops(hour);



// Connecting to the Time Tree:
//Trip
MATCH (t:Trips) WITH t 
MATCH (hh1:Year {yearid:t.year}) WITH t,hh1
MATCH (hh1)-[r1]->(mm1:Month {monthid:t.month}) WITH t,hh1,mm1
MATCH (mm1)-[r2]->(ss1:Day {dayid:t.day}) WITH t, hh1,mm1,ss1
MATCH (ss1)-[r3]->(hh:Hour {hourid:t.hour}) WITH t, hh1,mm1,ss1,hh
MERGE (t)-[:HAPPENS_AT]->(hh);

//Origin
MATCH (t:Origin) WITH t 
MATCH (yy:Year {yearid:t.year}) WITH t,yy
MATCH (yy)-[r1]->(mm:Month {monthid:t.month}) WITH t,yy,mm
MATCH (mm)-[r2]->(dd:Day {dayid:t.day}) WITH t,yy,mm,dd
MATCH (dd)-[r3]->(hh:Hour {hourid:t.hour}) WITH t,yy,mm,dd, hh
MERGE (t)-[:HAPPENS_AT]->(hh);


//Destination
MATCH (t:Destination) WITH t 
MATCH (yy:Year {yearid:t.year}) WITH t,yy
MATCH (yy)-[r1]->(mm:Month {monthid:t.month}) WITH t,yy,mm
MATCH (mm)-[r2]->(dd:Day {dayid:t.day}) WITH t,yy,mm,dd
MATCH (dd)-[r3]->(hh:Hour {hourid:t.hour}) WITH t,yy,mm,dd, hh
MERGE (t)-[:HAPPENS_AT]->(hh);

//Moves
MATCH (t:Moves) WITH t 
MATCH (yy:Year {yearid:t.year}) WITH t,yy
MATCH (yy)-[r1]->(mm:Month {monthid:t.month}) WITH t,yy,mm
MATCH (mm)-[r2]->(dd:Day {dayid:t.day}) WITH t,yy,mm,dd
MATCH (dd)-[r3]->(hh:Hour {hourid:t.hour}) WITH t,yy,mm,dd, hh
MERGE (t)-[:HAPPENS_AT]->(hh);


//Stops
MATCH (t:Stops) WITH t 
MATCH (yy:Year {yearid:t.year}) WITH t,yy
MATCH (yy)-[r1]->(mm:Month {monthid:t.month}) WITH t,yy,mm
MATCH (mm)-[r2]->(dd:Day {dayid:t.day}) WITH t,yy,mm,dd
MATCH (dd)-[r3]->(hh:Hour {hourid:t.hour}) WITH t,yy,mm,dd, hh
MERGE (t)-[:HAPPENS_AT]->(hh);

// END