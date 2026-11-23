CREATE DATABASE IF NOT EXISTS bda_stackexchange;
USE bda_stackexchange;

CREATE EXTERNAL TABLE IF NOT EXISTS posts_source (
    site STRING,
    id BIGINT,
    post_year INT,
    score INT,
    answer_count INT,
    comment_count INT,
    tags STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/tmp/stackexchange/pig_questions';

CREATE TABLE IF NOT EXISTS posts_text (
    site STRING,
    id BIGINT,
    post_year INT,
    score INT,
    answer_count INT,
    comment_count INT,
    tags STRING
)
STORED AS TEXTFILE;

CREATE TABLE IF NOT EXISTS posts_rc (
    site STRING,
    id BIGINT,
    post_year INT,
    score INT,
    answer_count INT,
    comment_count INT,
    tags STRING
)
STORED AS RCFILE;

SET hive.exec.compress.output=true;
SET mapred.output.compress=true;
SET mapred.output.compression.codec=org.apache.hadoop.io.compress.SnappyCodec;

INSERT OVERWRITE TABLE posts_text
SELECT site, id, post_year, score, answer_count, comment_count, tags
FROM posts_source;

INSERT OVERWRITE TABLE posts_rc
SELECT site, id, post_year, score, answer_count, comment_count, tags
FROM posts_source;
