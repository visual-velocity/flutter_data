// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable, always_declare_return_types, non_constant_identifier_names
mixin _$CommentModelAdapter on Repository<Comment> {
  @override
  Map<String, Map<String, Object>> relationshipsFor([Comment model]) => {
        'post': {'type': 'posts', 'kind': 'BelongsTo', 'instance': model?.post}
      };

  @override
  Map<String, Repository> get relatedRepositories =>
      {'posts': manager.locator<Repository<Post>>()};

  @override
  localDeserialize(map) {
    for (final key in relationshipsFor().keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key), manager]
      };
    }
    return _$CommentFromJson(map);
  }

  @override
  localSerialize(model) {
    final map = _$CommentToJson(model);
    for (final e in relationshipsFor(model).entries) {
      map[e.key] = (e.value['instance'] as Relationship)?.toJson();
    }
    return map;
  }
}

class $CommentRepository = Repository<Comment>
    with
        _$CommentModelAdapter,
        RemoteAdapter<Comment>,
        WatchAdapter<Comment>,
        StandardJSONAdapter<Comment>,
        JSONPlaceholderAdapter<Comment>;

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Comment _$CommentFromJson(Map<String, dynamic> json) {
  return Comment(
    id: json['id'] as int,
    body: json['body'] as String,
    approved: json['approved'] as bool,
    post: json['post'] == null
        ? null
        : BelongsTo.fromJson(json['post'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$CommentToJson(Comment instance) => <String, dynamic>{
      'id': instance.id,
      'body': instance.body,
      'approved': instance.approved,
      'post': instance.post,
    };
