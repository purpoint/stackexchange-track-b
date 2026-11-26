const posts = db.getSiblingDB("stackexchange").posts;

print("1. MongoDB connection check");
print(`ok=${db.adminCommand({ ping: 1 }).ok}`);

print("2. Stack Exchange Ask Ubuntu subset document count");
print(posts.countDocuments({ site: "askubuntu.com" }));

print("3. One question document");
const sample = posts.findOne(
  { site: "askubuntu.com", post_type_id: 1 },
  { _id: 0, id: 1, post_year: 1, score: 1, answer_count: 1, tags: 1 }
);
printjson(sample);

print("4. Index definitions");
printjson(posts.getIndexes().map(({ name, key }) => ({ name, key })));

print("5. Document counts by post type");
posts.aggregate([
  { $match: { site: "askubuntu.com" } },
  { $group: { _id: "$post_type_id", documents: { $sum: 1 } } },
  { $sort: { _id: 1 } },
]).forEach((row) => print(`${row._id}=${row.documents}`));

print("6. Questions by year (2015-2024)");
posts.aggregate([
  { $match: { site: "askubuntu.com", post_type_id: 1, post_year: { $gte: 2015, $lte: 2024 } } },
  { $group: { _id: "$post_year", questions: { $sum: 1 } } },
  { $sort: { _id: 1 } },
]).forEach((row) => print(`${row._id}=${row.questions}`));

print("7. Most common question tags");
posts.aggregate([
  { $match: { site: "askubuntu.com", post_type_id: 1, tags: { $ne: [] } } },
  { $unwind: "$tags" },
  { $group: { _id: "$tags", questions: { $sum: 1 } } },
  { $sort: { questions: -1 } },
  { $limit: 8 },
]).forEach((row) => print(`${row._id}=${row.questions}`));
