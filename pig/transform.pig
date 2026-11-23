-- Clean and filter the structured post fields that feed the Hive comparison.
raw_posts = LOAD '$INPUT'
    USING PigStorage('\t')
    AS (
        site:chararray,
        id:long,
        post_type_id:int,
        creation_date:chararray,
        post_year:int,
        score:int,
        view_count:long,
        answer_count:int,
        comment_count:int,
        tags:chararray,
        title:chararray
    );

valid_posts = FILTER raw_posts BY id IS NOT NULL AND post_year IS NOT NULL AND site IS NOT NULL;
questions = FILTER valid_posts BY post_type_id == 1;
clean_questions = FOREACH questions GENERATE
    site,
    id,
    post_year,
    (score IS NULL ? 0 : score) AS score,
    (answer_count IS NULL ? 0 : answer_count) AS answer_count,
    (comment_count IS NULL ? 0 : comment_count) AS comment_count,
    tags;
STORE clean_questions INTO '$OUTPUT' USING PigStorage('\t');
