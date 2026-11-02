import 'dart:io';

import 'package:Gixa/Modules/Documents/model/DocumentUpdateResponseModel.dart';
import 'package:Gixa/network/api_client.dart';
import 'package:Gixa/network/api_endpoints.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class DocumentApiService {
  // UPLOAD (unchanged)
  Future<Map<String, dynamic>> uploadDocument({
    required File file,
    required String documentType,
    required String documentName,
  }) async {
    return await ApiClient.postMultipart(
      ApiEndpoints.documents,
      file: file,
      fileFieldName: 'files',
      fields: {
        'document_type': documentType,
        'document_name': documentName,
      },
    );
  }

  // ✅ UPDATE (FIXED – RETURNS MODEL)
  Future<DocumentUpdateResponseModel> updateDocument({
    required File file,
    required String documentType,
    required String documentName,
    required int documentId, // 👈 ADD THIS
  }) async {
    final Map<String, dynamic> response = await ApiClient.putMultipartWithFile(
      ApiEndpoints.updateStudentDocument,
      file: file,
      fileFieldName: 'file',
      fields: {
        'document_id': documentId, // 👈 VERY IMPORTANT
        'document_type': documentType,
        'document_name': documentName,
      },
    );

    return DocumentUpdateResponseModel.fromJson(response);
  }

  // ✅ DELETE
  Future<dynamic> deleteDocument({
    required int documentId,
    String? documentType,
    String? documentName,
  }) async {
    return await ApiClient.delete(
      ApiEndpoints.deleteStudentDocument(documentId),
      {
        if (documentType != null) 'document_type': documentType,
        if (documentName != null) 'document_name': documentName,
      },
    );
  }
}
