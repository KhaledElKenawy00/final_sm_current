class SessionModel {
  final int? id; // id تلقائي من قاعدة البيانات
  final String date; // تاريخ الجلسة (مثلاً: 2024-06-23)
  final String time; // وقت الجلسة (مثلاً: 22:15:30)
  final String data; // بيانات الجلسة (JSON أو نص خام)

  SessionModel({
    this.id,
    required this.date,
    required this.time,
    required this.data,
  });

  /// تحويل الكائن إلى Map لإرساله إلى قاعدة البيانات
  Map<String, dynamic> toMap() {
    final map = {
      'date': date,
      'time': time,
      'data': data,
    };

    if (id != null) {
      map['id'] = id.toString();
    }

    return map;
  }

  /// تحويل البيانات القادمة من قاعدة البيانات إلى كائن SessionModel
  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      id: map['id'],
      date: map['date'].toString(),
      time: map['time'].toString(),
      data: map['data'].toString(),
    );
  }
}
