import 'dart:math';

class MockApiData {
  MockApiData._();

  static final _rand = Random();

  static dynamic respond(String method, String path, {Object? body}) {
    final p = path.split('?').first;

    if (method == 'POST' && p == '/api/login') {
      return {
        'token': 'mock-token-offline',
        'token_type': 'bearer',
        'user': {
          'id': 1,
          'username': 'admin',
          'full_name': 'Msimamizi (Mock)',
          'roles': 'ADMIN',
        },
      };
    }

    if (p == '/api/admin/dashboard/badges') {
      return {
        'unread_messages': 0,
        'new_members_7d': 0,
        'pending_leadership': 0,
        'pending_reports': 0,
        'pending_opportunities': 0,
      };
    }
    if (p.contains('/dashboard/summary')) {
      return {
        'total_rulers': 0,
        'total_regions': 0,
        'total_branches': 0,
        'active_leaders': 0,
      };
    }
    if (p.contains('/dashboard/charts')) {
      return {'labels': [], 'values': []};
    }

    if (method == 'GET' && p.endsWith('/')) {
      return <dynamic>[];
    }

    if (method == 'GET') {
      return <String, dynamic>{};
    }

    if (method == 'POST' || method == 'PUT') {
      if (body is Map<String, dynamic>) {
        return {...body, 'id': body['id'] ?? _rand.nextInt(100000)};
      }
      return {'id': _rand.nextInt(100000)};
    }

    return null;
  }

  static List<int> mockBytes() {
    return const [
      137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1,
      0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 10, 73, 68, 65, 84,
      120, 156, 99, 0, 1, 0, 0, 5, 0, 1, 13, 10, 45, 180, 0, 0, 0, 0, 73, 69,
      78, 68, 174, 66, 96, 130,
    ];
  }
}
