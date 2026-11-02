class StudentDocumentModel {
  final int id;
  final String documentType;
  final String documentName;
  final String fileUrl;
  final bool isVerified;
  final String? status;
  final DateTime uploadedAt;

  StudentDocumentModel({
    required this.id,
    required this.documentType,
    required this.documentName,
    required this.fileUrl,
    this.isVerified = false,
    this.status,
    required this.uploadedAt,
  });

  factory StudentDocumentModel.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status']?.toString();
    final verified = json['is_verified'] == true ||
        json['is_verified'] == 1 ||
        json['verified'] == true ||
        (statusStr != null && statusStr.toLowerCase() == 'verified');

    return StudentDocumentModel(
      id: json['id'],
      documentType: json['document_type'],
      documentName: json['document_name'],
      fileUrl: json['file_url'],
      isVerified: verified,
      status: statusStr,
      uploadedAt: DateTime.parse(json['uploaded_at']),
    );
  }

  bool get isImage =>
      fileUrl.endsWith('.png') ||
      fileUrl.endsWith('.jpg') ||
      fileUrl.endsWith('.jpeg');

  bool get isPdf => fileUrl.endsWith('.pdf');
}
