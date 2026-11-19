class CitizenDocument {
  final int id;
  final int userId;
  final String docType;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final bool verified;
  final Map<String, dynamic> extractedMeta;
  final String uploadedAt;
  final String? fileData;

  CitizenDocument({
    required this.id,
    required this.userId,
    required this.docType,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.verified,
    this.extractedMeta = const {},
    required this.uploadedAt,
    this.fileData,
  });

  factory CitizenDocument.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> meta = {};
    if (json['extracted_meta'] is Map) {
      meta = Map<String, dynamic>.from(json['extracted_meta']);
    }

    return CitizenDocument(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '1') ?? 1,
      docType: json['doc_type'] ?? 'other',
      fileName: json['file_name'] ?? 'document',
      fileSize: json['file_size'] is int ? json['file_size'] : int.tryParse(json['file_size']?.toString() ?? '0') ?? 0,
      mimeType: json['mime_type'] ?? 'application/pdf',
      verified: json['verified'] == true || json['verified'] == 'true' || json['verified'] == 1,
      extractedMeta: meta,
      uploadedAt: json['uploaded_at'] ?? DateTime.now().toIso8601String(),
      fileData: json['file_data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'doc_type': docType,
      'file_name': fileName,
      'file_size': fileSize,
      'mime_type': mimeType,
      'verified': verified,
      'extracted_meta': extractedMeta,
      'uploaded_at': uploadedAt,
      if (fileData != null) 'file_data': fileData,
    };
  }

  static String getDocTypeName(String type, bool isBn) {
    switch (type) {
      case 'nid_front':
        return isBn ? 'জাতীয় পরিচয়পত্র (সামনের অংশ)' : 'National ID (Front)';
      case 'nid_back':
        return isBn ? 'জাতীয় পরিচয়পত্র (পেছনের অংশ)' : 'National ID (Back)';
      case 'birth_certificate':
        return isBn ? 'ডিজিটাল জন্ম নিবন্ধন সনদ' : 'Digital Birth Certificate';
      case 'educational_transcript':
        return isBn ? 'এডমিট কার্ড / শিক্ষাগত সনদ' : 'Admit Card / Educational Certificate';
      case 'passport':
        return isBn ? 'ই-পাসপোর্ট / বায়োমেট্রিক পাসপোর্ট' : 'e-Passport';
      case 'driving_license':
        return isBn ? 'ড্রাইভিং লাইসেন্স (BRTA)' : 'Driving License (BRTA)';
      case 'utility_bill':
        return isBn ? 'ইউটিলিটি বিল (বিদ্যুৎ/গ্যাস/পানি)' : 'Utility Bill';
      case 'bank_statement':
        return isBn ? 'ব্যাংক স্টেটমেন্ট' : 'Bank Statement';
      case 'academic_certificate':
        return isBn ? 'শিক্ষাগত মূল সনদ / ডিপ্লোমা' : 'Educational Degree / Certificate';
      case 'photo':
        return isBn ? 'পাসপোর্ট সাইজ ছবি' : 'Passport Size Photo';
      case 'tin_certificate':
        return isBn ? 'ই-টিআইএন (e-TIN) সনদ' : 'e-TIN Certificate';
      case 'trade_license':
        return isBn ? 'ই-ট্রেড লাইসেন্স' : 'e-Trade License';
      case 'citizenship_certificate':
        return isBn ? 'নাগরিকত্ব / ওয়ারিশান সনদ' : 'Citizenship / Heir Certificate';
      case 'other':
        return isBn ? 'অন্যান্য প্রত্যয়নপত্র / নথি' : 'Other Certificates / Files';
      default:
        return isBn ? 'অন্যান্য প্রত্যয়নপত্র / নথি' : 'Other Certificates / Files';
    }
  }
}

