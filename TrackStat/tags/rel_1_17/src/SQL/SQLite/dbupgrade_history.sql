CREATE TABLE track_history (
  id integer primary key autoincrement,
  url varchar NOT NULL,
  musicbrainz_id varchar,  -- musicbrainz uuid (36 bytes of text)
  played integer,
  rating integer
);

