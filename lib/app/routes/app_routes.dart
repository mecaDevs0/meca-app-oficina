part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const home = _Paths.home;
  static const login = _Paths.login;
  static const forgotPassword = _Paths.forgotPassword;
  static const changePassword = _Paths.changePassword;
  static const notifications = _Paths.notifications;
  static const register = _Paths.register;
  static const core = _Paths.core;
  static const schedule = _Paths.schedule;
  static const financial = _Paths.financial;
  static const profile = _Paths.profile;
  static const serviceDetails = _Paths.serviceDetails;
  static const budgetDetails = _Paths.budgetDetails;
  static const serviceFailed = _Paths.serviceFailed;
  static const disputeFailedService = _Paths.disputeFailedService;
  static const sendQuote = _Paths.sendQuote;
  static const bankAccount = _Paths.bankAccount;
  static const service = _Paths.service;
  static const detailedService = _Paths.detailedService;
  static const configSchedule = _Paths.configSchedule;
  static const createService = _Paths.createService;
  static const editProfile = _Paths.editProfile;
  static const notificationDetail = _Paths.notificationDetail;
  static const helpCenter = _Paths.helpCenter;
  static const requirementsForm = _Paths.requirementsForm;
}

abstract class _Paths {
  _Paths._();
  static const home = '/home';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const changePassword = '/change-password';
  static const notifications = '/notifications';
  static const register = '/register';
  static const core = '/core';
  static const schedule = '/schedule';
  static const financial = '/financial';
  static const profile = '/profile';
  static const serviceDetails = '/service-details';
  static const budgetDetails = '/budget-details';
  static const serviceFailed = '/service-failed';
  static const disputeFailedService = '/dispute-failed-service';
  static const sendQuote = '/send-quote';
  static const bankAccount = '/bank-account';
  static const service = '/service';
  static const detailedService = '/detailed-service';
  static const configSchedule = '/config-schedule';
  static const createService = '/create-service';
  static const editProfile = '/edit-profile';
  static const notificationDetail = '/notification-detail';
  static const helpCenter = '/help-center';
  static const requirementsForm = '/requirements-form';
}
