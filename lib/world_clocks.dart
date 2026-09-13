import 'package:timezone/timezone.dart' as tz;

class WorldCity {
  final String id;
  final String nameAr;
  final String nameEn;
  final String ianaName; // e.g. 'America/New_York'
  const WorldCity(this.id, this.nameAr, this.nameEn, this.ianaName);
}

/// Fixed set of cities for the world-clock bar. IANA names are the
/// standard timezone-database identifiers — the same ones Android and
/// every other real system uses, so DST transitions for each city are
/// exactly correct for every date, past or future, with zero manual
/// date math.
const List<WorldCity> worldCities = [
  WorldCity('newyork', 'نيويورك', 'New York', 'America/New_York'),
  WorldCity('london', 'لندن', 'London', 'Europe/London'),
  WorldCity('tokyo', 'طوكيو', 'Tokyo', 'Asia/Tokyo'),
];

class WorldCityTime {
  final WorldCity city;
  final tz.TZDateTime time;
  final bool isDst;
  const WorldCityTime(this.city, this.time, this.isDst);
}

/// Current local time (and DST status) for [city], read straight from the
/// tz database — never computed by hand, so it stays correct through any
/// future rule changes a country makes to its own DST schedule.
WorldCityTime? worldCityNow(WorldCity city) {
  try {
    final location = tz.getLocation(city.ianaName);
    final now = tz.TZDateTime.now(location);
    return WorldCityTime(city, now, now.timeZone.isDst);
  } catch (_) {
    // Timezone database somehow missing this identifier — skip this city
    // rather than crash the whole clock bar.
    return null;
  }
}
