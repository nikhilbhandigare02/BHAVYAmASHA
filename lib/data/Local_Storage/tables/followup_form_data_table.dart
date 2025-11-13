class FollowupFormDataTable {
  static const table = 'followup_form_data';

  static const String eligibleCoupleRegistration = 'eligible_couple_registration';
  static const String eligibleCoupleTrackingDue = 'eligible_couple_tracking_due';
  static const String eligibleCoupleReregistration = 'eligible_couple_re_registration';
  static const String ancDueRegistration = 'anc_due_registration';
  static const String deliveryOutcome = 'delivery_outcome';
  static const String pncMother = 'pnc_mother';
  static const String infantDetails = 'infant_details';
  static const String infantPnc = 'infant_pnc';
  static const String childRegistrationDue = 'child_registration_due';
  static const String childTrackingDue = 'child_tracking_due';
  static const String hbycForm = 'hbyc_form';
  static const String cbac = 'cbac';

  // Form display names
  static const Map<String, String> formDisplayNames = {
    eligibleCoupleRegistration: 'Eligible Couple Registration',
    eligibleCoupleTrackingDue: 'Eligible Couple Tracking Due',
    eligibleCoupleReregistration: 'Eligible Couple Re-registration',
    ancDueRegistration: 'ANC Due Registration',
    deliveryOutcome: 'Delivery Outcome',
    pncMother: 'PNC Mother',
    infantDetails: 'Infant Details',
    infantPnc: 'Infant PNC',
    childRegistrationDue: 'Child Registration Due',
    childTrackingDue: 'Child Tracking Due',
    hbycForm: 'Home Based Young Child',
    cbac: 'Community Based Assessment Checklist',
  };

  // Form unique keys - these should be unique for each form type
  static const Map<String, String> formUniqueKeys = {
    eligibleCoupleRegistration: '5i8jv97xtnuz3fwq',
    eligibleCoupleTrackingDue: '0g5au2h46icwjlvr',
    eligibleCoupleReregistration: 'p1dm48g56h72txya',
    ancDueRegistration: 'bt7gs9rl1a5d26mz',
    deliveryOutcome: '4r7twnycml3ej1vg',
    pncMother: 'bu30k62jao9qesri',
    infantDetails: 'o6v4qlzrc7w8bahx',
    infantPnc: 'c7hmuxsli2nj6atq',
    childRegistrationDue: '2ol35gbp7rczyvn6',
    childTrackingDue: '30bycxe4gv7fqnt6',
    hbycForm: '999',
    cbac: 'vl7o6r9b6v3fbesk',
  };

  static const create = '''
  CREATE TABLE IF NOT EXISTS followup_form_data (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    server_id TEXT,
    forms_ref_key TEXT,
    household_ref_key TEXT, 
    beneficiary_ref_key TEXT,
    mother_key TEXT,
    father_key TEXT,
    child_care_state TEXT,
    device_details TEXT,
    app_details TEXT,
    parent_user TEXT,
    current_user_key TEXT,
    facility_id INTEGER,
    form_json TEXT, 
    created_date_time TEXT,
    modified_date_time TEXT,
    is_synced INTEGER,
    is_deleted INTEGER
  );
  ''';
}
