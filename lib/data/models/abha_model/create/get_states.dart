class GetStates {
  final int? sCode;
  final List<SDataState>? states;

  GetStates({this.sCode, this.states});

  factory GetStates.fromJson(Map<String, dynamic> json) {
    List<SDataState> parsedStates = [];

    // Iterate through all keys except "status_code"
    json.forEach((key, value) {
      if (key != "status_code" && value is Map<String, dynamic>) {
        parsedStates.add(SDataState.fromJson(value));
      }
    });

    return GetStates(
      sCode: json["status_code"], // Correct field name
      states: parsedStates,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (states != null) {
      for (int i = 0; i < states!.length; i++) {
        data["$i"] = states![i].toJson();
      }
    }
    data["status_code"] = sCode;
    return data;
  }
}

class SDataState {
  final int? stateCode;
  final String? stateName;

  SDataState({this.stateCode, this.stateName});

  factory SDataState.fromJson(Map<String, dynamic> json) {
    return SDataState(
      stateCode: json["stateCode"],
      stateName: json["stateName"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "stateCode": stateCode,
      "stateName": stateName,
    };
  }
}
