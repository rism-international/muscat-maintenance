/*
CREATE OR REPLACE VIEW person_authorities_links as 
(SELECT ID, 'VIAF' as provider, SUBSTR_DELIM(marc_source, '=024  7#$a', '$2VIAF', 1) AS ext_id FROM people WHERE STR_COUNT(marc_source, '$2VIAF')=1)
UNION
(SELECT ID, 'VIAF' as provider, SUBSTR_DELIM(marc_source, '=024  7#$a', '$2VIAF', 2) AS ext_id FROM people WHERE STR_COUNT(marc_source, '$2VIAF')=2)
UNION
(SELECT ID, 'VIAF' as provider, SUBSTR_DELIM(marc_source, '=024  7#$a', '$2VIAF', 3) AS ext_id FROM people WHERE STR_COUNT(marc_source, '$2VIAF')=3)
UNION
(SELECT ID, 'DNB' as provider, SUBSTR_DELIM(marc_source, '=024  7#$a', '$2DNB', 1) AS ext_id FROM people WHERE STR_COUNT(marc_source, '$2DNB')=1)
UNION
(SELECT ID, 'DNB' as provider, SUBSTR_DELIM(marc_source, '=024  7#$a', '$2DNB', 2) AS ext_id FROM people WHERE STR_COUNT(marc_source, '$2DNB')=2)
UNION
(SELECT ID, 'DNB' as provider, SUBSTR_DELIM(marc_source, '=024  7#$a', '$2DNB', 3) AS ext_id FROM people WHERE STR_COUNT(marc_source, '$2DNB')=3)
UNION
(SELECT ID, 'DNB' as provider, SUBSTR_DELIM(marc_source, '=024  7#$a', '$2DNB', 4) AS ext_id FROM people WHERE STR_COUNT(marc_source, '$2DNB')=4);
*/

CREATE OR REPLACE VIEW person_authorities_links as 
  (select id, 'DNB' as provider, substr_delim(marc_source, '=024  7#$a', '$2DNB', 1) as ext_id from people where marc_source like '%$2DNB%' and substr_delim(marc_source, '=024  7#$a', '$2DNB', 1) is NOT NULL)
  union
  (select id, 'DNB' as provider,  substr_delim(marc_source, '=024  7#$a', '$2DNB', 2) as ext_id from people where marc_source like '%$2DNB%' and substr_delim(marc_source, '=024  7#$a', '$2DNB', 2) is not NULL)
  union
 (select id, 'DNB' as provider,  substr_delim(marc_source, '=024  7#$a', '$2DNB', 3) as ext_id from people where marc_source like '%$2DNB%' and substr_delim(marc_source, '=024  7#$a', '$2DNB', 3) is not NULL)
UNION
 (select id, 'DNB' as provider,  substr_delim(marc_source, '=024  7#$a', '$2DNB', 4) as ext_id from people where marc_source like '%$2DNB%' and substr_delim(marc_source, '=024  7#$a', '$2DNB', 4) is not NULL)
UNION
  (select id, 'VIAF' as provider,  substr_delim(marc_source, '=024  7#$a', '$2VIAF', 1) as ext_id from people where marc_source like '%$2VIAF%' and substr_delim(marc_source, '=024  7#$a', '$2VIAF', 1) is NOT NULL)
UNION 
  (select id, 'VIAF' as provider,  substr_delim(marc_source, '=024  7#$a', '$2VIAF', 2) as ext_id from people where marc_source like '%$2VIAF%' and substr_delim(marc_source, '=024  7#$a', '$2VIAF', 2) is NOT NULL);









CREATE OR REPLACE VIEW dnb as 
  (select id, 'DNB' as provider, substr_delim(marc_source, '=024  7#$a', '$2DNB', 1) as ext_id from people where marc_source like '%$2DNB%' and substr_delim(marc_source, '=024  7#$a', '$2DNB', 1) is NOT NULL)
  union
  (select id, 'DNB' as provider,  substr_delim(marc_source, '=024  7#$a', '$2DNB', 2) as ext_id from people where marc_source like '%$2DNB%' and substr_delim(marc_source, '=024  7#$a', '$2DNB', 2) is not NULL)
  union
 (select id, 'DNB' as provider,  substr_delim(marc_source, '=024  7#$a', '$2DNB', 3) as ext_id from people where marc_source like '%$2DNB%' and substr_delim(marc_source, '=024  7#$a', '$2DNB', 3) is not NULL)
UNION
 (select id, 'DNB' as provider,  substr_delim(marc_source, '=024  7#$a', '$2DNB', 4) as ext_id from people where marc_source like '%$2DNB%' and substr_delim(marc_source, '=024  7#$a', '$2DNB', 4) is not NULL);

CREATE OR REPLACE VIEW viaf as
  (select id, 'VIAF' as provider,  substr_delim(marc_source, '=024  7#$a', '$2VIAF', 1) as ext_id from people where marc_source like '%$2VIAF%' and substr_delim(marc_source, '=024  7#$a', '$2VIAF', 1) is NOT NULL)
UNION 
  (select id, 'VIAF' as provider,  substr_delim(marc_source, '=024  7#$a', '$2VIAF', 2) as ext_id from people where marc_source like '%$2VIAF%' and substr_delim(marc_source, '=024  7#$a', '$2VIAF', 2) is NOT NULL);


