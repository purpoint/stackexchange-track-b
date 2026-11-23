SET default_parallel $REDUCERS;
SET mapreduce.job.reduces $REDUCERS;
SET mapreduce.input.fileinputformat.split.maxsize $SPLIT_MAXSIZE;

questions = LOAD '$INPUT'
    USING PigStorage('\t')
    AS (
        site:chararray,
        id:long,
        post_year:int,
        score:int,
        answer_count:int,
        comment_count:int,
        tags:chararray
    );
questions = FILTER questions BY post_year >= 2015 AND post_year <= 2024;
by_site_year = GROUP questions BY (site, post_year);
summary = FOREACH by_site_year GENERATE
    group.site AS site,
    group.post_year AS post_year,
    COUNT(questions) AS question_count,
    AVG(questions.score) AS mean_score,
    SUM(questions.answer_count) AS answers_reported;
STORE summary INTO '$OUTPUT' USING PigStorage('\t');
