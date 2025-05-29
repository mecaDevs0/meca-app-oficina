import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';
import 'package:mega_features/mega_features.dart';

import '../core/core.dart';
import '../modules/bank_account/views/bank_account_view.dart';
import '../modules/change_password/views/change_password_view.dart';
import '../modules/core/bindings/core_binding.dart';
import '../modules/core/views/core_view.dart';
import '../modules/create_service/bindings/create_service_binding.dart';
import '../modules/create_service/views/create_service_view.dart';
import '../modules/edit_profile/bindings/edit_profile_binding.dart';
import '../modules/edit_profile/views/edit_profile_view.dart';
import '../modules/forgot_password/views/forgot_password_view.dart';
import '../modules/help_center/bindings/help_center_binding.dart';
import '../modules/help_center/views/help_center_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/requirements_form.dart';
import '../modules/login/views/login_view.dart';
import '../modules/notification/bindings/notification_binding.dart';
import '../modules/notification/views/notification_detail_view.dart';
import '../modules/notification/views/notification_view.dart';
import '../modules/register/bindings/register_binding.dart';
import '../modules/register/views/register_view.dart';
import '../modules/schedule/bindings/schedule_binding.dart';
import '../modules/schedule/views/config_schedule_view.dart';
import '../modules/send_quote/bindings/send_quote_binding.dart';
import '../modules/send_quote/views/send_quote_view.dart';
import '../modules/service/bindings/service_binding.dart';
import '../modules/service/views/detailed_service_view.dart';
import '../modules/service/views/service_view.dart';
import '../modules/service_details/bindings/service_details_binding.dart';
import '../modules/service_details/views/budget_details_view.dart';
import '../modules/service_details/views/service_details_view.dart';
import '../modules/service_failed/bindings/service_failed_binding.dart';
import '../modules/service_failed/views/dispute_failed_service_view.dart';
import '../modules/service_failed/views/service_failed_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();
  static const initial = Routes.login;
  static final routes = [
    GetPage(
      name: Routes.login,
      page: () => const LoginView(),
      binding: LoginBinding(
        homeRoute: Routes.core,
        pathLogin: BaseUrls.login,
      ),
    ),
    GetPage(
      name: _Paths.forgotPassword,
      page: () => const ForgotPasswordView(),
      binding: ForgotPasswordBinding(
        pathForgotPassword: BaseUrls.forgotPassword,
      ),
    ),
    GetPage(
      name: _Paths.changePassword,
      page: () => const ChangePasswordView(),
      binding: ChangePasswordBinding(
        pathChangePassword: BaseUrls.changePassword,
      ),
    ),
    GetPage(
      name: _Paths.notifications,
      page: () => const NotificationView(),
      binding: AppNotificationBinding(),
    ),
    GetPage(
      name: _Paths.notificationDetail,
      page: () => const NotificationDetailView(),
      binding: AppNotificationBinding(),
    ),
    GetPage(
      name: _Paths.register,
      page: () => const RegisterView(),
      bindings: [
        RegisterBinding(),
        FormAddressBindings(),
      ],
    ),
    GetPage(
      name: _Paths.core,
      page: () => const CoreView(),
      binding: CoreBinding(),
    ),
    GetPage(
      name: _Paths.serviceDetails,
      page: () => const ServiceDetailsView(),
      binding: ServiceDetailsBinding(),
    ),
    GetPage(
      name: _Paths.budgetDetails,
      page: () => const BudgetDetailsView(),
      binding: ServiceDetailsBinding(),
    ),
    GetPage(
      name: _Paths.serviceFailed,
      page: () => const ServiceFailedView(),
      binding: ServiceFailedBinding(),
    ),
    GetPage(
      name: _Paths.disputeFailedService,
      page: () => const DisputeFailedServiceView(),
      binding: ServiceFailedBinding(),
    ),
    GetPage(
      name: _Paths.sendQuote,
      page: () => const SendQuoteView(),
      binding: SendQuoteBinding(),
    ),
    GetPage(
      name: _Paths.bankAccount,
      page: () => const BankAccountView(),
      binding: BankAccountBinding(),
    ),
    GetPage(
      name: _Paths.service,
      page: () => const ServiceView(),
      binding: ServiceBinding(),
    ),
    GetPage(
      name: _Paths.detailedService,
      page: () => const DetailedServiceView(),
      binding: ServiceBinding(),
    ),
    GetPage(
      name: _Paths.configSchedule,
      page: () => const ConfigScheduleView(),
      binding: ScheduleBinding(),
    ),
    GetPage(
      name: _Paths.createService,
      page: () => const CreateServiceView(),
      binding: CreateServiceBinding(),
    ),
    GetPage(
      name: _Paths.editProfile,
      page: () => const EditProfileView(),
      bindings: [
        EditProfileBinding(),
        FormAddressBindings(),
      ],
    ),
    GetPage(
      name: _Paths.helpCenter,
      page: () => const HelpCenterView(),
      binding: HelpCenterBinding(),
    ),
    GetPage(
      name: _Paths.requirementsForm,
      page: () => const RequirementsForm(),
      binding: HomeBinding(),
    ),
  ];
}
