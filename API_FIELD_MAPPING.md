# API to Local Database Field Mapping

## Beneficiary API Response Structure

The API returns beneficiary data with the following structure. This document shows how each API field maps to your local database structure.

## Main Beneficiary Fields

### API Root Level Fields → Local Database Fields

| API Field | Local Field | Data Type | Notes |
|-----------|-------------|-----------|-------|
| `_id` | `server_id` | String | Primary server identifier |
| `unique_key` | `unique_key` | String | Unique beneficiary key |
| `household_ref_key` | `household_ref_key` | String | Reference to household |
| `beneficiary_state` | `beneficiary_state` | Array | State history |
| `pregnancy_count` | `pregnancy_count` | Integer | Number of pregnancies |
| `spouse_key` | `spouse_key` | String | Spouse reference |
| `mother_key` | `mother_key` | String | Mother reference |
| `father_key` | `father_key` | String | Father reference |
| `is_family_planning` | `is_family_planning` | Integer | Family planning flag |
| `is_adult` | `is_adult` | Integer | Adult flag |
| `is_guest` | `is_guest` | Integer | Guest flag |
| `is_death` | `is_death` | Integer | Death flag |
| `is_migrated` | `is_migrated` | Integer | Migrated flag |
| `is_separated` | `is_separated` | Integer | Separated flag |
| `geo_location` | `geo_location` | Object | GPS coordinates |
| `device_details` | `device_details` | Object | Device information |
| `app_details` | `app_details` | Object | App information |
| `parent_user` | `parent_user` | Object | Parent user info |
| `current_user_key` | `current_user_key` | String | Current user key |
| `facility_id` | `facility_id` | Integer | Facility ID |
| `created_date_time` | `created_date_time` | String | Creation timestamp |
| `modified_date_time` | `modified_date_time` | String | Modification timestamp |
| `is_deleted` | `is_deleted` | Integer | Soft delete flag |

## Beneficiary Info Fields (nested object)

### Personal Information

| API Field | Local Field | Data Type | Mapping Logic |
|-----------|-------------|-----------|--------------|
| `name.first_name` | `name` | String | Combined with middle/last |
| `name.middle_name` | `name` | String | Combined with first/last |
| `name.last_name` | `name` | String | Combined with first/middle |
| `member_name` | `headName` | String | Display name |
| `gender` | `gender` | String | M→Male, F→Female, O→Other |
| `dob` | `dob` | String | Date of birth |
| `date_of_birth` | `dob` | String | Alternative DOB field |
| `age` | `approxAge`, `years` | Integer | Age in years |
| `marital_status` | `maritalStatus` | String | Title case formatting |

### Relationship & Family

| API Field | Local Field | Data Type | Notes |
|-----------|-------------|-----------|-------|
| `relaton_with_family_head` | `relation` | String | Relationship to head |
| `father_or_spouse_name` | `fatherName`, `spouseName` | String | Father/spouse name |
| `name_of_spouse` | `spouseName` | String | Spouse name |
| `have_children` | `hasChildren` | String | yes/no → children count |
| `ben_type` | `memberType` | String | Child→child, Adult→adult |
| `type_of_beneficiary` | `beneficiaryType` | String | Beneficiary category |

### Contact Information

| API Field | Local Field | Data Type | Notes |
|-----------|-------------|-----------|-------|
| `phone` | `mobileNo` | String | Primary phone |
| `mobile_no` | `mobileNo` | String | Alternative phone |
| `whose_mob_no` | `mobileOwner` | String | Phone owner |

### Address Information (nested object)

| API Field | Local Field | Data Type | Notes |
|-----------|-------------|-----------|-------|
| `address.state` | `state` | String | State name |
| `address.district` | `district` | String | District name |
| `address.block` | `block` | String | Block name |
| `address.village` | `village` | String | Village name |

### Verification & System Fields

| API Field | Local Field | Data Type | Notes |
|-----------|-------------|-----------|-------|
| `is_abha_verified` | `is_abha_verified` | Boolean | ABHA verification |
| `is_rch_id_verified` | `is_rch_id_verified` | Boolean | RCH verification |
| `is_fetched_from_abha` | `is_fetched_from_abha` | Boolean | ABHA data source |
| `is_fetched_from_rch` | `is_fetched_from_rch` | Boolean | RCH data source |
| `is_new_member` | `is_new_member` | Boolean | New member flag |
| `isFamilyhead` | `isFamilyhead` | Boolean | Family head flag |
| `isFamilyheadWife` | `isFamilyheadWife` | Boolean | Family head wife |
| `member_status` | `memberStatus` | String | Member status |

## Mapping Implementation

The `_mapBeneficiaryInfo()` method in `BeneficiaryRepository.dart` handles the transformation:

1. **Name Construction**: Combines `first_name`, `middle_name`, `last_name` into full name
2. **Gender Normalization**: Converts single letters to full words (M→Male, F→Female)
3. **Age Handling**: Maps API `age` to both `approxAge` and `years` fields
4. **Type Mapping**: Converts `ben_type` "Child"/"adult" to "child"/"adult"
5. **Boolean Handling**: Converts various boolean indicators to proper boolean values
6. **Address Flattening**: Extracts nested address fields to top-level
7. **Default Values**: Provides sensible defaults for missing fields

## Special Cases

### Children vs Adults
- API `ben_type: "Child"` → Local `memberType: "child"`
- API `ben_type: "adult"` → Local `memberType: "adult"`

### Phone Numbers
- Primary: `phone` field
- Fallback: `mobile_no` field
- Owner: `whose_mob_no` field

### Dates
- Primary: `dob` field
- Fallback: `date_of_birth` field
- Both stored as ISO strings

### Names
- Full name constructed from `name.first_name`, `name.middle_name`, `name.last_name`
- Display name from `member_name`
- Spouse/father name from `father_or_spouse_name` or `name_of_spouse`

## Usage Example

```dart
// API response
{
  "_id": "69525bd567ec259cc06a0a19",
  "unique_key": "e542b430188f244f_29220251224160115",
  "beneficiary_info": {
    "name": {
      "first_name": "sarika",
      "middle_name": "",
      "last_name": ""
    },
    "gender": "F",
    "dob": "2010-12-23",
    "age": 15,
    "phone": "7620593001"
  }
}

// Mapped to local structure
{
  "server_id": "69525bd567ec259cc06a0a19",
  "unique_key": "e542b430188f244f_29220251224160115",
  "beneficiary_info": {
    "name": "sarika",
    "gender": "Female",
    "dob": "2010-12-23",
    "approxAge": 15,
    "years": 15,
    "mobileNo": "7620593001"
  }
}
```
