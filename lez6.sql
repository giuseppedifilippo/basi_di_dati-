/*dato un titolo ritorna il voto più alto ricevuto*/
CREATE FUNCTION get_movie_top_rating(varchar(200)) RETURNS numeric AS $$
DECLARE
top_rating rating.score%TYPE;
begin
SELECT max(score) INTO top_rating FROM movie INNER JOIN rating ON movie.id = rating.movie 
WHERE trim(lower(official_title)) = trim(lower($1));
RETURN top_rating;
end;
$$ LANGUAGE plpgsql;
/*TRIM rimuove gli spazi prima e dopo */




/*get_movie_ratings dato un titolo di un film da tutti le recensioni*/
CREATE FUNCTION get_movie_ratings(varchar(200)) RETURNS SETOF rating AS $$
DECLARE
a_rating rating%ROWTYPE;
begin
FOR a_rating IN
SELECT rating.* FROM movie INNER JOIN rating ON movie.id = rating.movie
WHERE trim(lower(official_title)) = trim(lower($1)) ORDER BY movie.id
LOOP 
    RETURN NEXT a_rating;
END LOOP;

end;
$$ LANGUAGE plpgsql;

CREATE TYPE movie_top_rating AS (movie_id varchar(10), top_rating numeric);
CREATE FUNCTION get_movie_top_rating_revised(varchar(200)) RETURNS SETOF movie_top_rating AS $$
DECLARE
		top_rating movie_top_rating;
	BEGIN
		FOR top_rating IN SELECT movie.id, max(score) FROM movie INNER JOIN rating ON movie.id = rating.movie WHERE trim(lower(official_title)) = trim(lower($1)) GROUP BY movie.id
		LOOP
			RETURN NEXT top_rating;
		END LOOP;		
	END;	
$$ LANGUAGE plpgsql


/*dato il titolo di un film restituire i generi associati*/
CREATE TYPE movie_genre AS (movie_id varchar(10), genre_genre varchar(20));
CREATE FUNCTION get_movie_genre(varchar(200)) RETURNS SETOF movie_genre AS $$
DECLARE
		generi movie_genre;
	BEGIN
		FOR generi IN SELECT movie.id, genre.genre FROM movie INNER JOIN genre ON movie.id = genre.movie WHERE trim(lower(official_title)) = trim(lower($1)) GROUP BY movie.id
		LOOP
			RETURN NEXT movie_genre;
		END LOOP;		
	END;	
$$ LANGUAGE plpgsql

CREATE FUNCTION get_movie_genre_cursor(varchar(200)) RETURNS SETOF movie_genre AS $$
DECLARE 
    a_genre movie_genre;
    movie_genres CURSOR FOR SELECT genre.* FROM genre INNER JOIN movie 
    ON genre.movie = movie.id WHERE trim(lower(official_title)) = trim(lower($1)) ORDER BY genre.movie, genre.genre;
BEGIN
    OPEN movie_genres;
    LOOP 
    FETCH movie_genres INTO a_genre;
    EXIT WHEN NOT FOUND;

    RETURN NEXT a_genre;
    END LOOP;
    CLOSE movie_genres;
    END;
$$ LANGUAGE plpgsql;


/*get_movie_cast ritorna il cast del film dato il nome del film(solo attori)*/
CREATE VIEW movie_cast AS (SELECT movie, p_role, person.* FROM crew INNER JOIN person ON crew.person = person.id);
CREATE OR REPLACE FUNCTION get_movie_cast(varchar(200)) RETURNS SETOF movie_cast AS $$
DECLARE
    cast CURSOR FOR SELECT * FROM movie_cast INNER JOIN movie ON movie_cast.movie = movie.id 
    WHERE p_role = 'actor' AND trim(lower(official_title)) = trim(lower($1));
    a_cast movie_cast%ROWTYPE;
BEGIN 
OPEN cast;
LOOP 
FETCH cast INTO a_cast;
EXIT WHEN NOT FOUND;
RETURN NEXT a_cast;
END LOOP;
CLOSE cast;
end;
$$ LANGUAGE plpgsql;
        

/*get_movie_card, dato un film restituire la scheda che contiene
titole,anno, durata, paesi di distribuzione e titolo localizzato
INPUT: id del film*/

CREATE OR REPLACE FUNCTION get_movie_card(varchar(10)) RETURNS text AS $$
DECLARE
    m movie%ROWTYPE;
    d_country country.name%TYPE;
    d_date released.released%TYPE;
    d_title released.titol%TYPE;
    card text;
BEGIN
card := '';
SELECT * INTO m FROM movie WHERE trim(lower(id)) = trim(lower($1));
IF FOUND THEN 
card := m.official_title || ' - ' || m.year || '(durata:' || m.length || 'minuti)' || E'\n';
--vedere la funzione extract per mostrare solo l anno del film e non la data intera
FOR d_country, d_date, d_title IN SELECT country.name FROM released INNER JOIN country 
ON released.country = country.iso3 WHERE released.movie = m.id
LOOP
    IF (d_country IS NOT NULL) THEN
    card := card || E'\t' || 'distribuito in ' || d_country;
        IF (d_date IS NOT NULL) THEN
            card := card || 'in data' || d_date;
            END IF;
    END IF;
    ELSE card := 'film non esiste';
    END IF;

RETURN card;
