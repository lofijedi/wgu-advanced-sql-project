-- B. SQL code that creates the tables

	-- Detailed Table
		CREATE TABLE popularMovies_Detailed (
			rental_id integer,
			movie_title varchar(100),
			movie_type varchar (50),
			store_id integer,
			rental_year varchar
		);

	-- Summary Table
		CREATE TABLE popularMovies_Summary (
			movie_type varchar (50),
			type_count integer,
			store_id integer,
			rental_year varchar
		);

-- C. SQL code that extracts the raw data needed for the detailed report and verify the accuracy. 

	-- Insert Data Detailed
		INSERT INTO popularMovies_Detailed (
			rental_id,
			movie_title,
			movie_type,
			store_id,
			rental_year
		)

		SELECT
			rental.rental_id,
			film.title,
			category.name,
			inventory.store_id,
			public.dateformat(rental.rental_date)
		FROM film
			INNER JOIN inventory ON film.film_id = inventory.film_id
			INNER JOIN rental ON inventory.inventory_id = rental.inventory_id
			INNER JOIN film_category ON film.film_id = film_category.film_id
			INNER JOIN category ON film_category.category_id = category.category_id;

	-- Test for Detailed Table
		SELECT * FROM popularMovies_Detailed;

-- D. Functions that perform transformations identified in part A4.

	-- Function
		CREATE OR REPLACE FUNCTION dateformat(timestamp)
		RETURNS varchar AS $$
		BEGIN
            RETURN to_char($1, 'YYYY');
		END;
		$$
		LANGUAGE plpgsql;

--E. SQL code that creates a trigger on the detailed report that will update the summary table when data is added to the detailed table.

	-- Trigger
		CREATE TRIGGER updateSummary
		AFTER INSERT OR UPDATE
			ON popularMovies_detailed
		EXECUTE PROCEDURE updateSummary();

	-- Trigger Function
		CREATE OR REPLACE FUNCTION updateSummary()
		RETURNS TRIGGER
		AS $$
		BEGIN
			DELETE FROM popularMovies_summary;
			INSERT INTO popularMovies_summary (movie_type, type_count, store_id, rental_year)
			SELECT movie_type, COUNT(movie_type), store_id, rental_year
			FROM popularMovies_detailed
			GROUP BY movie_type, store_id, rental_year;
			RETURN NULL;
		END; $$
		LANGUAGE plpgsql;

-- F. Stored procedure that refreshes both the detailed and summary tables. 

	-- Procedure (Run monthly to maintain report freshness)
		CREATE OR REPLACE PROCEDURE popularMovies_Update()
		AS $$
		BEGIN
			DELETE FROM popularMovies_detailed;
			DELETE FROM popularMovies_summary;
			INSERT INTO popularMovies_detailed (
				rental_id,
				movie_title,
				movie_type,
				store_id,
				rental_year
			)

			SELECT
                rental.rental_id,
				film.title,
				category.name,
				inventory.store_id,
				public.dateformat(rental.rental_date)
			FROM film
				INNER JOIN inventory ON film.film_id = inventory.film_id
				INNER JOIN rental ON inventory.inventory_id = rental.inventory_id
				INNER JOIN film_category ON film.film_id = film_category.film_id
				INNER JOIN category ON film_category.category_id = category.category_id;
			END; $$
			LANGUAGE plpgsql;

-- F1. Run the update monthly to keep this report relevant to the business problem it is trying to solve. To do this, we can use pgAdmin. Within pgAdmin, there is a built-in tool called pgAgent that allows us to we create a job that can be set to run at specific times within a date range.

	-- Run the Update
		CALL popularMovies_Update();

