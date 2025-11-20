/// success : true
/// msg : "Successfully gets the announcement data"
/// records : 1
/// data : [{"_id":"691c142160690c1c828b80b0","unique_key":"Z14QCF7N9K8","announcement_type":"1","announcement_for":"3","state_id":1,"state_name":"Bihar","district_name":"","block_id":-1,"block_name":"","announcement_start_period":"2025-11-18T12:00:00.000+05:30","announcement_end_period":"2025-11-30T12:00:00.000+05:30","title_en":"General Health Awareness Announcement","content_en":"<p><strong>Dear ASHA Worker,</strong></p><p>We are pleased to announce an upcoming <strong>Community Health Awareness Drive</strong> in your area. Please follow the steps below:</p><h3><strong>Your Responsibilities:</strong></h3><ul><li>Visit all households in your assigned region</li><li>Spread awareness about key health topics:<ul><li>Immunization</li><li>Maternal health</li><li>Child nutrition</li><li>Disease prevention</li></ul></li><li>Encourage families to participate actively</li></ul><h3><strong>Key Points:</strong></h3><ol><li>The drive will cover all age groups</li><li>Inform families about nearby health facilities</li><li>Submit a brief update after your field visit</li></ol><p><strong>Your dedication is making our community healthier and stronger!</strong></p>","added_date_time":"2025-11-18T06:37:21.070Z","modified_date_time":"2025-11-18T06:37:21.070Z","option":"All","is_deleted":0,"is_published":1,"__v":0}]

class NotificationAnouncementResponce {
  NotificationAnouncementResponce({
      bool? success, 
      String? msg, 
      num? records, 
      List<Data>? data,}){
    _success = success;
    _msg = msg;
    _records = records;
    _data = data;
}

  NotificationAnouncementResponce.fromJson(dynamic json) {
    _success = json['success'];
    _msg = json['msg'];
    _records = json['records'];
    if (json['data'] != null) {
      _data = [];
      json['data'].forEach((v) {
        _data?.add(Data.fromJson(v));
      });
    }
  }
  bool? _success;
  String? _msg;
  num? _records;
  List<Data>? _data;
NotificationAnouncementResponce copyWith({  bool? success,
  String? msg,
  num? records,
  List<Data>? data,
}) => NotificationAnouncementResponce(  success: success ?? _success,
  msg: msg ?? _msg,
  records: records ?? _records,
  data: data ?? _data,
);
  bool? get success => _success;
  String? get msg => _msg;
  num? get records => _records;
  List<Data>? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = _success;
    map['msg'] = _msg;
    map['records'] = _records;
    if (_data != null) {
      map['data'] = _data?.map((v) => v.toJson()).toList();
    }
    return map;
  }


}

/// _id : "691c142160690c1c828b80b0"
/// unique_key : "Z14QCF7N9K8"
/// announcement_type : "1"
/// announcement_for : "3"
/// state_id : 1
/// state_name : "Bihar"
/// district_name : ""
/// block_id : -1
/// block_name : ""
/// announcement_start_period : "2025-11-18T12:00:00.000+05:30"
/// announcement_end_period : "2025-11-30T12:00:00.000+05:30"
/// title_en : "General Health Awareness Announcement"
/// content_en : "<p><strong>Dear ASHA Worker,</strong></p><p>We are pleased to announce an upcoming <strong>Community Health Awareness Drive</strong> in your area. Please follow the steps below:</p><h3><strong>Your Responsibilities:</strong></h3><ul><li>Visit all households in your assigned region</li><li>Spread awareness about key health topics:<ul><li>Immunization</li><li>Maternal health</li><li>Child nutrition</li><li>Disease prevention</li></ul></li><li>Encourage families to participate actively</li></ul><h3><strong>Key Points:</strong></h3><ol><li>The drive will cover all age groups</li><li>Inform families about nearby health facilities</li><li>Submit a brief update after your field visit</li></ol><p><strong>Your dedication is making our community healthier and stronger!</strong></p>"
/// added_date_time : "2025-11-18T06:37:21.070Z"
/// modified_date_time : "2025-11-18T06:37:21.070Z"
/// option : "All"
/// is_deleted : 0
/// is_published : 1
/// __v : 0

class Data {
  Data({
      String? id, 
      String? uniqueKey, 
      String? announcementType, 
      String? announcementFor, 
      num? stateId, 
      String? stateName, 
      String? districtName, 
      num? blockId, 
      String? blockName, 
      String? announcementStartPeriod, 
      String? announcementEndPeriod, 
      String? titleEn, 
      String? contentEn, 
      String? addedDateTime, 
      String? modifiedDateTime, 
      String? option, 
      num? isDeleted, 
      num? isPublished, 
      num? v,}){
    _id = id;
    _uniqueKey = uniqueKey;
    _announcementType = announcementType;
    _announcementFor = announcementFor;
    _stateId = stateId;
    _stateName = stateName;
    _districtName = districtName;
    _blockId = blockId;
    _blockName = blockName;
    _announcementStartPeriod = announcementStartPeriod;
    _announcementEndPeriod = announcementEndPeriod;
    _titleEn = titleEn;
    _contentEn = contentEn;
    _addedDateTime = addedDateTime;
    _modifiedDateTime = modifiedDateTime;
    _option = option;
    _isDeleted = isDeleted;
    _isPublished = isPublished;
    _v = v;
}

  Data.fromJson(dynamic json) {
    _id = json['_id'];
    _uniqueKey = json['unique_key'];
    _announcementType = json['announcement_type'];
    _announcementFor = json['announcement_for'];
    _stateId = json['state_id'];
    _stateName = json['state_name'];
    _districtName = json['district_name'];
    _blockId = json['block_id'];
    _blockName = json['block_name'];
    _announcementStartPeriod = json['announcement_start_period'];
    _announcementEndPeriod = json['announcement_end_period'];
    _titleEn = json['title_en'];
    _contentEn = json['content_en'];
    _addedDateTime = json['added_date_time'];
    _modifiedDateTime = json['modified_date_time'];
    _option = json['option'];
    _isDeleted = json['is_deleted'];
    _isPublished = json['is_published'];
    _v = json['__v'];
  }
  String? _id;
  String? _uniqueKey;
  String? _announcementType;
  String? _announcementFor;
  num? _stateId;
  String? _stateName;
  String? _districtName;
  num? _blockId;
  String? _blockName;
  String? _announcementStartPeriod;
  String? _announcementEndPeriod;
  String? _titleEn;
  String? _contentEn;
  String? _addedDateTime;
  String? _modifiedDateTime;
  String? _option;
  num? _isDeleted;
  num? _isPublished;
  num? _v;
Data copyWith({  String? id,
  String? uniqueKey,
  String? announcementType,
  String? announcementFor,
  num? stateId,
  String? stateName,
  String? districtName,
  num? blockId,
  String? blockName,
  String? announcementStartPeriod,
  String? announcementEndPeriod,
  String? titleEn,
  String? contentEn,
  String? addedDateTime,
  String? modifiedDateTime,
  String? option,
  num? isDeleted,
  num? isPublished,
  num? v,
}) => Data(  id: id ?? _id,
  uniqueKey: uniqueKey ?? _uniqueKey,
  announcementType: announcementType ?? _announcementType,
  announcementFor: announcementFor ?? _announcementFor,
  stateId: stateId ?? _stateId,
  stateName: stateName ?? _stateName,
  districtName: districtName ?? _districtName,
  blockId: blockId ?? _blockId,
  blockName: blockName ?? _blockName,
  announcementStartPeriod: announcementStartPeriod ?? _announcementStartPeriod,
  announcementEndPeriod: announcementEndPeriod ?? _announcementEndPeriod,
  titleEn: titleEn ?? _titleEn,
  contentEn: contentEn ?? _contentEn,
  addedDateTime: addedDateTime ?? _addedDateTime,
  modifiedDateTime: modifiedDateTime ?? _modifiedDateTime,
  option: option ?? _option,
  isDeleted: isDeleted ?? _isDeleted,
  isPublished: isPublished ?? _isPublished,
  v: v ?? _v,
);
  String? get id => _id;
  String? get uniqueKey => _uniqueKey;
  String? get announcementType => _announcementType;
  String? get announcementFor => _announcementFor;
  num? get stateId => _stateId;
  String? get stateName => _stateName;
  String? get districtName => _districtName;
  num? get blockId => _blockId;
  String? get blockName => _blockName;
  String? get announcementStartPeriod => _announcementStartPeriod;
  String? get announcementEndPeriod => _announcementEndPeriod;
  String? get titleEn => _titleEn;
  String? get contentEn => _contentEn;
  String? get addedDateTime => _addedDateTime;
  String? get modifiedDateTime => _modifiedDateTime;
  String? get option => _option;
  num? get isDeleted => _isDeleted;
  num? get isPublished => _isPublished;
  num? get v => _v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = _id;
    map['unique_key'] = _uniqueKey;
    map['announcement_type'] = _announcementType;
    map['announcement_for'] = _announcementFor;
    map['state_id'] = _stateId;
    map['state_name'] = _stateName;
    map['district_name'] = _districtName;
    map['block_id'] = _blockId;
    map['block_name'] = _blockName;
    map['announcement_start_period'] = _announcementStartPeriod;
    map['announcement_end_period'] = _announcementEndPeriod;
    map['title_en'] = _titleEn;
    map['content_en'] = _contentEn;
    map['added_date_time'] = _addedDateTime;
    map['modified_date_time'] = _modifiedDateTime;
    map['option'] = _option;
    map['is_deleted'] = _isDeleted;
    map['is_published'] = _isPublished;
    map['__v'] = _v;
    return map;
  }
  Map<String, dynamic> toMap() {
    return {
      '_id': _id,
      'unique_key': _uniqueKey,
      'announcement_type': _announcementType,
      'announcement_for': _announcementFor,
      'state_id': _stateId,
      'state_name': _stateName,
      'district_name': _districtName,
      'block_id': _blockId,
      'block_name': _blockName,
      'announcement_start_period': _announcementStartPeriod,
      'announcement_end_period': _announcementEndPeriod,
      'title_en': _titleEn,
      'content_en': _contentEn,
      'added_date_time': _addedDateTime,
      'modified_date_time': _modifiedDateTime,
      'option': _option,
      'is_deleted': _isDeleted,
      'is_published': _isPublished,
      '__v': _v,
      'is_read': 0,
      'is_synced': 1,
    };
  }


}