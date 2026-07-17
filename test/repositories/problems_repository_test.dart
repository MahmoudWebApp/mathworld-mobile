import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/core/network/api_client.dart';
import 'package:mathworld_mobile/models/problem_search.dart';
import 'package:mathworld_mobile/repositories/problems_repository.dart';

void main() {
  test('search parses localized problem previews and pagination', () async {
    final client = _FakeApiClient(
      getBody: {
        'Data': {
          'Results': [
            {
              'Id': 5,
              'TitleAr': 'عنوان',
              'TitleEn': 'Title',
              'CategoryNameAr': 'جبر',
              'CategoryNameEn': 'Algebra',
              'ViewsCount': 7,
              'Points': 10,
            },
          ],
          'Total': 1,
          'Page': 1,
          'TotalPages': 1,
        },
      },
    );
    final repository = ProblemsRepository(client);

    final result = await repository.search(
      const ProblemSearchParams(page: 1),
      'en',
    );

    expect(result.problems.single.title, 'Title');
    expect(result.problems.single.categoryName, 'Algebra');
    expect(result.total, 1);
    expect(client.lastQueryParameters?['engine'], 'postgresql');
  });

  test('submit answer parses server validation metadata', () async {
    final client = _FakeApiClient(
      postBody: {
        'Data': {
          'IsCorrect': false,
          'CorrectOptionText': r'$x=3$',
          'PointsEarned': 0,
          'DetailedSolutionEn': 'Explanation',
        },
      },
    );
    final repository = ProblemsRepository(client);

    final result = await repository.submitAnswer(
      problemId: 1,
      selectedOptionId: 2,
      timeSpentSeconds: 30,
      languageCode: 'en',
    );

    expect(result.isCorrect, isFalse);
    expect(result.selectedOptionId, 2);
    expect(result.correctOptionText, r'$x=3$');
    expect(result.detailedSolution, 'Explanation');
  });

  test('favorite update sends explicit requested state', () async {
    final client = _FakeApiClient(
      postBody: {
        'Data': {'IsFavorite': true},
      },
    );
    final repository = ProblemsRepository(client);

    final result = await repository.setFavorite(
      problemId: 9,
      isFavorite: true,
    );

    expect(result, isTrue);
    expect(client.lastPostData, {
      'ProblemId': 9,
      'IsFavorite': true,
    });
  });
}

class _FakeApiClient implements ApiClient {
  final dynamic getBody;
  final dynamic postBody;
  final StreamController<void> _sessionController =
      StreamController<void>.broadcast();

  Map<String, dynamic>? lastQueryParameters;
  Map<String, dynamic>? lastPostData;

  _FakeApiClient({this.getBody, this.postBody});

  @override
  Stream<void> get sessionExpiredStream => _sessionController.stream;

  @override
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool handleUnauthorized = true,
  }) async {
    lastQueryParameters = queryParameters;
    return _response(path, getBody);
  }

  @override
  Future<Response<dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    bool handleUnauthorized = true,
  }) async {
    lastPostData = data;
    return _response(path, postBody);
  }

  Response<dynamic> _response(String path, dynamic body) {
    return Response<dynamic>(
      data: body,
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }

  @override
  Future<void> deleteToken() async {}

  @override
  Future<String?> readToken() async => null;

  @override
  Future<void> saveToken(String token) async {}

  @override
  Future<Response<dynamic>> delete(
    String path, {
    bool handleUnauthorized = true,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Response<dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
    bool handleUnauthorized = true,
  }) {
    throw UnimplementedError();
  }
}
