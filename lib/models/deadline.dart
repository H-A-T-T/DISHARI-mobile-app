class CitizenDeadline {
  final String id;
  final String titleBn;
  final String titleEn;
  final String deadline;
  final String category;
  final String urgency; // high, medium, normal
  final String descriptionBn;
  final String descriptionEn;
  final List<String> requiredDocs;
  final String? officialLink;

  CitizenDeadline({
    required this.id,
    required this.titleBn,
    required this.titleEn,
    required this.deadline,
    required this.category,
    required this.urgency,
    required this.descriptionBn,
    required this.descriptionEn,
    required this.requiredDocs,
    this.officialLink,
  });

  factory CitizenDeadline.fromJson(Map<String, dynamic> json) {
    List<String> docs = [];
    if (json['required_docs'] is List) {
      docs = (json['required_docs'] as List).map((d) => d.toString()).toList();
    }

    return CitizenDeadline(
      id: json['id'] ?? '',
      titleBn: json['title_bn'] ?? '',
      titleEn: json['title_en'] ?? '',
      deadline: json['deadline'] ?? '',
      category: json['category'] ?? 'tax',
      urgency: json['urgency'] ?? 'normal',
      descriptionBn: json['description_bn'] ?? '',
      descriptionEn: json['description_en'] ?? '',
      requiredDocs: docs,
      officialLink: json['official_link'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title_bn': titleBn,
      'title_en': titleEn,
      'deadline': deadline,
      'category': category,
      'urgency': urgency,
      'description_bn': descriptionBn,
      'description_en': descriptionEn,
      'required_docs': requiredDocs,
      'official_link': officialLink,
    };
  }

  bool get isUrgent => urgency == 'high';
}

