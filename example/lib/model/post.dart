import 'package:flutter_data/flutter_data.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:flutter_data/annotations.dart';
import 'adapters.dart';
import 'comment.dart';
import 'user.dart';

part 'post.g.dart';

@JsonSerializable()
@DataRepository([StandardJSONAdapter, JSONPlaceholderAdapter])
class Post with DataSupport<Post> {
  @override
  final int id;
  final String title;
  final String body;
  final HasMany<Comment> comments;
  final BelongsTo<User> user;

  Post({
    this.id,
    this.title,
    this.body,
    HasMany<Comment> comments,
    BelongsTo<User> user,
  })  : comments = comments ?? HasMany<Comment>(),
        user = user ?? BelongsTo<User>();
}
