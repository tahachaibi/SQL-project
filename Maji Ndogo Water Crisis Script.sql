Data Analysis Code

use md_water_services

/*
 list of all the tables in the database. 
 */

show tables


 -- Dive into the water sources

	/* looking at the water sources table */

	select 
		*
	FROM
		water_source
	
	/* the unique types of water sources. */

	select 
		DISTINCT type_of_water_source 
	FROM
		water_source
		
-- Unpack the visits to water sources
	
	/* looking at the visits table */
		
	select 
		*
	FROM
		visits 
		
	/* records with a big time in queue */

	SELECT 
		*
	FROM 
		visits 
	WHERE 
		time_in_queue >= 500 
	
	/* Looking for what type of water sources take this long to queue for. */
		
	SELECT 
		DISTINCT water_source.type_of_water_source 
	FROM 
		visits 
		join water_source
		on visits.source_id = water_source.source_id 
	WHERE 
		time_in_queue >= 500 
		
-- Assess the quality of water sources
		
	/* looking at the water quality table */
	
	SELECT 
		*
	FROM 
		water_quality 
		
	/* checking if surveyors only made multiple visits to shared taps and did not revisit other types of water sources. */
		
	SELECT 
		type_of_water_source,	
		water_quality.subjective_quality_score ,
		water_quality.visit_count
	FROM 
		water_quality 
		join visits 
			on water_quality.record_id = visits.record_id 
		join water_source 
			on water_source.source_id = visits.source_id 
	where
		subjective_quality_score = 10
		and water_quality.visit_count = 2
		
-- Investigate pollution issues 
	
	/* looking at the well pollution table */
    
    select 
		*
	from
		well_pollution
		
	/* checking if the results is Clean but the biological column is > 0.01 */
    
    select 
		*
    from
		well_pollution
	where
		results = 'clean' and biological > 0.01 
    
	/* identify the records that mistakenly have the word Clean in the description */ 
	
    select 
		*
    from
		well_pollution
	where
		results = 'clean' and biological > 0.01  and description like '%clean%'
    
    /* fix these descriptions so that we don’t encounter this issue again */
		-- first case
			update 
				well_pollution 
			set 
				description = 'Bacteria: Giardia Lamblia' 
			where 
				description = 'Clean Bacteria: Giardia Lamblia'
        
        -- second case
        
			update 
				well_pollution 
			set 
				results = 'Contaminated: Biological'
			where 
				biological > 0.01 and results = 'Clean'
        
        -- third case
    
			update 
				well_pollution 
			set 
				description = 'Clean Bacteria: E. coli'
			where 
				description = 'Bacteria: E. coli'
    
-- Clustering the data 
    /* looking at the employee table */
    
    select 
		*
	from
		employee
        
	/* the email addresses have not been added */
    /* the emails for our department are : first_name.last_name@ndogowater.gov */
    
    select 
		concat(lower(replace(employee_name, ' ', '.')), '@ndogowater.gov') as new_email_adress
	from
		employee
        
	/* update the emails column in the employee table */ 
    
    update 
		employee
	set
		email = concat(lower(replace(employee_name, ' ', '.')), '@ndogowater.gov')
    
    /* looking at the lenght of phone numbers */
	
    select
		length(phone_number)
	from
		employee
        
	/* updating the length of the phone number column in the employee table because it should be just 12 not 13*/

 UPDATE employee 
	set phone_number = trim(phone_number)

/* count how many of our employees live in each town */

select 
	town_name, COUNT(employee_name) as num_employees
from 
	employee
group by 
	town_name 
order by 
	num_employees
    
/* looking at the number of records each employee collected */

select
	assigned_employee_id,
	count(visit_count) as num_of_visits
from
	visits 
group by
	assigned_employee_id
order by
	num_of_visits desc

/* select the top three employees to honor them */
select 
	employee_name, 
    phone_number, 
    email
from 
	employee join (select assigned_employee_id, count(visit_count)
	from 
		visits
	group by 
		assigned_employee_id
	order by 
		count(visit_count) desc
	limit 3) as top_employees
on employee.assigned_employee_id = top_employees.assigned_employee_id


-- Analysing locations
	/* Number of records per town */

	 select 
		 town_name, 
		 count(*) as records_per_town
	from 
		location
	group by 
		town_name 
	order by 
		records_per_town desc;


	/* Number of records per province */

	select 
		province_name, 
			count(*) as records_per_province
	from 
		location
	group by 
		province_name 
	order by 
		records_per_province desc;

	/* showing recors per province and town */
	select 
		province_name, 
		town_name, 
		count(*) as records_per_town
	from 
		location
	group by 
		province_name, 
		town_name 
	order by 
		province_name, 
		records_per_town desc
        
	/* the number of records for each location type */

	select 
		location_type, 
        count(*) as records_per_location
	from 
		location
	group by 
		location_type 
	order by 
		records_per_location desc
        
-- Diving into the sources
	/* Number of people we survey in total */
    
    select
		type_of_water_source,
        sum(number_of_people_served) as total_served_ppl
	from
		water_source
	group by
		type_of_water_source
        
	/* the number of wells, taps and rivers */
    
    select
		type_of_water_source,
        count(type_of_water_source) as number_of_types_of_water
	from
		water_source
	group by
		type_of_water_source

	/* average number of people share particular types of water sources */
    
    select
		type_of_water_source,
        round(avg(number_of_people_served), 0) as avg_ppl_share_water_sources
	from
		water_source
	group by
		type_of_water_source
    
    
    
    
	/* The pourcentage of people getting water from each type of source*/ 
	
    select 
		type_of_water_source, 
			round((sum(number_of_people_served)/(select sum(number_of_people_served)from water_source) * 100), 0) as pct_of_served_ppl
	from 
		water_source
	group by 
		type_of_water_source
	order by 
		pct_of_served_ppl desc
        
-- Start of a solution

	/* Finding the most affected people to fix their infrastracture first */

	select 
		type_of_water_source,
		sum(number_of_people_served) as served_ppl,
		ROW_NUMBER () over (order by sum(number_of_people_served) DESC ) as rank_by_pop
	FROM 
		water_source
	group by 
		type_of_water_source

	/* Finding the most used sources to fixe them first */
    
	select 
		distinct(source_id),
		type_of_water_source,
		sum(number_of_people_served) as served_ppl,
		DENSE_RANK () over (partition by type_of_water_source order by sum(number_of_people_served) DESC ) as priority_rank
	FROM 
		water_source
	group by 
		source_id,
		type_of_water_source

-- Analysing queues

	/* How long the survey took */ 

	SELECT 
		MAX(time_of_record) AS last_date,
		MIN(time_of_record) AS first_date,
		TIMESTAMPDIFF(DAY, MIN(time_of_record), MAX(time_of_record)) AS survey_duration_in_days
	FROM visits

	/* the average total queue time for water */
    
	SELECT 
		ROUND( AVG (NULLIF(time_in_queue, 0)), 0) AS average_queue_time
	FROM 
		visits

	/* the average queue time on different days */

	select 
		DAYNAME(time_of_record),
		ROUND(avg(time_in_queue), 0) 
	FROM 
		visits
	group by
		DAYNAME(time_of_record)

	/* The time during the day people collect water */ 
    
	select 
		TIME_FORMAT (time (time_of_record), '%H:00') as hour_of_day,
		ROUND(avg(time_in_queue), 0) as avg_queue_time 
	from
		visits
	group by 
		hour_of_day
	order by
		hour_of_day ASC 

	/* breaking down the queue times for each hour of each day */
    
	select 
		TIME_FORMAT (time (time_of_record), '%H:00') as hour_of_day,
		round(avg(
			CASE 
				when DAYNAME (time_of_record) = 'sunday' then time_in_queue
				else null
			END ), 0) as Sunday,
		round(avg(
			CASE 
				when DAYNAME (time_of_record) = 'Monday' then time_in_queue
				else null
			END), 0) as Monday,
		round(avg(
			CASE 
				when DAYNAME (time_of_record) = 'Tuesday' then time_in_queue
				else null
			END), 0) as Tuesday,
		round(avg(
			CASE 
				when DAYNAME (time_of_record) = 'Wednesday' then time_in_queue
				else null
			END), 0) as Wednesday,
		round(avg(
			CASE 
				when DAYNAME (time_of_record) = 'Thursday' then time_in_queue
				else null
			END), 0) as Thursday,
		round(avg(
			CASE 
				when DAYNAME (time_of_record) = 'Friday' then time_in_queue
				else null
			END), 0) as Friday,
		round(avg(
			CASE 
				when DAYNAME (time_of_record) = 'Saturday' then time_in_queue
				else null
			END), 0) as Saturday
	from
		visits
	WHERE 
		time_in_queue != 0
	GROUP BY
		hour_of_day
	ORDER BY
		hour_of_day
        
        
-- importing the auditor report table -- 
-- this is an independent team that were tasked with conducting an independent audit of the Maji Ndogo water project specifically the database recording water sources in the country --
	
    
	DROP TABLE IF EXISTS 
		`auditor_report`;
	CREATE TABLE `auditor_report` (
		`location_id` VARCHAR(32),
		`type_of_water_source` VARCHAR(64),
		`true_water_source_score` int DEFAULT NULL,
		`statements` VARCHAR(255)
		);
        
	/* looking at the auditor's table */ 
    
    select
		*
	from
		auditor_report
	

	/*	comparing the quality scores in the water_quality table to the auditor's scores */
    
	SELECT 
		ar.location_id ,
		v.record_id,
		v.assigned_employee_id,
		ar.true_water_source_score as auditor_score,
		wq.subjective_quality_score as employee_score 
	from
		auditor_report ar
	join 
		visits v 
		on
		v.location_id = ar.location_id 
	JOIN 
		water_quality wq 
		on
		wq.record_id = v.record_id
     
    /* checking if the auditor's and employees' scores agree */
        
    SELECT 
		ar.location_id ,
		v.record_id,
		v.assigned_employee_id,
		e.employee_name,
		ar.true_water_source_score as auditor_score,
		wq.subjective_quality_score as employee_score 
	from
		auditor_report ar
	join 
		visits v 
		on
		v.location_id = ar.location_id 
	JOIN 
		water_quality wq 
		on
		wq.record_id = v.record_id 
	JOIN 
		employee e 
		on
		e.assigned_employee_id = v.assigned_employee_id 
	where
		ar.true_water_source_score = wq.subjective_quality_score 
        and v.visit_count = 1
    
	/* the records where the auditors' and the employees' disagree */
    
    SELECT 
		ar.location_id ,
		v.record_id,
		v.assigned_employee_id,
		e.employee_name,
		ar.true_water_source_score as auditor_score,
		wq.subjective_quality_score as employee_score 
	from
		auditor_report ar
	join 
		visits v 
		on
		v.location_id = ar.location_id 
	JOIN 
		water_quality wq 
		on
		wq.record_id = v.record_id 
	JOIN 
		employee e 
		on
		e.assigned_employee_id = v.assigned_employee_id 
	where
		ar.true_water_source_score <> wq.subjective_quality_score 
        and v.visit_count = 1
	
    /* creating a view of error records */ 
    
    CREATE view incorrect_records as
			(SELECT 
				ar.location_id ,
				v.record_id,
				v.assigned_employee_id,
				e.employee_name,
				ar.true_water_source_score as auditor_score,
				wq.subjective_quality_score as employee_score,
                ar.statements AS statements
			from
				auditor_report ar
			join 
				visits v 
				on
				v.location_id = ar.location_id 
			JOIN 
				water_quality wq 
				on
				wq.record_id = v.record_id 
			JOIN 
				employee e 
				on
				e.assigned_employee_id = v.assigned_employee_id 
			where
				ar.true_water_source_score <> wq.subjective_quality_score and v.visit_count = 1)

/* Number of mistakes per employee  */
		
        SELECT 
			employee_name, 
			COUNT(employee_name) number_of_mistakes
		from 
			incorrect_records ir 
		group by
			employee_name

/* the employees who made more than the average of mistakes */ 

	with 
		suspect_list as
			(SELECT 
				employee_name, 
				COUNT(employee_name) number_of_mistakes
			from 
				incorrect_records ir 
			group by
				employee_name)
		SELECT 
			employee_name,
			number_of_mistakes
		from
			error_count
		WHERE 
			number_of_mistakes > (select 
			AVG(number_of_mistakes)
		from error_count )
        
	/* Checking if there are any employees in the Incorrect_records table with statements mentioning "cash" */

	WITH error_count AS (
		SELECT
			employee_name,
			COUNT(employee_name) AS number_of_mistakes
		FROM
			Incorrect_records
	GROUP BY
		employee_name),
		suspect_list AS (
		SELECT
			employee_name,
			number_of_mistakes
		FROM
			error_count
		WHERE
			number_of_mistakes > (SELECT AVG(number_of_mistakes) FROM error_count))
		SELECT
			employee_name,
			location_id,
			statements
		FROM
			Incorrect_records
		WHERE
			employee_name in (SELECT employee_name FROM suspect_list) 
			and statements like '%cash%'


	/* pulling all the important informations in one table */

	CREATE view combined_analysis_table
		as (
			SELECT 	
				l.province_name,
				l.town_name,
				ws.type_of_water_source,
				l.location_type,
				ws.number_of_people_served, 
				v.time_in_queue,
				wp.results 
			FROM 
					visits v 
				LEFT JOIN
					well_pollution wp
				ON 
					wp.source_id = v.source_id
				join
					location l 
				on 
					l.location_id = v.location_id 
				JOIN 
					water_source ws 
				on
					ws.source_id = v.source_id 
			WHERE 
				v.visit_count = 1
			)

	/* breaking down our data into provinces and source types to understand where the problems are, and what we need to improve at those locations */

	with province_totals 
		as 
			(
			SELECT 
				province_name,
				SUM(number_of_people_served) total_served_ppl
			from
				combined_analysis_table
			group by
				province_name 
			)
		SELECT 
			cat.province_name,
			round(sum(CASE 
				when cat.type_of_water_source = 'river' THEN number_of_people_served else 0 end) / total_served_ppl * 100) as river,
			round(sum(CASE 
				when cat.type_of_water_source = 'well' THEN number_of_people_served else 0 end) / total_served_ppl * 100) as well,
			round(sum(CASE 
				when cat.type_of_water_source = 'shared_tap' THEN number_of_people_served else 0 end) / total_served_ppl * 100) as shared_tap,
			round(sum(CASE 
				when cat.type_of_water_source = 'tap_in_home' THEN number_of_people_served else 0 end) / total_served_ppl * 100) as tap_in_home,
			round(sum(CASE 
				when cat.type_of_water_source = 'tap_in_home_broken' THEN number_of_people_served else 0 end) / total_served_ppl * 100) as tap_in_home_broken
		from
			combined_analysis_table cat
		join
			province_totals pt
			on 
				pt.province_name = cat.province_name 
		group by 
			cat.province_name 

	/* breaking down our data into provinces, towns and source types to understand where the problems are, and what we need to improve at those locations */

	create view town_aggregated_water_access as
		(
		with province_totals 
			as 
				(
				SELECT 
					province_name,
					town_name, 
					SUM(number_of_people_served) total_served_ppl
				from
					combined_analysis_table
				group by
					province_name,
					town_name 
				)
			SELECT 
				cat.province_name,
				cat.town_name, 
				round(sum(CASE 
					when cat.type_of_water_source = 'river' THEN number_of_people_served else 0 end) / total_served_ppl * 100) as river,
				round(sum(CASE 
					when cat.type_of_water_source = 'well' THEN number_of_people_served else 0 end) / total_served_ppl * 100) as well,
				round(sum(CASE 
					when cat.type_of_water_source = 'shared_tap' THEN number_of_people_served else 0 end) / total_served_ppl * 100) as shared_tap,
				round(sum(CASE 
					when cat.type_of_water_source = 'tap_in_home' THEN number_of_people_served else 0 end) / total_served_ppl * 100) as tap_in_home,
				round(sum(CASE 
					when cat.type_of_water_source = 'tap_in_home_broken' THEN number_of_people_served else 0 end) / total_served_ppl * 100) as tap_in_home_broken
			from
				combined_analysis_table cat
			join
				province_totals pt
				on 
					pt.province_name = cat.province_name and pt.town_name = cat.town_name 
			group by 
				cat.province_name,
				cat.town_name 
			)
    /* Finding which town has the highest ratio of people who have taps, but have no running water */        
     
	SELECT
		province_name,
		town_name,
		ROUND(tap_in_home_broken / (tap_in_home_broken + tap_in_home) * 100,0) AS Pct_broken_taps
	FROM
		town_aggregated_water_access
     
/* Summary report

1. Most water sources are rural in Maji Ndogo.
2. 43% of our people are using shared taps. 2000 people often share one tap.
3. 31% of our population has water infrastructure in their homes, but within that group,
4. 45% face non-functional systems due to issues with pipes, pumps, and reservoirs. Towns like Amina, the rural parts of Amanzi, and a couple
of towns across Akatsi and Hawassa have broken infrastructure.
5. 18% of our people are using wells of which, but within that, only 28% are clean. These are mostly in Hawassa, Kilimani and Akatsi.
6. Our citizens often face long wait times for water, averaging more than 120 minutes:
		• Queues are very long on Saturdays.
		• Queues are longer in the mornings and evenings.
		• Wednesdays and Sundays have the shortest queues.
*/

    /* creating a view that filter the data to only contain sources we want to improve */ 
	create view sources_to_improve as (
	SELECT
		l.address,
		l.town_name,
		l.province_name,
		ws.source_id,
		ws.type_of_water_source,
		wp.results
	FROM
		water_source ws
		LEFT JOIN
			well_pollution wp 
		ON 
			ws.source_id = wp.source_id
		INNER JOIN
			visits v 
		ON 
			ws.source_id = v.source_id
		INNER JOIN
			location l 
		ON 
			l.location_id = v.location_id
	WHERE
		v.visit_count = 1 
		AND (
			wp.results != 'Clean'
		OR 
			ws.type_of_water_source IN ('tap_in_home_broken', 'river')
		OR 
			(ws.type_of_water_source = 'shared_tap' AND v.time_in_queue > 30))	
		)
        









