const pipeline = [
  {
    $match: {
      site: "askubuntu.com",
      post_type_id: 1,
      post_year: { $gte: 2015, $lte: 2024 },
    },
  },
  {
    $facet: {
      yearly_questions: [
        {
          $group: {
            _id: "$post_year",
            question_count: { $sum: 1 },
            mean_score: { $avg: "$score" },
            answers_reported: { $sum: { $ifNull: ["$answer_count", 0] } },
          },
        },
        {
          $project: {
            _id: 0,
            year: "$_id",
            question_count: 1,
            mean_score: 1,
            answers_reported: 1,
          },
        },
        { $sort: { year: 1 } },
      ],
      most_used_tags: [
        { $unwind: "$tags" },
        {
          $group: {
            _id: "$tags",
            question_count: { $sum: 1 },
            mean_score: { $avg: "$score" },
          },
        },
        {
          $project: {
            _id: 0,
            tag: "$_id",
            question_count: 1,
            mean_score: 1,
          },
        },
        { $sort: { question_count: -1 } },
        { $limit: 25 },
      ],
      answered_status: [
        {
          $group: {
            _id: { answered: { $gt: [{ $ifNull: ["$answer_count", 0] }, 0] } },
            question_count: { $sum: 1 },
          },
        },
        { $project: { _id: 0, answered: "$_id.answered", question_count: 1 } },
        { $sort: { answered: 1 } },
      ],
    },
  },
];
db.posts.aggregate(pipeline, { allowDiskUse: true }).forEach(printjson);
