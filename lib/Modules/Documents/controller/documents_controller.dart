import 'dart:io';
import 'package:Gixa/Modules/Profile/controllers/profile_controller.dart';
import 'package:get/get.dart';
import 'package:file_selector/file_selector.dart';
import 'package:Gixa/services/document_api_services.dart';
import 'package:Gixa/network/app_exception.dart';
import 'package:Gixa/Modules/Documents/controller/view_document_controller.dart';
import 'package:Gixa/common/widgets/app_snackbar.dart';

class DocumentController extends GetxController {
  final DocumentApiService _service = DocumentApiService();

  /// âœ… ADD THIS BACK
  final List<String> requiredDocuments = [
    "10th_marksheet",
    "12th_marksheet",
    "neet_marksheet", // âœ… fixed
    "aadhar",
    "pan_card",
    "other",
  ];

  bool isUploading = false;
  bool isDeleting = false;
  String currentUploadingDoc = '';
  int? currentDeletingId;

  final int maxFileSizeMB = 10;

  Future<void> uploadDocument(String docType) async {
    await _pickAndProcess(docType, isUpdate: false);
  }

  Future<void> updateDocument(String docType) async {
    await _pickAndProcess(docType, isUpdate: true);
  }

  Future<void> deleteDocument(int documentId) async {
    try {
      final viewController = Get.find<StudentDocumentsController>();
      final doc =
          viewController.documents.firstWhereOrNull((d) => d.id == documentId);

      if (doc == null) {
        AppSnackbar.show("Error", "Document not found locally.");
        return;
      }

      isDeleting = true;
      currentDeletingId = documentId;
      update();

      await _service.deleteDocument(
        documentId: documentId,
        documentType: doc.documentType,
        documentName: doc.documentName,
      );

      /// Refresh documents list
      await Get.find<StudentDocumentsController>().refreshDocuments();

      /// 🔥 Refresh profile completion
      final profileController = Get.find<ProfileController>();
      await profileController.fetchProfile();

      AppSnackbar.show(
        "Success",
        "Document deleted successfully",
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print("ERROR: $e");
      AppSnackbar.show(
        "Error",
        "Failed to delete document. Please try again.",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isDeleting = false;
      currentDeletingId = null;
      update();
    }
  }

  Future<void> _pickAndProcess(String docType, {required bool isUpdate}) async {
    print(
      '[DEBUG] _pickAndProcess called with docType: $docType, isUpdate: $isUpdate',
    );
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'documents',
      extensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    final XFile? pickedFile = await openFile(acceptedTypeGroups: [typeGroup]);

    if (pickedFile == null) return;

    final file = File(pickedFile.path);

    final sizeInMB = await file.length() / (1024 * 1024);
    if (sizeInMB > maxFileSizeMB) {
      AppSnackbar.show(
        "File Too Large",
        "Maximum allowed size is $maxFileSizeMB MB",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isUploading = true;
    currentUploadingDoc = docType;
    update();

    final documentTypeForBackend = docType;
    final documentName = docType.replaceAll('_', ' ').toUpperCase();

    print('[DEBUG] Before isUpdate check');
    try {
      // Debug: Print what will be sent to backend
      print(
        '[DEBUG] Sending to backend: documentType = "' +
            documentTypeForBackend +
            '", documentName = "' +
            documentName +
            '"',
      );
      if (isUpdate) {
        final viewController = Get.find<StudentDocumentsController>();
        print(
          '[DEBUG] Number of documents in controller: ${viewController.documents.length}',
        );
        // Debug: Print all document types in the list
        print('[DEBUG] Current documents in controller:');
        for (var doc in viewController.documents) {
          print(
            '  - docType: "' + doc.documentType + '", id: ' + doc.id.toString(),
          );
        }
        try {
          print('[DEBUG] Attempting to match docType: "' + docType + '"');
          final existingDoc = viewController.documents.firstWhere((doc) {
            // Normalize both docType and backendType by removing spaces and underscores, and lowercasing
            String normalize(String s) =>
                s.trim().toLowerCase().replaceAll(RegExp(r'[ _]'), '');
            final backendTypeNorm = normalize(doc.documentType);
            final requiredTypeNorm = normalize(docType);
            print(
              '[DEBUG] Comparing backendTypeNorm: "' +
                  backendTypeNorm +
                  '" with requiredTypeNorm: "' +
                  requiredTypeNorm +
                  '"',
            );
            return backendTypeNorm == requiredTypeNorm;
          });
          print(
            '[DEBUG] updateDocument payload: file=${file.path}, documentType="$documentTypeForBackend", documentName="$documentName", documentId=${existingDoc.id}',
          );
          await _service.updateDocument(
            file: file,
            documentType: documentTypeForBackend,
            documentName: documentName,
            documentId: existingDoc.id,
          );
        } catch (e) {
          print(
            '[DEBUG] No matching document found for update. Error: ' +
                e.toString(),
          );
          AppSnackbar.show(
            "Error",
            "No matching document found to update.",
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
      } else {
        await _service.uploadDocument(
          file: file,
          documentType: documentTypeForBackend,
          documentName: documentName,
        );
      }

      /// Refresh documents list
      await Get.find<StudentDocumentsController>().refreshDocuments();

      /// ðŸ”¥ Refresh profile completion
      final profileController = Get.find<ProfileController>();
      await profileController.fetchProfile();

      AppSnackbar.show(
        "Success",
        isUpdate
            ? "Document updated successfully"
            : "Document uploaded successfully",
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print("ERROR: $e");
      AppSnackbar.show(
        "Error",
        "Operation failed. Please try again.",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isUploading = false;
      currentUploadingDoc = '';
      update();
    }
  }
}

