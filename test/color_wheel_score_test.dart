import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_login_app1/country_tracker.dart';
import 'package:flutter_login_app1/data_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('stores the best Color Wheel score and matching stage', () async {
    await PlayerProfileStore.saveColorWheelScore(
      name: 'Player',
      score: 4,
      stage: 5,
    );
    await PlayerProfileStore.saveColorWheelScore(
      name: 'Player',
      score: 2,
      stage: 3,
    );

    final player = (await PlayerProfileStore.loadData()).single;
    expect(player.colorWheelScore, 4);
    expect(player.colorWheelStage, 5);
  });

  test('returns Color Wheel leaders with points and stage', () async {
    await PlayerProfileStore.saveColorWheelScore(
      name: 'Player',
      score: 4,
      stage: 5,
    );
    final visits = [
      CountryVisit(
        playerName: 'Player',
        ipAddress: '127.0.0.1',
        countryCode: 'TH',
        countryName: 'Thailand',
        isDomestic: true,
        createdAt: DateTime(2026),
      ),
    ];

    final leaders = await CountryTracker.modeLeaders(
      visits,
      colorWheelReflex: true,
    );

    expect(leaders, hasLength(1));
    expect(leaders.single.scoreLabel, '4 แต้ม');
    expect(leaders.single.detailLabel, 'ผ่านถึงด่าน 5');
  });
}
