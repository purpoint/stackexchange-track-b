const query = {
  site: "askubuntu.com",
  post_type_id: 1,
  creation_date: {
    $gte: "2020-01-01T00:00:00.000",
    $lt: "2021-01-01T00:00:00.000",
  },
};
const projection = { _id: 0, site: 1, id: 1, post_year: 1, score: 1 };

print("Collection scan");
printjson(
  db.posts
    .find(query, projection)
    .hint({ $natural: 1 })
    .explain("executionStats")
);

db.posts.createIndex(
  { site: 1, post_type_id: 1, creation_date: 1 },
  { name: "site_type_created" }
);

print("Indexed query");
printjson(
  db.posts
    .find(query, projection)
    .hint("site_type_created")
    .explain("executionStats")
);
