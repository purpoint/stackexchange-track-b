const posts = db.getSiblingDB("stackexchange").posts;
posts.createIndex({ site: 1, id: 1 }, { unique: true, name: "site_id_unique" });
posts.createIndex(
  { site: 1, post_type_id: 1, creation_date: 1 },
  { name: "site_type_created" }
);
posts.createIndex({ tags: 1 }, { name: "tags_multikey" });
printjson(posts.getIndexes());
