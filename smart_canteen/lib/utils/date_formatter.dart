import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  static final DateFormat _timeFormat = DateFormat('HH:mm', 'id_ID');
  static final DateFormat _dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

  static String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    try {
      return _dateTimeFormat.format(timestamp.toDate());
    } catch (_) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  static String formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    try {
      return _timeFormat.format(timestamp.toDate());
    } catch (_) {
      final date = timestamp.toDate();
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  static String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    try {
      return _dateFormat.format(timestamp.toDate());
    } catch (_) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
