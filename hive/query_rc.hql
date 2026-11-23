USE bda_stackexchange;
SELECT post_year,
       COUNT(*) AS question_count,
       AVG(score) AS mean_score,
       SUM(answer_count) AS answers_reported
FROM posts_rc
WHERE post_year BETWEEN 2015 AND 2024
GROUP BY post_year
ORDER BY post_year;
