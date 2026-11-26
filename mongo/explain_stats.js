const posts = db.getSiblingDB("stackexchange").posts;
const query = {
  site: "askubuntu.com",
  post_type_id: 1,
  creation_date: {
    $gte: "2020-01-01T00:00:00.000",
    $lt: "2021-01-01T00:00:00.000",
  },
};
const projection = { _id: 0, site: 1, id: 1, post_year: 1, score: 1 };

function findScan(plan) {
  if (!plan) return null;
  if (plan.stage === "COLLSCAN" || plan.stage === "IXSCAN") return plan;
  return findScan(plan.inputStage) ||
    (plan.inputStages || []).map(findScan).find(Boolean) || null;
}

for (const [label, hint] of [
  ["COLLSCAN", { $natural: 1 }],
  ["IXSCAN", "site_type_created"],
]) {
  const result = posts.find(query, projection).hint(hint).explain("executionStats");
  const scan = findScan(result.queryPlanner.winningPlan);
  const stats = result.executionStats;
  print(`${label}: stage=${scan ? scan.stage : "unknown"}, index=${scan && scan.indexName || "none"}, returned=${stats.nReturned}, keys=${stats.totalKeysExamined}, documents=${stats.totalDocsExamined}, time_ms=${stats.executionTimeMillis}`);
}
