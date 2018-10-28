Chictopia metadata
==================

Web-crawled data from Chictopia in Fall 2012. Image data are not included.

Contents
--------

    chictopia.sql.gz
    README.md

Reconstructing SQLite3 database
-------------------------------

The following command will reconstruct the SQLite3 database file.

    gunzip -c chictopia.sql.gz | sqlite3 chictopia.sqlite3


Getting started
---------------

Here are a list of major structures in Chictopia. Most external relations are
represented a name + `_id` field. For example, User-Post relation is stored as
`user_id` field in posts table.

### User-Posts-Photos relationships

A user has many posts. A post has many photos (up to 5 / post).

    user {
      name,
      type,
      [
        post {
          title,
          description,
          [photo {}, photo {}, ...]
        },
        post {
          title,
          description,
          [photo {}, photo {}, ...]
        }
        ...
      ]
    }

Example: retrieving posts of user 1234.

    SELECT * FROM posts WHERE id = 1234


### Post-Tag relationships

Chictopia has a fairly complicated tagging strcture. First, there are different
kinds of tags.

 * Color: color of the item.
 * Style: general style of the post.
 * Occasion: occasion of the outfit.
 * Clothing: type of the item.
 * Brand: brand of the item.
 * Trend: free-form tag.

Only trend tags are stored in the `trends` table. Other tags are stored in the
`tags` table.

Example: retrieving all clothing tags.

    SELECT * FROM tags WHERE type = 'Clothing'

These tags are associated with a post through complex relationships. It is
recommended to create a new (temporary) table from existing records to
retrieve desired structured tags.

    post {
      style_id,
      occasion_id,
      [
        garment {
          clothing_id,
          color_id,
          brand_id,
          trend_id
        },
        garment {
          clothing_id,
          color_id,
          brand_id,
          trend_id
        },
        ...
      ],
      [
        tagging { trend_id },
        tagging { trend_id },
        ...
      ],
      [
        color_tagging { color_id },
        color_tagging { color_id },
        ...
      ]
    }

Example: retrieving 100 garment-lists by post id.

    SELECT
      post_id,
      "(" || GROUP_CONCAT(name) || ")"
    FROM (
      SELECT
        post_id,
        "('" ||
        replace(replace(replace(coalesce(lower(colors.name),""), "%2B", '+'), "%27", "'"), "'", "''") || "','" ||
        replace(replace(replace(coalesce(lower(brands.name),""), "%2B", '+'), "%27", "'"), "'", "''") || "','" ||
        replace(replace(replace(coalesce(lower(trends.name),""), "%2B", '+'), "%27", "'"), "'", "''") || "','" ||
        coalesce(clothings.name,"") ||
        "')" AS name
      FROM garments
      LEFT OUTER JOIN tags AS colors
        ON garments.color_id = colors.id
      LEFT OUTER JOIN tags AS brands
        ON garments.brand_id = brands.id
      LEFT OUTER JOIN tags AS clothings
        ON garments.clothing_id = clothings.id
      LEFT OUTER JOIN trends AS trends
        ON garments.trend_id = trends.id
      ) AS garment_tuples
    GROUP BY post_id
    LIMIT 100

### User-user

There are two networks: friends and fans. Both are stored as edges in the table.

    friendship, fanship {
      user_id,
      to_id
    }


Schema
------

Following tables exist in the SQLite3 database.

### Users

    CREATE TABLE "users" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      "name" varchar(255) NOT NULL,
      "type" varchar(255) DEFAULT 'User' NOT NULL,
      "street_id" integer,
      "views" integer DEFAULT 0 NOT NULL,
      "chic_points" integer DEFAULT 0 NOT NULL,
      "status" integer DEFAULT 0 NOT NULL,
      "description" text,
      "bookmarks_count" integer DEFAULT 0 NOT NULL,
      "comments_count" integer DEFAULT 0 NOT NULL,
      "friends_count" integer DEFAULT 0 NOT NULL,
      "fans_count" integer DEFAULT 0 NOT NULL,
      "favorite_chictopians_count" integer DEFAULT 0 NOT NULL,
      "created_at" datetime NOT NULL,
      "updated_at" datetime NOT NULL
      );

User information. The `status` indicates a crawler status in integer.
`{-1: error, 2: success}`.

  * belongs to street
  * has many posts
  * has many comments
  * has many bookmarks
  * has many friendships (`user_id`, `to_id`)
  * has many fanships (`user_id`, `to_id`)

### Posts

    CREATE TABLE "posts" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      "chictopia_id" integer NOT NULL,
      "user_id" integer,
      "type" varchar(255) DEFAULT 'Post' NOT NULL,
      "status" integer DEFAULT 0 NOT NULL,
      "votes" integer DEFAULT 0 NOT NULL,
      "title" varchar(255),
      "date" date,
      "description" text,
      "style_id" integer,
      "occasion_id" integer,
      "season_id" integer,
      "comments_count" integer DEFAULT 0 NOT NULL,
      "bookmarks_count" integer DEFAULT 0 NOT NULL,
      "created_at" datetime NOT NULL,
      "updated_at" datetime NOT NULL);

Posts in Chictopia. The `status` indicates a crawler status in integer.
`{-1: error, 2: success}`.

  * belongs to user
  * belongs to tag (`style_id`, `occasion_id`)
  * has many photos
  * has many comments
  * has many bookmarks
  * has many garments
  * has many taggings
  * has many color taggings

### Streets

    CREATE TABLE "streets" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      "name" varchar(255) NOT NULL,
      "chictopia_id" integer NOT NULL,
      "users_count" integer DEFAULT 0 NOT NULL
      );

Location names of the user.

 * belongs to user

### Garment

    CREATE TABLE "garments" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      "clothing_id" integer,
      "color_id" integer,
      "brand_id" integer,
      "trend_id" integer,
      "store_id" integer,
      "post_id" integer NOT NULL
    );

Structured tags for posts.

 * belongs to post
 * belongs to tag (`clothing_id`, `color_id`, `brand_id`)
 * belongs to trend
 * belongs to store

### Tags

    CREATE TABLE "tags" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      "name" varchar(255) NOT NULL,
      "type" varchar(255) NOT NULL,
      "garments_count" integer DEFAULT 0 NOT NULL
      );

Tag names. Depending on the type, it has posts or garments.

 * has many posts
 * has many garments
 * has many color taggings

### Trends

    CREATE TABLE "trends" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      "name" varchar(255) NOT NULL,
      "chictopia_id" integer NOT NULL,
      "taggings_count" integer DEFAULT 0 NOT NULL,
      "garments_count" integer DEFAULT 0 NOT NULL
      );

Free-form text tags.

 * has many taggings
 * has many posts

### Fanships

    CREATE TABLE "fanships" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      "user_id" integer NOT NULL,
      "to_id" integer NOT NULL,
      "created_at" datetime,
      "updated_at" datetime
      );

User fanship relationships.

 * belongs to user (`user_id`, `to_id`)

### Friendships

    CREATE TABLE "friendships" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      "user_id" integer NOT NULL,
      "to_id" integer NOT NULL,
      "created_at" datetime,
      "updated_at" datetime
      );

User friendship relationships.

 * belongs to user (`user_id`, `to_id`)

### Bookmarks

    CREATE TABLE "bookmarks" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      "user_id" integer,
      "post_id" integer
      );

User bookmarking.

 * belongs to post
 * belongs to user

### Stores

    CREATE TABLE "stores" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      "uri" varchar(255) NOT NULL,
      "name" varchar(255) NOT NULL,
      "garments_count" integer DEFAULT 0 NOT NULL
      );

Store names found in Chictopia.

 * belongs to post

### Comments

    CREATE TABLE "comments" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      "user_id" integer NOT NULL,
      "post_id" integer NOT NULL,
      "text" text,
      "date" date,
      "comment_id" integer,
      "created_at" datetime NOT NULL,
      "updated_at" datetime NOT NULL
      );

User comments. The `comment_id` tracks reply to another comment.

 * belongs to post
 * belongs to user
 * belongs to comment

### Color taggings

    CREATE TABLE "color_taggings" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      "post_id" integer,
      "color_id" integer
      );

Many-to-many relationships for colors and posts.

 * belongs to post
 * belongs to tag (`color_id`)

### Taggings

    CREATE TABLE "taggings" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      "post_id" integer,
      "trend_id" integer,
      "created_at" datetime NOT NULL,
      "updated_at" datetime NOT NULL
      );

Many-to-many relationships for trends and posts.

 * belongs to post
 * belongs to trend

### Photos

    CREATE TABLE "photos" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      "post_id" integer,
      "path" varchar(255) NOT NULL,
      "status" integer DEFAULT 0 NOT NULL,
      "file_file_name" varchar(255),
      "file_file_size" integer,
      "file_content_type" varchar(255),
      "file_updated_at" datetime,
      "width" integer,
      "height" integer,
      "created_at" datetime NOT NULL,
      "updated_at" datetime NOT NULL
      );

Photos attached to a post. The `status` indicates a crawler status in integer.
`{-1: error, 2: success}`.

 * belongs to post
