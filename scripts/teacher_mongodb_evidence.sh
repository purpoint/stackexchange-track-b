#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
source scripts/project_env.sh
mkdir -p results/teacher_evidence
LOG=results/teacher_evidence/mongodb_execution.txt
exec > >(tee "$LOG") 2>&1
echo "MongoDB Ask Ubuntu execution evidence"
echo "Project: $PWD"
echo "Dataset: data/archives/askubuntu.com.7z"
echo
echo '1) Server ping'
mongosh --quiet --eval 'db.adminCommand({ping:1})'
echo
echo '2) Document count'
mongosh --quiet stackexchange --eval 'db.posts.countDocuments({site:"askubuntu.com"})'
echo
echo '3) Sample document fields'
mongosh --quiet stackexchange --eval 'db.posts.findOne({site:"askubuntu.com"},{_id:0,site:1,id:1,post_type_id:1,post_year:1,score:1})'
echo
echo '4) Indexes'
mongosh --quiet --file mongo/create_indexes.js
echo
echo '5) Yearly question aggregation'
mongosh --quiet stackexchange --eval 'db.posts.aggregate([{$match:{site:"askubuntu.com",post_type_id:1,post_year:{$gte:2015,$lte:2024}}},{$group:{_id:"$post_year",questions:{$sum:1},average_score:{$avg:"$score"}}},{$sort:{_id:1}}]).forEach(printjson)'
echo
echo '6) Popular tags'
mongosh --quiet stackexchange --eval 'db.posts.aggregate([{$match:{site:"askubuntu.com",post_type_id:1}},{$unwind:"$tags"},{$group:{_id:"$tags",count:{$sum:1}}},{$sort:{count:-1}},{$limit:10}]).forEach(printjson)'
echo
echo '7) Collection-scan execution statistics'
mongosh --quiet stackexchange --eval 'const q={site:"askubuntu.com",post_type_id:1,creation_date:{$gte:"2020-01-01T00:00:00.000",$lt:"2021-01-01T00:00:00.000"}}; const s=db.posts.find(q,{_id:0,id:1}).hint({$natural:1}).explain("executionStats").executionStats; printjson({returned:s.nReturned,documentsExamined:s.totalDocsExamined,indexKeysExamined:s.totalKeysExamined,timeMs:s.executionTimeMillis})'
echo
echo '8) Indexed-query execution statistics'
mongosh --quiet stackexchange --eval 'const q={site:"askubuntu.com",post_type_id:1,creation_date:{$gte:"2020-01-01T00:00:00.000",$lt:"2021-01-01T00:00:00.000"}}; const s=db.posts.find(q,{_id:0,id:1}).hint("site_type_created").explain("executionStats").executionStats; printjson({returned:s.nReturned,documentsExamined:s.totalDocsExamined,indexKeysExamined:s.totalKeysExamined,timeMs:s.executionTimeMillis})'
echo
echo 'MongoDB execution completed.'
