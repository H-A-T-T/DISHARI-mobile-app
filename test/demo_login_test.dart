import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobileapp/providers/auth_provider.dart';
import 'package:mobileapp/providers/dashboard_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Demo Citizen Login & Dashboard Seed Tests', () {
    test('loginAsDemoCitizen sets correct citizen credentials', () async {
      final auth = AuthProvider();
      await auth.loginAsDemoCitizen();

      expect(auth.isLoggedIn, isTrue);
      expect(auth.citizenId, 'BD-USER-782');
      expect(auth.user?.fullName, 'আহমেদ জামিল');
      expect(auth.user?.email, 'jamil.citizen@dishari.bd');
      expect(auth.user?.phone, '+8801712345678');
    });

    test('seedDemoData populates 5 verified documents and 2 dockets', () async {
      final dashboard = DashboardProvider();
      await dashboard.seedDemoData();

      expect(dashboard.documents.length, equals(5));
      expect(dashboard.applications.length, equals(2));
      expect(dashboard.completenessPercent, equals(100));

      // Verify specific document types exist
      final docTypes = dashboard.documents.map((d) => d.docType).toSet();
      expect(docTypes.contains('nid_front'), isTrue);
      expect(docTypes.contains('nid_back'), isTrue);
      expect(docTypes.contains('birth_certificate'), isTrue);
      expect(docTypes.contains('photo'), isTrue);
      expect(docTypes.contains('tin_certificate'), isTrue);

      // Verify applications
      expect(dashboard.applications.first.docketId, contains('BD-APP-'));
      expect(dashboard.applications.first.serviceSlug, equals('passport'));
    });

    test('clearSessionData properly resets documents and applications', () async {
      final dashboard = DashboardProvider();
      await dashboard.seedDemoData();
      expect(dashboard.documents.isNotEmpty, isTrue);

      await dashboard.clearSessionData();
      expect(dashboard.documents.isEmpty, isTrue);
      expect(dashboard.applications.isEmpty, isTrue);
      expect(dashboard.activeTab, equals(0));
    });
  });
}
