class LoginResponseModel {
  final String? token;
  final String? refreshToken;
  final String? msg;
  final bool success;
  final Map<String, dynamic>? data;

  LoginResponseModel({
    this.token,
    this.refreshToken,
    this.msg,
    required this.success,
    this.data,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      token: json['token'],
      refreshToken: json['refreshToken'],
      msg: json['msg'],
      success: json['success'] ?? false,
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'refreshToken': refreshToken,
      'msg': msg,
      'success': success,
      'data': data,
    };
  }
  
  // For backward compatibility
  String? get message => msg;
  Map<String, dynamic>? get user => data;
}
