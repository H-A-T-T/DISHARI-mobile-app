class RequiredDoc {
  final String nameBn;
  final String nameEn;
  final String copyType; // original, photocopy, online, online_print, both
  final String? noteBn;

  RequiredDoc({
    required this.nameBn,
    required this.nameEn,
    required this.copyType,
    this.noteBn,
  });

  factory RequiredDoc.fromJson(Map<String, dynamic> json) {
    return RequiredDoc(
      nameBn: json['name_bn'] ?? '',
      nameEn: json['name_en'] ?? '',
      copyType: json['copy_type'] ?? 'original',
      noteBn: json['note_bn'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name_bn': nameBn,
      'name_en': nameEn,
      'copy_type': copyType,
      'note_bn': noteBn,
    };
  }
}

class ServiceStep {
  final int step;
  final String titleBn;
  final String descriptionBn;
  final String? url;

  ServiceStep({
    required this.step,
    required this.titleBn,
    required this.descriptionBn,
    this.url,
  });

  factory ServiceStep.fromJson(Map<String, dynamic> json) {
    return ServiceStep(
      step: json['step'] is int ? json['step'] : int.tryParse(json['step']?.toString() ?? '1') ?? 1,
      titleBn: json['title_bn'] ?? '',
      descriptionBn: json['description_bn'] ?? '',
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'step': step,
      'title_bn': titleBn,
      'description_bn': descriptionBn,
      'url': url,
    };
  }
}

class Service {
  final String slug;
  final String nameBn;
  final String nameEn;
  final String category;
  final String departmentBn;
  final String departmentEn;
  final String submissionType; // online_bot, pdf_only, hybrid
  final String fee;
  final String? feeNoteBn;
  final String processingTimeBn;
  final String officialUrl;
  final String applyLocationBn;
  final List<RequiredDoc> requiredDocs;
  final List<ServiceStep> steps;
  final List<String> importantNotesBn;
  final List<String> commonMistakesBn;

  Service({
    required this.slug,
    required this.nameBn,
    required this.nameEn,
    required this.category,
    required this.departmentBn,
    required this.departmentEn,
    required this.submissionType,
    required this.fee,
    this.feeNoteBn,
    required this.processingTimeBn,
    required this.officialUrl,
    required this.applyLocationBn,
    required this.requiredDocs,
    required this.steps,
    this.importantNotesBn = const [],
    this.commonMistakesBn = const [],
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    var rawDocs = json['required_docs'];
    List<RequiredDoc> docs = [];
    if (rawDocs is List) {
      docs = rawDocs.map((d) => RequiredDoc.fromJson(Map<String, dynamic>.from(d))).toList();
    }

    var rawSteps = json['steps'];
    List<ServiceStep> steps = [];
    if (rawSteps is List) {
      steps = rawSteps.map((s) => ServiceStep.fromJson(Map<String, dynamic>.from(s))).toList();
    }

    var rawNotes = json['important_notes_bn'];
    List<String> notes = [];
    if (rawNotes is List) {
      notes = rawNotes.map((n) => n.toString()).toList();
    }

    var rawMistakes = json['common_mistakes_bn'];
    List<String> mistakes = [];
    if (rawMistakes is List) {
      mistakes = rawMistakes.map((m) => m.toString()).toList();
    }

    return Service(
      slug: json['slug'] ?? '',
      nameBn: json['name_bn'] ?? '',
      nameEn: json['name_en'] ?? '',
      category: json['category'] ?? 'identity',
      departmentBn: json['department_bn'] ?? '',
      departmentEn: json['department_en'] ?? '',
      submissionType: json['submission_type'] ?? 'hybrid',
      fee: json['fee'] ?? '০',
      feeNoteBn: json['fee_note_bn'],
      processingTimeBn: json['processing_time_bn'] ?? '',
      officialUrl: json['official_url'] ?? '',
      applyLocationBn: json['apply_location_bn'] ?? '',
      requiredDocs: docs,
      steps: steps,
      importantNotesBn: notes,
      commonMistakesBn: mistakes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'name_bn': nameBn,
      'name_en': nameEn,
      'category': category,
      'department_bn': departmentBn,
      'department_en': departmentEn,
      'submission_type': submissionType,
      'fee': fee,
      'fee_note_bn': feeNoteBn,
      'processing_time_bn': processingTimeBn,
      'official_url': officialUrl,
      'apply_location_bn': applyLocationBn,
      'required_docs': requiredDocs.map((d) => d.toJson()).toList(),
      'steps': steps.map((s) => s.toJson()).toList(),
      'important_notes_bn': importantNotesBn,
      'common_mistakes_bn': commonMistakesBn,
    };
  }
}

