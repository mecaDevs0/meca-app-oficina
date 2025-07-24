class BaseUrls {
  BaseUrls._();
  static String baseUrlDev = 'https://api.mecabr.com';
  static String baseUrlHml = 'https://api.mecabr.com';
  static String baseUrlProd = 'https://api.mecabr.com';

  static String workshop = 'api/v1/Workshop';
  static String login = '$workshop/Token';
  static String forgotPassword = '$workshop/ForgotPassword';
  static String changePassword = '$workshop/ChangePassword';
  static String updateDataBank = '$workshop/UpdateDataBank';
  static String profile = '$workshop/GetInfo';
  static String dataBank = '$workshop/GetDataBank';
  static String registerDevice = '$workshop/RegisterUnRegisterDeviceId';
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
