import 'dart:io';
import 'package:Gixa/Modules/Profile/controllers/profile_controller.dart';
import 'package:Gixa/Modules/ticket/model/ticket_model.dart';
import 'package:Gixa/services/ticket_services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Gixa/common/widgets/app_snackbar.dart';
import 'package:image_picker/image_picker.dart';

class TicketController extends GetxController {
  var subjectError = "".obs;
  var descriptionError = "".obs;

  var isLoading = false.obs;
  var isListLoading = false.obs;
  var isDetailsLoading = false.obs;

  static const String billingPaymentOption = "Billing & Payment";

  static const String profileUpdateOption = "Profile Data Update";

  static const String airRankUpdateOption = "AIR Rank Update";

  static const String categoryUpdateOption = "Category Update";

  static const String neetScoreUpdateOption = "NEET Score Update";

  static const String courseChangeOption = "Course Change Request";

  static const String technicalIssueOption = "Technical Issue";

  static const String appBugOption = "App Bug Report";

  static const String subscriptionIssueOption = "Subscription Issue";

  static const String predictionIssueOption = "College Prediction Issue";

  static const String accountIssueOption = "Account/Login Issue";

  static const String othersOption = "Others";

  var selectedSubjectOption = technicalIssueOption.obs;
  var subject = "".obs;
  var description = "".obs;
  var errorMessage = "".obs;

  final selectedAttachments = <File>[].obs;
  final showAllTickets = false.obs;

  var tickets = <TicketModel>[].obs;

  var selectedTicket = Rxn<TicketDetailsModel>();

  /// CHAT MESSAGE INPUT
  final messageTec = TextEditingController();

  /// REPLY ATTACHMENTS
  final replyAttachments = <File>[].obs;

  /// SEND REPLY LOADING
  final isSendingReply = false.obs;

  @override
  void onInit() {
    super.onInit();
    subject.value = technicalIssueOption;
    fetchTickets();
    _checkLostData();
  }

  Future<void> _checkLostData() async {
    try {
      final response = await ImagePicker().retrieveLostData();
      if (response.isEmpty) return;

      if (response.file != null) {
        final file = File(response.file!.path);
        if (await file.exists()) {
          final fileSize = await file.length();
          if (fileSize <= 500 * 1024) {
            addAttachment(file);
          } else {
            AppSnackbar.show(
              'Error',
              'Recovered image exceeds the 500 KB limit.',
            );
          }
        }
      } else if (response.files != null && response.files!.isNotEmpty) {
        for (final pickedFile in response.files!) {
          final file = File(pickedFile.path);
          if (await file.exists()) {
            final fileSize = await file.length();
            if (fileSize <= 500 * 1024) {
              addAttachment(file);
            }
          }
        }
      }
    } catch (e) {
      print("❌ RETRIEVE LOST DATA ERROR => $e");
    }
  }

  int? get _studentId => Get.find<ProfileController>().profile.value?.user.id;
  String get _studentEmail => Get.find<ProfileController>().email;

  Future<void> fetchTickets() async {
    final id = _studentId;
    if (id == null) return;

    try {
      isListLoading.value = true;

      final data = await TicketService.getTickets(studentId: id);
      tickets.assignAll(data);
    } catch (e) {
      AppSnackbar.show("Error", "Failed to load tickets");
    } finally {
      isListLoading.value = false;
    }
  }

  Future<bool> createTicket() async {
    subjectError.value = "";
    descriptionError.value = "";

    bool hasError = false;

    /// FINAL SUBJECT
    String finalSubject = '';

    if (isOtherSubjectSelected) {
      finalSubject = subject.value.trim();
    } else {
      finalSubject = selectedSubjectOption.value.trim();
    }

    /// SUBJECT VALIDATION
    if (finalSubject.isEmpty) {
      subjectError.value = "Subject is required";

      hasError = true;
    }

    /// DESCRIPTION VALIDATION
    if (description.value.trim().isEmpty) {
      descriptionError.value = "Description is required";

      hasError = true;
    }

    if (hasError) {
      return false;
    }

    final id = _studentId;

    final email = _studentEmail;

    if (id == null || email.isEmpty) {
      AppSnackbar.show("Error", "Profile not loaded");

      return false;
    }

    try {
      isLoading.value = true;

      print('Creating ticket with subject: $finalSubject');

      await TicketService.createTicket(
        studentId: id,

        studentEmail: email,

        /// IMPORTANT
        subject: finalSubject,

        description: description.value.trim(),

        attachment: selectedAttachments.isNotEmpty
            ? selectedAttachments.first
            : null,
      );

      AppSnackbar.show("Success", "Ticket created successfully");

      clearForm();

      await fetchTickets();

      return true;
    } catch (e) {
      print('Create ticket error: ${e.toString()}');

      String errorMessage = 'Failed to create ticket';

      /// FULL RAW ERROR
      final rawError = e.toString().toLowerCase();

      print('RAW ERROR: $rawError');

      /// 413 IMAGE TOO LARGE
      if (rawError.contains('413') ||
          rawError.contains('request entity too large')) {
        errorMessage =
            'Selected image is too large. Please upload a smaller image.';
      }
      /// SOCKET ERROR
      else if (rawError.contains('socketexception')) {
        errorMessage = 'No internet connection. Please try again.';
      }
      /// TIMEOUT
      else if (rawError.contains('timeoutexception')) {
        errorMessage = 'Request timeout. Please try again.';
      }

      AppSnackbar.show("Upload Failed", errorMessage);

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// ============================
  /// ðŸ“„ FETCH TICKET DETAILS
  /// ============================
  Future<bool> fetchTicketDetails(int ticketId) async {
    try {
      isDetailsLoading.value = true;

      final data = await TicketService.getTicketDetails(ticketId);

      selectedTicket.value = data;

      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isDetailsLoading.value = false;
    }
  }

  void setAttachment(File file) {
    selectedAttachments.value = [file];
  }

  void setAttachments(List<File> files) {
    selectedAttachments.value = files;
  }

  void addAttachment(File file) {
    selectedAttachments.add(file);
  }

  void addAttachments(List<File> files) {
    selectedAttachments.addAll(files);
  }

  void removeAttachmentAt(int index) {
    if (index >= 0 && index < selectedAttachments.length) {
      selectedAttachments.removeAt(index);
    }
  }

  /// ============================
  /// 📸 PICK REPLY IMAGE
  /// ============================
  Future<void> pickReplyImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 25,
        maxWidth: 1280,
        maxHeight: 1280,
      );

      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      final size = await file.length();
      print("📸 Picked reply image size: ${size / 1024} KB");

      replyAttachments.add(file);
    } catch (e) {
      print("❌ PICK REPLY IMAGE ERROR => $e");
      AppSnackbar.show("Error", "Failed to pick image");
    }
  }

  /// ============================
  /// 🖼️ PICK MULTIPLE REPLY IMAGES
  /// ============================
  Future<void> pickReplyImages() async {
    try {
      final pickedFiles = await ImagePicker().pickMultiImage(
        imageQuality: 25,
        maxWidth: 1280,
        maxHeight: 1280,
      );

      if (pickedFiles.isEmpty) return;

      for (var picked in pickedFiles) {
        final file = File(picked.path);
        replyAttachments.add(file);
      }
    } catch (e) {
      print("❌ PICK MULTI IMAGE ERROR => $e");
      AppSnackbar.show("Error", "Failed to pick images");
    }
  }

  /// ============================
  /// 📎 PICK REPLY FILES
  /// ============================
  Future<void> pickReplyFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
        allowMultiple: true,
        withData: false,
      );

      if (result == null) return;

      List<File> files = [];
      for (final file in result.files) {
        if (file.path == null || file.path!.isEmpty) continue;
        File f = File(file.path!);
        
        String filename = file.name;
        String ext = "";

        if (filename.contains('.')) {
          ext = filename.split('.').last.toLowerCase();
        } else if (file.extension != null && file.extension!.isNotEmpty && file.extension!.length <= 5) {
          ext = file.extension!.toLowerCase();
        } else {
          // Detect from magic bytes
          try {
            final fileStream = f.openRead(0, 4);
            final List<int> bytes = [];
            await for (var chunk in fileStream) {
               bytes.addAll(chunk);
               if (bytes.length >= 4) break;
            }
            if (bytes.length >= 4 && bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46) {
              ext = 'pdf';
            } else if (bytes.length >= 4 && bytes[0] == 0x50 && bytes[1] == 0x4B && bytes[2] == 0x03 && bytes[3] == 0x04) {
              ext = 'docx'; // PK ZIP format, usually docx/xlsx
            } else if (bytes.length >= 4 && bytes[0] == 0xD0 && bytes[1] == 0xCF && bytes[2] == 0x11 && bytes[3] == 0xE0) {
              ext = 'doc'; // OLE2 format
            } else {
              ext = 'pdf'; // Default fallback
            }
          } catch(e) {
            ext = 'pdf';
          }
        }

        if (!filename.toLowerCase().endsWith('.$ext')) {
          filename = '$filename.$ext';
        }

        if (!f.path.toLowerCase().endsWith('.$ext')) {
          final newPath = '${Directory.systemTemp.path}/$filename';
          f = await f.copy(newPath);
        }

        final size = await f.length();
        if (size > 500 * 1024) {
          AppSnackbar.show(
            "File Too Large",
            "${file.name} exceeds the 500 KB limit. Please upload a smaller document.",
          );
          continue;
        }
        files.add(f);
      }

      if (files.isNotEmpty) {
        replyAttachments.addAll(files);
      }
    } catch (e) {
      print("❌ PICK FILE ERROR => $e");

      AppSnackbar.show("Error", "Failed to pick files");
    }
  }

  /// ============================
  /// ❌ REMOVE REPLY ATTACHMENT
  /// ============================
  void removeReplyAttachment(int index) {
    if (index >= 0 && index < replyAttachments.length) {
      replyAttachments.removeAt(index);
    }
  }

  void clearForm() {
    selectedSubjectOption.value = technicalIssueOption;
    subject.value = technicalIssueOption;
    description.value = "";
    selectedAttachments.clear();
  }

  bool get isOtherSubjectSelected =>
      selectedSubjectOption.value == othersOption;

  void setSubjectOption(String? value) {
    if (value == null) return;

    selectedSubjectOption.value = value;

    subject.value = value == othersOption ? "" : value;
  }

  /// ============================
  /// 💬 SEND TICKET REPLY
  /// ============================
  Future<void> sendReply() async {
    try {
      /// VALIDATION
      if (messageTec.text.trim().isEmpty && replyAttachments.isEmpty) {
        AppSnackbar.show("Error", "Please enter message");

        return;
      }

      final ticket = selectedTicket.value;

      if (ticket == null) {
        AppSnackbar.show("Error", "Ticket not found");

        return;
      }

      final senderId = _studentId;

      if (senderId == null) {
        AppSnackbar.show("Error", "User not found");

        return;
      }

      isSendingReply.value = true;

      /// API CALL
      final response = await TicketService.sendReply(
        ticketId: ticket.ticketId,

        senderId: senderId,

        message: messageTec.text.trim(),

        attachments: replyAttachments,
      );

      print("✅ SEND REPLY => $response");

      /// CLEAR MESSAGE
      messageTec.clear();

      /// CLEAR FILES
      replyAttachments.clear();

      /// REFRESH CHAT
      await fetchTicketDetails(ticket.ticketId);

      AppSnackbar.show("Success", "Reply sent successfully");
    } catch (e) {
      print("❌ SEND REPLY ERROR => $e");

      AppSnackbar.show("Error", e.toString());
    } finally {
      isSendingReply.value = false;
    }
  }
}
