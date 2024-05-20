BEGIN
/*SELECT person, d_role FROM location GROUP by person, d_role HAVING count(*) > 1;*/
PERFORM * FROM location WHERE person = NEW.person AND d_role = NEW.d_role; 
IF FOUND THEN 
    RAISE INFO 'persona già presente';
    RETURN NULL;
ELSE
    RETURN NEW;
END IF;
END;


/*si crei un trigger che ricaclcola il valore di score quando si modifica la scala di un rating*/
CREATE FUNCTION scale_update() RETURNS TRIGGER AS $$
BEGIN 
IF (OLD.scale <> NEW.scale) THEN
NEW.score := OLD.score / OLD.SCALE * NEW.scale;
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;



CREATE TRIGGER update_scale_rating BEFORE UPDATE ON rating FOR EACH ROW EXECUTE PROCEDURE scale_update();

/*check_character su aggiunta o inserimento di tuple in crew, elimina eventuali nomi
di personaggio con quelle categorie p_role che non sono actor*/
CREATE FUNCTION check_character() RETURNS TRIGGER AS $$
BEGIN 
IF (NEW.d_role <> 'actor' ) THEN
    NEW.p_role := null;
    END IF;
RETURN NEW;

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER i_u_crew BEFORE INSERT OR UPDATE ON crew FOR EACH ROW EXECUTE PROCEDURE check_character();

/*person_stats costrusice una vista con person_id, given_name e numero di performance per ogni ruolo*/
CREATE TABLE person_stats(
    person integer REFERENCES person(id) ON UPDATE CASCADE ON DELETE CASCADE,
    given_name varchar(100) NOT NULL,
    person_role REFERENCES cre
    performance_number integer,
    PRIMARY KEY(person, person_role)
);
/*tg_op indica il tipo di operazione che scatena il trigger*/
CREATE FUNCTION update_person_stats() RETURNS TRIGGER AS $$
DECLARE
person_id crew.person%TYPE;
p_role crew.p_role%TYPE
num_performance integer
BEGIN
IF (TG_OP = 'DELETE') THEN
    person_id := OLD.person;
    p_role := OLD.p_role;
ELSE IF (TG_OP = 'UPDATE') THEN
     person_id := NEW.person;
    p_role := NEW.p_role;
ELSE
END IF;
num_performance := 0 ;
FOR a_crew IN SELECT * FROM crew WHERE person = person_id AND p_role = p_role
LOOP
num_performance := num_performance + 1 ;
END LOOP;
PERFORM * FROM person_stats  WHERE person = person_id AND p_role = p_role;
IF FOUND THEN
UPDATE person_stats SET performance_number = num_performance WHERE person = person_id AND p_role = p_role;
ELSE 
SELECT given_name INTO given_name FROM person WHERE id = person_id;
INSERT INTO 

CREATE TRIGGER crew_trigger AFTER INSERT OR UPDATE OR DELETE on crew FOR EACH ROW EXECUTE PROCEDURE update_person_stats();

--populate movie score si crei una vista che mostri per ogni film il numero di rating 
--ricevuti e lo score complssico considereando tutti i rating
CREATE TABLE movie_score (
    movie varchar(10) PRIMARY KEY REFERENCES movie(id) ON UPDATE CASCADE ON DELETE CASCADE,
    rating_number integer,
    overall_score numeric
);

CREATE TRIGGER populate_movie_score AFTER INSERT OR UPDATE ON rating FOR EACH ROW EXECUTE PROCEDURE update_ratings();

CREATE FUNCTION update_ratings() RETURNS VOID AS $$

DECLARE 
movie_id movie.id%TYPE;
a_rating rating%ROWTYPE;
score_value rating.score%TYPE;
total_votes rating.votes%TYPE;
total_score rating.%TYPE;
num_rating integer;

BEGIN
FOR movie_id IN SELECT id FROM movie
LOOP
    total_score := 0;
    total_votes := 0;
    num_rating := 0;
    FOR a_rating IN SELECT * FROM rating WHERE movie = movie_id AND scale <> 0
    LOOP 
    total_votes := total_votes + a_rating.votes;
    total_score := total_score + ((a_rating.score / a_rating.scale) * 10) * a_rating.votes;
    num_rating := num_rating + 1;
    END LOOP;
    IF total_votes <> 0 THEN
    score_value := total_score / total_votes;
    ELSE 
        score_value := 0;
    END IF;
    INSERT INTO movie_score(movie, rating_number,score) VALUES (movie_id, num_rating, score_value);
END LOOP;
RETURN;
END;
$$ LANGUAGE plpgsql
