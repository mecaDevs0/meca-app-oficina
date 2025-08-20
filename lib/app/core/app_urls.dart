class BaseUrls {
  BaseUrls._();
  static String baseUrlDev = 'https://api.mecabr.com/';
  static String baseUrlHml = 'https://api.mecabr.com/';
  static String baseUrlProd = 'https://api.mecabr.com/';

  static String workshopBase = 'api/v1/Workshop';
  static String workshop = '$workshopBase/Register';
  static String login = '$workshopBase/Token';
  static String forgotPassword = '$workshopBase/ForgotPassword';
  static String changePassword = '$workshopBase/ChangePassword';
  static String updateDataBank = '$workshopBase/UpdateDataBank';
  static String profile = '$workshopBase/GetInfo';
  static String dataBank = '$workshopBase/GetDataBank';
  static String registerDevice = '$workshopBase/RegisterUnRegisterDeviceId';
  static String service = 'api/v1/WorkshopServices';
  static String financial = 'api/v1/FinancialHistory';
  static String scheduling = 'api/v1/Scheduling';
  static String schedulingHistory = 'api/v1/SchedulingHistory';
  static String availableScheduling = '$scheduling/AvailableScheduling';
  static String agenda = 'api/v1/WorkshopAgenda';
  static String deleteHour = '$agenda/Hour';
  static String notification = 'api/v1/Notification';
  static String helpCenter = 'api/v1/Faq';
  static String confirmSchedule = '$scheduling/ConfirmScheduling';
  static String changeScheduleStatus = '$scheduling/ChangeSchedulingStatus';
  static String suggestNewTime = '$scheduling/SuggestNewTime';
  static String suggestFreeRepair = '$scheduling/SuggestFreeRepair';
  static String sendBudget = '$scheduling/SendBudget';
  static String disputeDisapprovedService =
      '$scheduling/DisputeDisapprovedService';
  static String defaultService = 'api/v1/ServicesDefault';
}
