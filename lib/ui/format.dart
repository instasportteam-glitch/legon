const weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const weekdayLong = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const monthShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String formatTime(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
}

/// "Mon, Oct 13"
String formatDay(DateTime d) => '${weekdayShort[d.weekday - 1]}, ${monthShort[d.month - 1]} ${d.day}';

/// "Today, 8:10 AM", "Yesterday, 7:02 PM" or "Mon, Oct 13".
String formatLogDate(DateTime d, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(d.year, d.month, d.day);
  if (day == today) return 'Today, ${formatTime(d)}';
  if (day == DateTime(today.year, today.month, today.day - 1)) return 'Yesterday, ${formatTime(d)}';
  return formatDay(d);
}

DateTime mondayOf(DateTime d) => DateTime(d.year, d.month, d.day - (d.weekday - 1));

/// "October 13 – 19" or "Sep 29 – Oct 5"
String formatWeekRange(DateTime monday) {
  const monthLong = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  final sunday = DateTime(monday.year, monday.month, monday.day + 6);
  if (monday.month == sunday.month) {
    return '${monthLong[monday.month - 1]} ${monday.day} – ${sunday.day}';
  }
  return '${monthShort[monday.month - 1]} ${monday.day} – ${monthShort[sunday.month - 1]} ${sunday.day}';
}

String formatJoined(DateTime d) => '${monthShort[d.month - 1]} ${d.day}, ${d.year}';
