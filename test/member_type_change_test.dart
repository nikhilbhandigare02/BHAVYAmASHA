import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddNewFamilyMember/bloc/addnewfamilymember_bloc.dart';

void main() {
  group('Member Type Change Tests', () {
    late AddnewfamilymemberBloc bloc;

    setUp(() {
      bloc = AddnewfamilymemberBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('should clear all data when changing from Adult to Child', () {
      // Arrange - set initial data for adult
      bloc.add(AnmUpdateName('John Doe'));
      bloc.add(AnmUpdateMobileNo('1234567890'));
      bloc.add(AnmUpdateRelation('Spouse'));
      bloc.add(AnmUpdateMaritalStatus('Married'));
      
      // Verify data is set
      expect(bloc.state.name, 'John Doe');
      expect(bloc.state.mobileNo, '1234567890');
      expect(bloc.state.relation, 'Spouse');
      expect(bloc.state.maritalStatus, 'Married');

      // Act - change member type from Adult to Child
      bloc.add(AnmClearAllData());
      bloc.add(AnmUpdateMemberType('Child'));

      // Assert - all data should be cleared except member type
      expect(bloc.state.memberType, 'Child');
      expect(bloc.state.name, null);
      expect(bloc.state.mobileNo, null);
      expect(bloc.state.relation, null);
      expect(bloc.state.maritalStatus, null);
    });

    test('should clear all data when changing from Child to Adult', () {
      // Arrange - set initial data for child
      bloc.add(AnmUpdateMemberType('Child'));
      bloc.add(AnmUpdateName('Baby Doe'));
      bloc.add(AnmUpdateBirthOrder('1'));
      bloc.add(AnmUpdateFatherName('Father Name'));
      
      // Verify data is set
      expect(bloc.state.memberType, 'Child');
      expect(bloc.state.name, 'Baby Doe');
      expect(bloc.state.birthOrder, '1');
      expect(bloc.state.fatherName, 'Father Name');

      // Act - change member type from Child to Adult
      bloc.add(AnmClearAllData());
      bloc.add(AnmUpdateMemberType('Adult'));

      // Assert - all data should be cleared except member type
      expect(bloc.state.memberType, 'Adult');
      expect(bloc.state.name, null);
      expect(bloc.state.birthOrder, null);
      expect(bloc.state.fatherName, null);
    });

    test('should not clear data when member type stays the same', () {
      // Arrange - set initial data
      bloc.add(AnmUpdateMemberType('Adult'));
      bloc.add(AnmUpdateName('John Doe'));
      
      // Verify data is set
      expect(bloc.state.memberType, 'Adult');
      expect(bloc.state.name, 'John Doe');

      // Act - change member type to the same value
      bloc.add(AnmUpdateMemberType('Adult'));

      // Assert - data should remain unchanged
      expect(bloc.state.memberType, 'Adult');
      expect(bloc.state.name, 'John Doe');
    });

    test('should reset to default state after clear all data', () {
      // Arrange - set various fields
      bloc.add(AnmUpdateName('Test Name'));
      bloc.add(AnmUpdateMobileNo('9876543210'));
      bloc.add(AnmUpdateMemberType('Child'));
      bloc.add(AnmUpdateRelation('Son'));
      bloc.add(AnmUpdateMaritalStatus('Single'));
      
      // Verify data is set
      expect(bloc.state.name, 'Test Name');
      expect(bloc.state.mobileNo, '9876543210');
      expect(bloc.state.memberType, 'Child');
      expect(bloc.state.relation, 'Son');
      expect(bloc.state.maritalStatus, 'Single');

      // Act - clear all data
      bloc.add(AnmClearAllData());

      // Assert - should return to default state
      expect(bloc.state.memberType, 'Adult'); // Default value
      expect(bloc.state.name, null);
      expect(bloc.state.mobileNo, null);
      expect(bloc.state.relation, null);
      expect(bloc.state.maritalStatus, null);
      expect(bloc.state.useDob, true); // Default value
    });

    test('should clear data on first member type change in edit mode', () {
      // Simulate edit mode with prefilled Adult member type
      bloc.add(AnmUpdateMemberType('Adult'));
      bloc.add(AnmUpdateName('Existing Adult Member'));
      bloc.add(AnmUpdateMobileNo('1234567890'));
      bloc.add(AnmUpdateRelation('Head'));
      bloc.add(AnmUpdateMaritalStatus('Married'));
      
      // Verify prefilled data
      expect(bloc.state.memberType, 'Adult');
      expect(bloc.state.name, 'Existing Adult Member');
      expect(bloc.state.mobileNo, '1234567890');
      expect(bloc.state.relation, 'Head');
      expect(bloc.state.maritalStatus, 'Married');

      // Act - FIRST change: Adult to Child (should clear data immediately)
      bloc.add(AnmClearAllData());
      bloc.add(AnmUpdateMemberType('Child'));

      // Assert - data should be cleared on first change
      expect(bloc.state.memberType, 'Child');
      expect(bloc.state.name, null);
      expect(bloc.state.mobileNo, null);
      expect(bloc.state.relation, null);
      expect(bloc.state.maritalStatus, null);

      // Add some child data
      bloc.add(AnmUpdateName('Child Member'));
      bloc.add(BirthWeightChange('3.0'));
      
      // Verify child data is set
      expect(bloc.state.name, 'Child Member');
      expect(bloc.state.birthWeight, '3.0');

      // Act - SECOND change: Child back to Adult (should also clear data)
      bloc.add(AnmClearAllData());
      bloc.add(AnmUpdateMemberType('Adult'));

      // Assert - data should be cleared again
      expect(bloc.state.memberType, 'Adult');
      expect(bloc.state.name, null);
      expect(bloc.state.birthWeight, null);
    });

    test('should work correctly in edit mode simulation', () {
      // Simulate edit mode scenario where data is pre-filled
      bloc.add(AnmUpdateMemberType('Adult'));
      bloc.add(AnmUpdateName('Existing Member'));
      bloc.add(AnmUpdateMobileNo('1111111111'));
      bloc.add(AnmUpdateRelation('Head'));
      bloc.add(AnmUpdateMaritalStatus('Married'));
      
      // Verify pre-filled data
      expect(bloc.state.memberType, 'Adult');
      expect(bloc.state.name, 'Existing Member');
      expect(bloc.state.mobileNo, '1111111111');
      expect(bloc.state.relation, 'Head');
      expect(bloc.state.maritalStatus, 'Married');

      // Act - change member type in edit mode (Adult to Child)
      bloc.add(AnmClearAllData());
      bloc.add(AnmUpdateMemberType('Child'));

      // Assert - all data should be cleared even in edit mode
      expect(bloc.state.memberType, 'Child');
      expect(bloc.state.name, null);
      expect(bloc.state.mobileNo, null);
      expect(bloc.state.relation, null);
      expect(bloc.state.maritalStatus, null);
    });

    test('should clear all edit-specific fields when switching types', () {
      // Set all possible fields including edit-specific ones
      bloc.add(AnmUpdateMemberType('Child'));
      bloc.add(AnmUpdateName('Child Name'));
      bloc.add(AnmUpdateBirthOrder('2'));
      bloc.add(BirthWeightChange('2.5'));
      bloc.add(ChildSchoolChange('Primary'));
      bloc.add(AnmUpdateFatherName('Father'));
      bloc.add(AnmUpdateMotherName('Mother'));
      
      // Verify all fields are set
      expect(bloc.state.memberType, 'Child');
      expect(bloc.state.name, 'Child Name');
      expect(bloc.state.birthOrder, '2');
      expect(bloc.state.birthWeight, '2.5');
      expect(bloc.state.ChildSchool, 'Primary');
      expect(bloc.state.fatherName, 'Father');
      expect(bloc.state.motherName, 'Mother');

      // Act - switch to Adult
      bloc.add(AnmClearAllData());
      bloc.add(AnmUpdateMemberType('Adult'));

      // Assert - all child-specific fields should be cleared
      expect(bloc.state.memberType, 'Adult');
      expect(bloc.state.name, null);
      expect(bloc.state.birthOrder, null);
      expect(bloc.state.birthWeight, null);
      expect(bloc.state.ChildSchool, null);
      expect(bloc.state.fatherName, null);
      expect(bloc.state.motherName, null);
    });
  });
}