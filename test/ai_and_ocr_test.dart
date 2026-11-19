import 'package:flutter_test/flutter_test.dart';
import 'package:mobileapp/services/agent_service.dart';
import 'package:mobileapp/services/n8n_service.dart';

void main() {
  group('PART 1: AI Chatbot Intelligence & Relevance Tests', () {
    test('Question 1: Passport Requirements', () {
      final q = 'বাংলাদেশের পাসপোর্ট করতে কী কী লাগে?';
      final reply = AgentService.getLocalFallbackReply(q, true);

      expect(reply, isNotEmpty);
      expect(reply.contains('পাসপোর্ট'), isTrue);
      expect(reply.contains('এনআইডি') || reply.contains('NID'), isTrue);
      expect(reply.contains('জন্ম নিবন্ধন') || reply.contains('BDRIS'), isTrue);
      // Must not be the generic template
      expect(reply.contains('আমি পাসপোর্ট, জাতীয় পরিচয়পত্র, ডিজিটাল জন্মনিবন্ধন, জমির নামজারি'), isFalse);
    });

    test('Question 2: Youth Training & Unemployed Loans', () {
      final q = 'দ্বিতীয় পাস বেকারদের সরকারি যুব প্রশিক্ষণ ও ঋণ কীভাবে পাব?';
      final reply = AgentService.getLocalFallbackReply(q, true);

      expect(reply, isNotEmpty);
      expect(reply.contains('যুব উন্নয়ন') || reply.contains('প্রশিক্ষণ'), isTrue);
      expect(reply.contains('ঋণ') || reply.contains('৫০,০০০'), isTrue);
      expect(reply.contains('কর্মসংস্থান ব্যাংক') || reply.contains('dyd.gov.bd'), isTrue);
      // Must not be the generic template
      expect(reply.contains('আমি পাসপোর্ট, জাতীয় পরিচয়পত্র, ডিজিটাল জন্মনিবন্ধন, জমির নামজারি'), isFalse);
    });

    test('Question 3: Birth Certificate (English)', () {
      final q = 'How can I register a birth certificate?';
      final reply = AgentService.getLocalFallbackReply(q, false);

      expect(reply, isNotEmpty);
      expect(reply.toLowerCase().contains('birth'), isTrue);
      expect(reply.toLowerCase().contains('bdris') || reply.toLowerCase().contains('hospital'), isTrue);
      // Must not be the generic template
      expect(reply.contains('I can help you with e-Passports, National ID, Birth Registration, Land Records'), isFalse);
    });

    test('Question 4: Driving License Duration', () {
      final q = 'ড্রাইভিং লাইসেন্স করতে কতদিন লাগে?';
      final reply = AgentService.getLocalFallbackReply(q, true);

      expect(reply, isNotEmpty);
      expect(reply.contains('ড্রাইভিং'), isTrue);
      expect(reply.contains('লার্নার') || reply.contains('তাৎক্ষণিক'), isTrue);
      expect(reply.contains('মাস') || reply.contains('দিন'), isTrue);
      // Must not be the generic template
      expect(reply.contains('আমি পাসপোর্ট, জাতীয় পরিচয়পত্র, ডিজিটাল জন্মনিবন্ধন, জমির নামজারি'), isFalse);
    });

    test('Question 5: Computer Science - DFA vs NFA Difference', () {
      final q = 'আমাকে DFA এবং NFA এর পার্থক্য বুঝিয়ে দাও।';
      final reply = AgentService.getLocalFallbackReply(q, true);

      expect(reply, isNotEmpty);
      expect(reply.contains('DFA'), isTrue);
      expect(reply.contains('NFA'), isTrue);
      expect(reply.contains('ট্রানজিশন') || reply.contains('স্টেট'), isTrue);
      expect(reply.contains('ε') || reply.contains('Epsilon'), isTrue);
      // Must not be the generic template
      expect(reply.contains('আমি পাসপোর্ট, জাতীয় পরিচয়পত্র, ডিজিটাল জন্মনিবন্ধন, জমির নামজারি'), isFalse);
    });

    test('Question 6: Follow-up Multi-Turn Context (Second Topic - NFA)', () {
      final history = <({bool isUser, String text})>[
        (isUser: true, text: 'আমাকে DFA এবং NFA এর পার্থক্য বুঝিয়ে দাও।'),
        (
          isUser: false,
          text: 'DFA এবং NFA-এর মধ্যে মূল পার্থক্য:\n১. DFA\n২. NFA এর স্টেট ট্রানজিশন'
        ),
      ];

      final q = 'আগের প্রশ্নের দ্বিতীয় বিষয়টি বিস্তারিত বলো।';
      final reply = AgentService.getLocalFallbackReply(q, true, history: history);

      expect(reply, isNotEmpty);
      expect(reply.contains('NFA'), isTrue);
      expect(reply.contains('Nondeterministic') || reply.contains('ট্রানজিশন') || reply.contains('অটোমাটা'), isTrue);
      // Must not be the generic template
      expect(reply.contains('আমি পাসপোর্ট, জাতীয় পরিচয়পত্র, ডিজিটাল জন্মনিবন্ধন, জমির নামজারি'), isFalse);
    });
  });

  group('PART 2: Universal OCR Engine Normalization & MRZ Tests', () {
    test('Passport OCR & 2-Line ICAO 9303 MRZ Parsing', () {
      const line1 = 'P<BGDISLAM<<MOHAMMAD<RAFIQUL<<<<<<<<<<<<<<<';
      const line2 = 'A012345678BGD9001015M3001014<<<<<<<<<<<<<<02';

      final parsed = MrzParser.parse2LineMrz(line1, line2);
      expect(parsed, isNotNull);
      expect(parsed!['doc_type'], equals('passport'));
      expect(parsed['passport_number'], equals('A01234567'));
      expect(parsed['full_name_en'], equals('MOHAMMAD RAFIQUL ISLAM'));
      expect(parsed['nationality'], equals('BGD'));
      expect(parsed['dob'], equals('1990-01-01'));
      expect(parsed['gender'], equals('M'));
      expect(parsed['expiry_date'], equals('2030-01-01'));

      final normalized = N8nService.normalizeDocumentData({
        'mrz_line1': line1,
        'mrz_line2': line2,
      });

      expect(normalized['passport_number'], equals('A01234567'));
      expect(normalized['id_number'], equals('A01234567'));
      expect(normalized['full_name_en'], equals('MOHAMMAD RAFIQUL ISLAM'));
      expect(normalized['confidence_score'], greaterThanOrEqualTo(85));
    });

    test('NID Front & Back Normalization', () {
      final frontData = N8nService.normalizeDocumentData({
        'name_bn': 'মোঃ রফিকুল ইসলাম',
        'name_en': 'MD RAFIQUL ISLAM',
        'nid_number': '19901234567890123',
        'dob': '1990-01-01',
        'father_name': 'আব্দুল করিম',
      });

      expect(frontData['full_name_bn'], equals('মোঃ রফিকুল ইসলাম'));
      expect(frontData['full_name_en'], equals('MD RAFIQUL ISLAM'));
      expect(frontData['id_number'], equals('19901234567890123'));
      expect(frontData['confidence_score'], greaterThanOrEqualTo(85));

      final backData = N8nService.normalizeDocumentData({
        'address': 'বাসা/হোল্ডিং: ১২, রোড: ৪, ধানমন্ডি, ঢাকা-১২০৫',
        'blood_group': 'B+',
        'issue_date': '15/05/2018',
      });

      expect(backData['address'], contains('ধানমন্ডি'));
      expect(backData['blood_group'], equals('B+'));
      expect(backData['issue_date'], equals('15/05/2018'));
    });

    test('Academic Marksheet & Certificate Normalization', () {
      final academicData = N8nService.normalizeDocumentData({
        'Exam Name': 'Higher Secondary Certificate Examination',
        'Roll Number': '123456',
        'Registration No': '1012345678',
        'Board': 'Dhaka',
        'GPA': '5.00',
        'Passing Year': '2023',
        'Institution': 'Dhaka College',
      });

      expect(academicData['exam_name'], contains('Higher Secondary'));
      expect(academicData['roll'], equals('123456'));
      expect(academicData['reg_no'], equals('1012345678'));
      expect(academicData['board'], equals('Dhaka'));
      expect(academicData['gpa'], equals('5.00'));
      expect(academicData['passing_year'], equals('2023'));
      expect(academicData['institution'], equals('Dhaka College'));
    });

    test('Utility Bill Normalization', () {
      final billData = N8nService.normalizeDocumentData({
        'Account Number': '987654321',
        'Meter Number': 'MTR-554433',
        'Billing Month': 'October 2026',
        'Total Payable': '1,450.00',
        'Due Date': '15/11/2026',
      });

      expect(billData['account_number'], equals('987654321'));
      expect(billData['id_number'], equals('987654321'));
      expect(billData['meter_number'], equals('MTR-554433'));
      expect(billData['bill_month'], equals('October 2026'));
      expect(billData['bill_amount'], equals('1,450.00'));
      expect(billData['due_date'], equals('15/11/2026'));
    });

    test('Driving License Normalization', () {
      final licenseData = N8nService.normalizeDocumentData({
        'License Number': 'DK0123456L',
        'Vehicle Class': 'LIGHT, MOTORCYCLE',
        'Name (English)': 'MD RAFIQUL ISLAM',
        'Blood Group': 'O+',
      });

      expect(licenseData['license_number'], equals('DK0123456L'));
      expect(licenseData['id_number'], equals('DK0123456L'));
      expect(licenseData['vehicle_class'], equals('LIGHT, MOTORCYCLE'));
      expect(licenseData['blood_group'], equals('O+'));
    });
  });
}
