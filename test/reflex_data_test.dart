import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_login_app1/reflex_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('keeps the existing record when a score is not better', () async {
    await ScoreboardStore.saveScore(id: 'player', name: 'Player', score: 250);
    final original = (await ScoreboardStore.load()).single;

    await ScoreboardStore.saveScore(id: 'PLAYER', name: 'Renamed', score: 300);
    await ScoreboardStore.saveScore(id: 'player', name: 'Renamed', score: 250);

    final saved = (await ScoreboardStore.load()).single;
    expect(saved.bestScore, original.bestScore);
    expect(saved.name, original.name);
    expect(saved.timestamp, original.timestamp);
  });

  test('replaces the record when a better score is achieved', () async {
    await ScoreboardStore.saveScore(id: 'player', name: 'Player', score: 250);

    await ScoreboardStore.saveScore(
      id: 'player',
      name: 'Player Two',
      score: 200,
    );

    final saved = (await ScoreboardStore.load()).single;
    expect(saved.bestScore, 200);
    expect(saved.name, 'Player Two');
  });
}
