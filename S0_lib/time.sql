-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('time.sql', '$Id');

-- support for times and dates
-- support for intervals and ranges of times and dates
-- support for time travel
-- Lynn Dobbs and Greg Davidson

-- Review where we're allowing NULLs !!

CREATE DOMAIN event_times AS timestamp with time zone NOT NULL;
CREATE DOMAIN maybe_event_times AS timestamp with time zone;

CREATE OR REPLACE
FUNCTION event_time() RETURNS event_times AS $$
	SELECT now()::event_times
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION time_text(event_times) RETURNS text AS $$
	SELECT to_char($1, 'HH12:MI DD Mon YYYY')
$$ LANGUAGE sql;

CREATE TABLE IF NOT EXISTS time_ranges (
	starting event_times NOT NULL DEFAULT current_date::timestamp,
	ending event_times NOT NULL DEFAULT 'infinity'
);
COMMENT ON TABLE time_ranges IS
'Inherit this to support time-travel. Please note that time travel
introduces new integrity concerns.  Do not update time_ranges
lightly!';
COMMENT ON COLUMN time_ranges.ending IS
'We anticipate expiring derived tables by updating ending to the
expiry time.  This is dangerous if records exist based on a future
computed from the old range.  Suggestions: (1) Prohibit the update
except when the old value is infinity or is earlier than the new value
(i.e. we are extending the range) and (2) prohibit any exploration of
a future where ending is infinity.';

SELECT declare_abstract('time_ranges');

CREATE OR REPLACE
FUNCTION time_range_start() RETURNS event_times AS $$
	SELECT event_time()
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION time_range_start(event_times) RETURNS event_times AS $$
	SELECT COALESCE($1, time_range_start())
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION time_range_start(time_ranges) RETURNS event_times AS $$
	SELECT time_range_start( ($1).starting )
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION time_range_end() RETURNS event_times AS $$
	SELECT 'infinity'::event_times
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION time_range_end(event_times) RETURNS event_times AS $$
	SELECT COALESCE($1, time_range_end())
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION time_range_end(time_ranges) RETURNS event_times AS $$
	SELECT time_range_end( ($1).ending )
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION time_range(event_times, event_times) RETURNS time_ranges AS $$
	SELECT ( $1, $2 )::time_ranges
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION time_range(event_times) RETURNS time_ranges AS $$
	SELECT time_range( $1, time_range_end() )
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION time_range() RETURNS time_ranges AS $$
	SELECT time_range( time_range_start() )
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION is_current(event_times, event_times, event_times) RETURNS boolean AS $$
	SELECT $1 <= the_time AND the_time < $2
	FROM COALESCE($3, event_time()) the_time
$$ LANGUAGE sql;
COMMENT ON FUNCTION is_current(event_times, event_times, event_times)
IS '(starting, ending, sometime) --> is sometime between starting and ending?';

CREATE OR REPLACE
FUNCTION is_current(event_times, event_times) RETURNS boolean AS $$
	SELECT is_current( $1, $2, event_time() )
$$ LANGUAGE sql;
COMMENT ON FUNCTION is_current(event_times, event_times)
IS '(starting, ending) --> is the current time between starting and ending?';

CREATE OR REPLACE
FUNCTION is_current(time_ranges, event_times) RETURNS boolean AS $$
	SELECT is_current( time_range_start($1),  time_range_end($1), $2 )
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION is_current(time_ranges) RETURNS boolean AS $$
	SELECT is_current( $1, event_time() )
$$ LANGUAGE sql;


