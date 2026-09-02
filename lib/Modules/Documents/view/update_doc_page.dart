import 'package:Gixa/Modules/Documents/view/doc_preview.dart';
import 'package:Gixa/Modules/Documents/view/documents_view.dart';
import 'package:Gixa/Modules/Documents/view/view_documents_page.dart';
import 'package:Gixa/Modules/subscription/controller/subscription_controller.dart';
import 'package:Gixa/Modules/subscription/features/feature_names.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Gixa/Modules/Documents/controller/documents_controller.dart';
import 'package:Gixa/Modules/Documents/controller/view_document_controller.dart';
import 'package:Gixa/Modules/Documents/model/view_documents_model.dart';
import 'package:Gixa/common/widgets/app_snackbar.dart';

class StudentDocumentsUnifiedPage extends StatelessWidget {
  StudentDocumentsUnifiedPage({super.key});

  /// âœ… Added clean display names (NO UI change, just better text)
  String getDisplayName(String docType) {
    switch (docType) {
      case "10th_marksheet":
        return "10th Marksheet";
      case "12th_marksheet":
        return "12th Marksheet";
      case "neet_marksheet":
        return "NEET Marksheet";
      case "aadhar":
        return "Aadhar Card";
      case "pan_card":
        return "PAN Card";
      case "other":
        return "Other Document";
      default:
        return docType.replaceAll("_", " ").toUpperCase();
    }
  }

  bool isLockedDoc(String docType) {
    final subscriptionController = Get.find<SubscriptionController>();

    final isSubscribed = subscriptionController.isSubscribed;

    return !isSubscribed &&
        (docType == "aadhar" || docType == "pan_card" || docType == "other");
  }

  @override
  Widget build(BuildContext context) {
    final DocumentController uploadController = Get.find<DocumentController>();

    final StudentDocumentsController viewController =
        Get.find<StudentDocumentsController>();

    final isDark = Get.isDarkMode;
    final backgroundColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF5F7FB);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(title: const Text("My Documents"), centerTitle: true),
      body: Obx(() {
        if (viewController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        /// Progress Indicator
        final progress =
            viewController.documents.length /
            uploadController.requiredDocuments.length;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "${viewController.documents.length} / ${uploadController.requiredDocuments.length} Documents Uploaded",
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: viewController.refreshDocuments,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  itemCount: uploadController.requiredDocuments.length,
                  itemBuilder: (context, index) {
                    final docType = uploadController.requiredDocuments[index];

                    String normalize(String s) =>
                        s.trim().toLowerCase().replaceAll(RegExp(r'[ _]'), '');

                    final uploadedDoc = viewController.documents
                        .firstWhereOrNull(
                          (doc) =>
                              normalize(doc.documentType) == normalize(docType),
                        );

                    return _buildCard(
                      docType,
                      uploadedDoc,
                      isDark,
                      uploadController,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildCard(
    String docType,
    StudentDocumentModel? doc,
    bool isDark,
    DocumentController uploadController,
  ) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: doc == null
          ? _buildUploadSection(docType, isDark, uploadController)
          : _buildPreviewSection(doc, docType, isDark, uploadController),
    );
  }

  /// Upload UI
  Widget _buildUploadSection(
    String docType,
    bool isDark,
    DocumentController uploadController,
  ) {
    final primaryColor = const Color(0xFF3B82F6);
    final isLocked = isLockedDoc(docType);

    return GetBuilder<DocumentController>(
      builder: (controller) {
        final isUploading =
            controller.isUploading && controller.currentUploadingDoc == docType;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getDisplayName(docType),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),

            const SizedBox(height: 10),

            Stack(
              children: [
                Container(
                  height: 90,
                  width: double.infinity,

                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.07),

                    borderRadius: BorderRadius.circular(10),

                    border: Border.all(color: primaryColor.withOpacity(0.25)),
                  ),

                  child: Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLocked ? Colors.grey : primaryColor,

                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      onPressed: isLocked || isUploading
                          ? (isLocked
                                ? () {
                                    AppSnackbar.show(
                                      "Premium Feature",
                                      "Upgrade your plan to upload this document",
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                  }
                                : null)
                          : () {
                              uploadController.uploadDocument(docType);
                            },

                      icon: isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              isLocked ? Icons.lock : Icons.upload_file,
                              size: 18,
                            ),

                      label: Text(
                        isLocked
                            ? "Locked"
                            : isUploading
                            ? "Uploading..."
                            : "Upload Document",

                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),

                /// LOCK OVERLAY
                if (isLocked)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),

                        borderRadius: BorderRadius.circular(10),
                      ),

                      child: const Center(
                        child: Icon(Icons.lock, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Preview UI
  Widget _buildPreviewSection(
    StudentDocumentModel doc,
    String docType,
    bool isDark,
    DocumentController uploadController,
  ) {
    final primaryColor = const Color(0xFF3B82F6);
    final editColor = Colors.orange;

    final isImage =
        doc.fileUrl.endsWith(".jpg") ||
        doc.fileUrl.endsWith(".png") ||
        doc.fileUrl.endsWith(".jpeg");

    final isPdf = doc.fileUrl.endsWith(".pdf"); // âœ… added

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                doc.documentName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                "Uploaded",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 130,
            width: double.infinity,
            color: Colors.grey.shade200,
            child: isImage
                ? Image.network(doc.fileUrl, fit: BoxFit.cover)
                : isPdf
                ? const Center(
                    child: Icon(
                      Icons.picture_as_pdf,
                      size: 55,
                      color: Colors.red,
                    ),
                  )
                : const Center(child: Icon(Icons.insert_drive_file, size: 55)),
          ),
        ),
        const SizedBox(height: 10),
        GetBuilder<DocumentController>(
          builder: (controller) {
            final isDeleting =
                controller.isDeleting && controller.currentDeletingId == doc.id;

            return Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showDocumentPreview(doc.fileUrl);
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text("View", style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: editColor),
                    onPressed: () {
                      uploadController.updateDocument(docType);
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text("Update", style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: isDeleting
                      ? null
                      : () {
                          _showDeleteConfirmation(uploadController, doc.id);
                        },
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    foregroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.red,
                          ),
                        )
                      : const Icon(Icons.delete_outline, size: 20),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showDeleteConfirmation(
    DocumentController controller,
    int docId,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text("Delete Document?"),
        content: const Text("Are you sure you want to delete this document? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Get.back();
              controller.deleteDocument(docId);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
