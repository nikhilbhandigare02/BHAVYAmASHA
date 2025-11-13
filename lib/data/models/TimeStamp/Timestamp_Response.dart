/// time : "2025-11-12 19:03:11"

class TimeStampResponce {
  TimeStampResponce({
    String? time,}){
    _time = time;
  }

  TimeStampResponce.fromJson(dynamic json) {
    _time = json['time'];
  }
  String? _time;
  TimeStampResponce copyWith({  String? time,
  }) => TimeStampResponce(  time: time ?? _time,
  );
  String? get time => _time;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['time'] = _time;
    return map;
  }

}