import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:quadranti/services/local_auth_service.dart';

void main() {
  late Directory dir;
  late LocalAuthService auth;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('quadranti_auth_');
    Hive.init(dir.path);
    auth = LocalAuthService();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('sign up then sign in with differently cased email', () async {
    final created = await auth.signUp(email: 'Me@Example.com', password: 'pw');
    expect(created?.email, 'me@example.com');

    final user = await auth.signIn(email: 'ME@example.COM', password: 'pw');
    expect(user?.id, created?.id);
  });

  test('second sign up with same email in another case is rejected', () async {
    await auth.signUp(email: 'me@example.com', password: 'pw');
    expect(await auth.signUp(email: 'ME@example.com', password: 'pw'), isNull);
  });

  test('password whitespace is significant', () async {
    await auth.signUp(email: 'me@example.com', password: ' pw ');
    expect(
      () => auth.signIn(email: 'me@example.com', password: 'pw'),
      throwsA(predicate((e) => e.toString().contains('WRONG_PASSWORD'))),
    );
    expect(await auth.signIn(email: 'me@example.com', password: ' pw '), isNotNull);
  });

  test('legacy account keyed by mixed-case email still signs in', () async {
    final users = await Hive.openBox('users');
    await users.put('Old@Example.com', {
      'id': '1',
      'email': 'Old@Example.com',
      'displayName': 'Old',
      'photoUrl': null,
      // sha256('pw')
      'passwordHash': '30c952fab122c3f9759f02a6d95c3758b246b4fee239957b2d4fee46e26170c4',
    });

    expect(await auth.signIn(email: 'Old@Example.com', password: 'pw'), isNotNull);
  });

  test('session survives until sign out', () async {
    await auth.signUp(email: 'me@example.com', password: 'pw');
    expect(await auth.getCurrentUser(), isNotNull);
    await auth.signOut();
    expect(await auth.getCurrentUser(), isNull);
  });
}
