class CitizenApplication {
  final int id;
  final String docketId;
  final int userId;
  final String serviceSlug;
  final String serviceNameBn;
  final String serviceNameEn;
  final String status; // ready, submitted, processing, approved
  final Map<String, dynamic> applicantData;
  final List<String> documentsAttached;
  final String feeStatus;
  final String? officialPortalUrl;
  final String submittedAt;
  final String updatedAt;

  CitizenApplication({
    required this.id,
    required this.docketId,
    required this.userId,
    required this.serviceSlug,
    required this.serviceNameBn,
    required this.serviceNameEn,
    required this.status,
    required this.applicantData,
    required this.documentsAttached,
    required this.feeStatus,
    this.officialPortalUrl,
    required this.submittedAt,
    required this.updatedAt,
  });

  factory CitizenApplication.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> applicant = {};
    if (json['applicant_data'] is Map) {
      applicant = Map<String, dynamic>.from(json['applicant_data']);
    } else if (json['applicant_data'] is String) {
      // If backend returned serialized JSON string
      applicant = {'data': json['applicant_data']};
    }

    List<String> docs = [];
    if (json['documents_attached'] is List) {
      docs = (json['documents_attached'] as List).map((d) => d.toString()).toList();
    }

    return CitizenApplication(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      docketId: json['docket_id'] ?? 'BD-APP-2026-00000',
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '1') ?? 1,
      serviceSlug: json['service_slug'] ?? '',
      serviceNameBn: json['service_name_bn'] ?? '',
      serviceNameEn: json['service_name_en'] ?? '',
      status: json['status'] ?? 'ready',
      applicantData: applicant,
      documentsAttached: docs,
      feeStatus: json['fee_status'] ?? 'unpaid',
      officialPortalUrl: json['official_portal_url'],
      submittedAt: json['submitted_at'] ?? DateTime.now().toIso8601String(),
      updatedAt: json['updated_at'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'docket_id': docketId,
      'user_id': userId,
      'service_slug': serviceSlug,
      'service_name_bn': serviceNameBn,
      'service_name_en': serviceNameEn,
      'status': status,
      'applicant_data': applicantData,
      'documents_attached': documentsAttached,
      'fee_status': feeStatus,
      'official_portal_url': officialPortalUrl,
      'submitted_at': submittedAt,
      'updated_at': updatedAt,
    };
  }

  String getStatusDisplay(bool isBn) {
    switch (status) {
      case 'ready':
        return isBn ? 'ডকেট প্রস্তুত' : 'Docket Ready';
      case 'submitted':
        return isBn ? 'দাখিলকৃত' : 'Submitted';
      case 'processing':
        return isBn ? 'যাচাই প্রক্রিয়াধীন' : 'Processing';
      case 'approved':
        return isBn ? 'অনুমোদিত' : 'Approved';
      default:
        return status;
    }
  }
}

