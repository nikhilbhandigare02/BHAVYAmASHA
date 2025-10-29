part of 'children_bloc.dart';

class ChildrenState extends Equatable {
  const ChildrenState({
    this.totalBorn = 0,
    this.totalLive = 0,
    this.totalMale = 0,
    this.totalFemale = 0,
    this.youngestAge,
    this.ageUnit,
    this.youngestGender,
  });

  final int totalBorn;
  final int totalLive;
  final int totalMale;
  final int totalFemale;
  final String? youngestAge;
  final String? ageUnit; // Days/Months/Years
  final String? youngestGender; // Male/Female

  ChildrenState copyWith({
    int? totalBorn,
    int? totalLive,
    int? totalMale,
    int? totalFemale,
    String? youngestAge,
    String? ageUnit,
    String? youngestGender,
  }) {
    return ChildrenState(
      totalBorn: totalBorn ?? this.totalBorn,
      totalLive: totalLive ?? this.totalLive,
      totalMale: totalMale ?? this.totalMale,
      totalFemale: totalFemale ?? this.totalFemale,
      youngestAge: youngestAge ?? this.youngestAge,
      ageUnit: ageUnit ?? this.ageUnit,
      youngestGender: youngestGender ?? this.youngestGender,
    );
  }

  @override
  List<Object?> get props => [
        totalBorn,
        totalLive,
        totalMale,
        totalFemale,
        youngestAge,
        ageUnit,
        youngestGender,
      ];

  Map<String, dynamic> toJson() {
    return {
      'totalBorn': totalBorn,
      'totalLive': totalLive,
      'totalMale': totalMale,
      'totalFemale': totalFemale,
      'youngestAge': youngestAge,
      'ageUnit': ageUnit,
      'youngestGender': youngestGender,
    };
  }
}
