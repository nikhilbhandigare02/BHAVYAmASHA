class GetDistricts {
  final int? sCode;
  final List<SDataDistricts>? districts;

  GetDistricts({this.sCode, this.districts});

  factory GetDistricts.fromJson(Map<String, dynamic> json) {
    List<SDataDistricts> parsedDistricts = [];

    // Iterate through all keys except "status_code"
    json.forEach((key, value) {
      if (key != "status_code" && value is Map<String, dynamic>) {
        parsedDistricts.add(SDataDistricts.fromJson(value));
      }
    });

    return GetDistricts(
      sCode: json["status_code"],
      districts: parsedDistricts,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (districts != null) {
      for (int i = 0; i < districts!.length; i++) {
        data["$i"] = districts![i].toJson();
      }
    }
    data["status_code"] = sCode;
    return data;
  }
}

class SDataDistricts {
  final int? code;
  final String? name;

  SDataDistricts({
    this.code,
    this.name,
  });

  factory SDataDistricts.fromJson(Map<String, dynamic> json) {
    return SDataDistricts(
      code: json["code"],
      name: json["name"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "code": code,
      "name": name,
    };
  }
}
