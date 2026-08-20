import 'package:flutter/foundation.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';

class AppsFlyerService {
  AppsFlyerService._();
  static final AppsFlyerService instance = AppsFlyerService._();

  AppsflyerSdk? _sdk;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    try {
      final options = AppsFlyerOptions(
        afDevKey: 'EJgci2EGWpS69K5FNqdFcS',
        appId: '6743011627',
        showDebug: kDebugMode,
        timeToWaitForATTUserAuthorization: 10,
      );

      _sdk = AppsflyerSdk(options);

      _sdk!.onInstallConversionData((data) {
        if (kDebugMode) print('[AppsFlyer] Install conversion data: $data');
        _handleDeferredDeepLink(data);
      });

      _sdk!.onAppOpenAttribution((data) {
        if (kDebugMode) print('[AppsFlyer] App open attribution: $data');
      });

      _sdk!.onDeepLinking((DeepLinkResult result) {
        if (kDebugMode) print('[AppsFlyer] Deep link: ${result.status}');
        if (result.status == Status.FOUND) {
          final deepLink = result.deepLink;
          if (deepLink == null) return;

          final screen = deepLink.getStringValue('screen') ?? '';
          final id = deepLink.getStringValue('id') ?? '';
          final nav = MecaOficinaApp.navigatorKey.currentState;
          if (nav == null) return;

          switch (screen) {
            case 'booking':
              if (id.isNotEmpty) {
                nav.pushNamed('/booking-detail', arguments: {'id': id});
              }
              break;
            case 'dashboard':
              nav.pushNamed('/core');
              break;
          }
        }
      });

      await _sdk!.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: true,
      );

      _initialized = true;
      if (kDebugMode) print('[AppsFlyer] SDK initialized (oficina)');
    } catch (e) {
      if (kDebugMode) print('[AppsFlyer] Init error: $e');
    }
  }

  void setCustomerUserId(String id) {
    try {
      _sdk?.setCustomerUserId(id);
    } catch (e) {
      if (kDebugMode) print('[AppsFlyer] setCustomerUserId error: $e');
    }
  }

  void clearCustomerUserId() {
    try {
      _sdk?.setCustomerUserId('');
    } catch (e) {
      if (kDebugMode) print('[AppsFlyer] clearCustomerUserId error: $e');
    }
  }

  // ── Deferred Deep Linking ──

  void _handleDeferredDeepLink(Map? data) {
    try {
      if (data == null) return;
      final payload = data['payload'] as Map? ?? data;

      final isFirstLaunch = payload['is_first_launch'];
      if (isFirstLaunch != true && isFirstLaunch != 'true') return;

      final screen = payload['af_dp']?.toString() ?? payload['screen']?.toString();
      final id = payload['id']?.toString();
      if (screen == null) return;

      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('af_deferred_screen', screen);
        if (id != null) prefs.setString('af_deferred_id', id);
      });
    } catch (e) {
      if (kDebugMode) print('[AppsFlyer] Deferred deep link error: $e');
    }
  }

  Future<void> applyDeferredDeepLink() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final screen = prefs.getString('af_deferred_screen');
      if (screen == null) return;

      final id = prefs.getString('af_deferred_id');
      await prefs.remove('af_deferred_screen');
      await prefs.remove('af_deferred_id');

      final nav = MecaOficinaApp.navigatorKey.currentState;
      if (nav == null) return;

      switch (screen) {
        case 'booking':
          if (id != null && id.isNotEmpty) {
            nav.pushNamed('/booking-detail', arguments: {'id': id});
          }
          break;
        case 'dashboard':
          nav.pushNamed('/core');
          break;
      }
    } catch (e) {
      if (kDebugMode) print('[AppsFlyer] Apply deferred deep link error: $e');
    }
  }

  Future<void> _logEvent(String name, Map<String, dynamic> params) async {
    try {
      await _sdk?.logEvent(name, params);
      if (kDebugMode) print('[AppsFlyer] Event: $name');
    } catch (e) {
      if (kDebugMode) print('[AppsFlyer] logEvent($name) error: $e');
    }
  }

  Future<void> logRegistration(String method, String workshopId) =>
      _logEvent('af_complete_registration', {
        'af_registration_method': method,
        'workshop_id': workshopId,
      });

  Future<void> logLogin(String workshopId) =>
      _logEvent('af_login', {
        'af_customer_user_id': workshopId,
      });

  Future<void> logBookingAccepted(String bookingId, String customerId) =>
      _logEvent('meca_booking_accepted', {
        'af_content_id': bookingId,
        'customer_id': customerId,
      });

  Future<void> logServiceStarted(String bookingId) =>
      _logEvent('meca_service_started', {
        'af_content_id': bookingId,
      });

  Future<void> logServiceCompleted(String bookingId, double amount) =>
      _logEvent('meca_service_completed', {
        'af_content_id': bookingId,
        'af_revenue': amount,
        'af_currency': 'BRL',
      });

  Future<void> logPaymentReceived(String bookingId, double workshopAmount) =>
      _logEvent('af_purchase', {
        'af_revenue': workshopAmount,
        'af_currency': 'BRL',
        'af_content_id': bookingId,
      });

  Future<void> logQuoteSent(String bookingId, double estimatedPrice) =>
      _logEvent('meca_quote_sent', {
        'af_content_id': bookingId,
        'af_price': estimatedPrice,
        'af_currency': 'BRL',
      });

  Future<void> logFinancialOnboarding(String workshopId) =>
      _logEvent('meca_financial_onboarding', {
        'workshop_id': workshopId,
      });

  Future<void> logEvidenceUploaded(String bookingId, String evidenceType) =>
      _logEvent('meca_evidence_uploaded', {
        'af_content_id': bookingId,
        'evidence_type': evidenceType,
      });
}
