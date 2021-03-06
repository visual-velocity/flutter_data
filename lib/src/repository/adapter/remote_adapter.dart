part of flutter_data;

mixin RemoteAdapter<T extends DataSupport<T>> on Repository<T> {
  // request

  @protected
  @visibleForTesting
  String get baseUrl => throw UnsupportedError('Please override baseUrl');

  @protected
  @visibleForTesting
  String urlForFindAll(params) => '$type';

  @protected
  @visibleForTesting
  DataRequestMethod methodForFindAll(params) => DataRequestMethod.GET;

  @protected
  @visibleForTesting
  String urlForFindOne(id, params) => '$type/$id';

  @protected
  @visibleForTesting
  DataRequestMethod methodForFindOne(id, params) => DataRequestMethod.GET;

  @protected
  @visibleForTesting
  String urlForSave(id, params) => id != null ? '$type/$id' : type;

  @protected
  @visibleForTesting
  DataRequestMethod methodForSave(id, params) =>
      id != null ? DataRequestMethod.PATCH : DataRequestMethod.POST;

  @protected
  @visibleForTesting
  String urlForDelete(id, params) => '$type/$id';

  @protected
  @visibleForTesting
  DataRequestMethod methodForDelete(id, params) => DataRequestMethod.DELETE;

  @protected
  @visibleForTesting
  Map<String, dynamic> get params => {};

  @protected
  @visibleForTesting
  Map<String, String> get headers => {};

  // serialization

  @protected
  @visibleForTesting
  Map<String, dynamic> serialize(T model) => localSerialize(model);

  @protected
  @visibleForTesting
  Iterable<Map<String, dynamic>> serializeCollection(Iterable<T> models) =>
      models.map(serialize);

  @protected
  @visibleForTesting
  T deserialize(dynamic object, {String key}) {
    final map = Map<String, dynamic>.from(object as Map);
    final model = localDeserialize(map);
    return _initModel(model, key: key, save: true);
  }

  @protected
  @visibleForTesting
  Iterable<T> deserializeCollection(object) =>
      (object as Iterable).map(deserialize);

  @protected
  @visibleForTesting
  String fieldForKey(String key) => key;

  @protected
  @visibleForTesting
  String keyForField(String field) => field;

  // repository implementation

  @override
  Future<List<T>> findAll(
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers}) async {
    remote ??= _remote;

    if (remote == false) {
      return localFindAll().toList();
    }

    final response = await withHttpClient(
      (client) => _executeRequest(
        client,
        urlForFindAll(params),
        methodForFindAll(params),
        params: params,
        headers: headers,
      ),
    );

    return withResponse<List<T>>(response, (data) {
      return deserializeCollection(data).toList();
    });
  }

  @override
  Future<T> findOne(dynamic model,
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers}) async {
    assert(model != null);
    remote ??= _remote;

    final id = model is T ? model.id : model;

    if (remote == false) {
      final key =
          manager.getKeyForId(type, id) ?? (model is T ? model._key : null);
      if (key == null) {
        return null;
      }
      return localFindOne(key);
    }

    final response = await withHttpClient(
      (client) => _executeRequest(
        client,
        urlForFindOne(id, params),
        methodForFindOne(id, params),
        params: params,
        headers: headers,
      ),
    );

    return withResponse<T>(response, (data) {
      // data has an ID, deserialize will reuse
      // corresponding key, if present
      return deserialize(data);
    });
  }

  @override
  Future<T> save(T model,
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers}) async {
    remote ??= _remote;

    if (remote == false) {
      _initModel(model);
      localSave(model._key, model);
      return model;
    }

    final body = json.encode(serialize(model));

    final response = await withHttpClient(
      (client) => _executeRequest(
        client,
        urlForSave(model.id, params),
        methodForSave(model.id, params),
        params: params,
        headers: headers,
        body: body,
      ),
    );

    return withResponse<T>(response, (data) {
      if (data == null) {
        // return "old" model if response was empty
        return _initModel(model);
      }
      // deserialize already inits models
      // if model had a key already, reuse it
      final newModel =
          deserialize(data as Map<String, dynamic>, key: model._key);
      if (model._key != null && model._key != newModel._key) {
        // in the unlikely case where supplied key couldn't be used
        // ensure "old" copy of model carries the updated key
        manager.removeKey(model._key);
        model._key = newModel._key;
      }
      return newModel;
    });
  }

  @override
  Future<void> delete(dynamic model,
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers}) async {
    remote ??= _remote;

    final id = model is T ? model.id : model;
    final key =
        manager.getKeyForId(type, id) ?? (model is T ? model._key : null);

    if (key == null) {
      return;
    }

    localDelete(key);

    if (remote && id != null) {
      manager.removeId(type, id);
      final response = await withHttpClient(
        (client) => _executeRequest(
          client,
          urlForDelete(id, params),
          methodForDelete(id, params),
          params: params,
          headers: headers,
        ),
      );

      return withResponse<void>(response, (_) {
        return;
      });
    }
  }

  @override
  Map<dynamic, T> get dumpBox => box.toMap();

  // utils

  @protected
  Map<String, String> parseQueryParameters(Map<String, dynamic> params) {
    params ??= const {};

    return params.entries.fold<Map<String, String>>({}, (acc, e) {
      if (e.value is Map<String, dynamic>) {
        for (var e2 in (e.value as Map<String, dynamic>).entries) {
          acc['${e.key}[${e2.key}]'] = e2.value.toString();
        }
      } else {
        acc[e.key] = e.value.toString();
      }
      return acc;
    });
  }

  @protected
  Future<R> withHttpClient<R>(OnRequest<R> onRequest) async {
    final client = http.Client();
    try {
      return await onRequest(client);
    } finally {
      client.close();
    }
  }

  @protected
  FutureOr<R> withResponse<R>(
      http.Response response, OnResponseSuccess<R> onSuccess) {
    dynamic data;
    dynamic error;

    if (response.body.isNotEmpty) {
      try {
        data = json.decode(response.body);
      } on FormatException catch (e) {
        error = e;
      }
    }

    final code = response.statusCode;

    if (code >= 200 && code < 300) {
      if (error != null) {
        throw DataException(error, response.statusCode);
      }
      return onSuccess(data);
    } else if (code >= 400 && code < 600) {
      throw DataException(error ?? data, response.statusCode);
    } else {
      throw UnsupportedError('Failed request for type $R');
    }
  }

  // helpers

  Future<http.Response> _executeRequest(
      http.Client client, String url, DataRequestMethod method,
      {Map<String, dynamic> params,
      Map<String, String> headers,
      String body}) async {
    final _baseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    var uri = Uri.parse('$_baseUrl$url');

    final _params = this.params & params;
    if (_params.isNotEmpty) {
      uri = uri.replace(queryParameters: parseQueryParameters(_params));
    }
    final _headers = this.headers & headers;

    http.Response response;
    switch (method) {
      case DataRequestMethod.HEAD:
        response = await client.head(uri, headers: _headers);
        break;
      case DataRequestMethod.GET:
        response = await client.get(uri, headers: _headers);
        break;
      case DataRequestMethod.PUT:
        response = await client.put(uri, headers: _headers, body: body);
        break;
      case DataRequestMethod.POST:
        response = await client.post(uri, headers: _headers, body: body);
        break;
      case DataRequestMethod.PATCH:
        response = await client.patch(uri, headers: _headers, body: body);
        break;
      case DataRequestMethod.DELETE:
        response = await client.delete(uri, headers: _headers);
        break;
      default:
        response = null;
        break;
    }

    if (_verbose && response != null) {
      print(
          '[flutter_data] $T: ${method.toShortString()} $uri [HTTP ${response.statusCode}]');
    }

    return response;
  }
}
