import 'package:flutter/material.dart';
import 'package:accommodation/domain/models/accommodation_request.dart';
import 'package:accommodation/domain/usecases/create_request_usecase.dart';
import 'package:accommodation/core/utils/prefs.dart';
import 'package:accommodation/data/datasources/request_remote_datasource.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';

import 'package:accommodation/core/utils/notifications.dart';
import 'package:accommodation/core/services/push_notification_service.dart';
import 'package:accommodation/core/services/notification_service.dart';
import 'dart:async';

class NewRequestViewModel extends ChangeNotifier {
  final _uiNotificationController =
      StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get uiNotificationStream =>
      _uiNotificationController.stream;

  void notify(String message, {bool isError = false}) {
    _uiNotificationController.add(AppNotification(message, isError: isError));
  }

  final CreateRequestUseCase useCase;
  final RequestRemoteDataSource remoteDataSource;

  NewRequestViewModel(this.useCase, this.remoteDataSource) {
    // Initialize with one empty member by default so UI doesn't show empty for seconds
    if (members.isEmpty) {
      members.add(AddedMember(name: "", contact: "", email: "", pradesh: ""));
    }
  }

  DateTime? checkIn;
  DateTime? checkOut;

  DateTime get minimumCheckInDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
  }

  bool get isCheckInAllowed =>
      checkIn != null &&
      !DateUtils.dateOnly(checkIn!).isBefore(minimumCheckInDate);

  bool get isCheckOutAllowed =>
      checkIn != null &&
      checkOut != null &&
      !DateUtils.dateOnly(checkOut!).isBefore(DateUtils.dateOnly(checkIn!));

  List<SuggestedMember> suggested = [];

  List<AddedMember> members = [];
  TextEditingController requestNameCtrl = TextEditingController();
  TextEditingController notesCtrl = TextEditingController();

  bool isLoading = false;
  AccommodationRequest? editingRequest;
  bool get isEditing => editingRequest != null;
  bool get canEditAsUser =>
      !isEditing || editingRequest!.status.trim().toUpperCase() == 'PENDING';

  String userPradesh = '';
  bool isAdmin = false;
  List<String> availablePradesh = [];
  bool get shouldLockPradeshToRequester => !isAdmin && userPradesh.isNotEmpty;

  void init(
    AccommodationRequest? request, {
    String? pradesh,
    bool? adminRole,
    List<String>? allPradesh,
  }) {
    if (pradesh != null) userPradesh = pradesh;
    if (adminRole != null) isAdmin = adminRole;

    // Update available pradesh list without resetting the form
    final set = <String>{};
    if (allPradesh != null) set.addAll(allPradesh);
    if (userPradesh.isNotEmpty) set.add(userPradesh);

    // Also include existing pradesh values from members if we are editing
    if (request != null) {
      for (var m in request.members) {
        if (m.pradesh.isNotEmpty) set.add(m.pradesh);
      }
    }

    availablePradesh = set.toList()..sort();

    // Only initialize the form fields if they haven't been initialized yet
    if (request != null && editingRequest == null) {
      editingRequest = request;
      checkIn = request.checkIn;
      checkOut = request.checkOut;
      members = request.members
          .map(
            (m) => AddedMember(
              id: m.id,
              name: m.name,
              contact: m.contact,
              email: m.email,
              pradesh: shouldLockPradeshToRequester ? userPradesh : m.pradesh,
            ),
          )
          .toList();
      notesCtrl.text = request.notes;
      requestNameCtrl.text = request.requestName;
    } else if (shouldLockPradeshToRequester) {
      for (final member in members) {
        member.pradesh = userPradesh;
      }
    } else if (request == null && members.isEmpty) {
      // New request, add default empty member
      members.add(
        AddedMember(name: "", contact: "", email: "", pradesh: userPradesh),
      );
    }

    // Fetch suggestions after edit state is known so admin edit can be filtered
    // to the requester's pradesh.
    if (suggested.isEmpty) {
      _fetchSuggestions(
        pradeshFilter: shouldLockPradeshToRequester ? userPradesh : null,
      );
    }
  }

  Future<void> _fetchSuggestions({String? pradeshFilter}) async {
    final token = await Prefs.getToken();
    if (token == null) return;

    final data = await remoteDataSource.getMemberSuggestions(
      token,
      pradesh: pradeshFilter,
    );
    suggested = data
        .where(
          (m) =>
              pradeshFilter == null ||
              pradeshFilter.isEmpty ||
              (m['pradesh'] ?? '').toString() == pradeshFilter,
        )
        .map((m) {
          final name = m['name'] ?? '';
          final initials = name
              .split(' ')
              .map((e) => e.isNotEmpty ? e[0] : '')
              .take(2)
              .join('')
              .toUpperCase();
          return SuggestedMember(
            name: name,
            initials: initials,
            pradesh: m['pradesh'] ?? '',
            contact: m['contact'] ?? '',
            email: m['email'] ?? '',
          );
        })
        .toList();

    final pradeshSet = {...availablePradesh};
    for (final member in suggested) {
      if (member.pradesh.isNotEmpty) {
        pradeshSet.add(member.pradesh);
      }
    }
    availablePradesh = pradeshSet.toList()..sort();

    notifyListeners();
  }

  void setCheckIn(DateTime date) {
    checkIn = date;
    if (checkOut != null &&
        DateUtils.dateOnly(checkOut!).isBefore(DateUtils.dateOnly(date))) {
      checkOut = null;
    }
    notifyListeners();
  }

  void setCheckOut(DateTime date) {
    checkOut = date;
    notifyListeners();
  }

  void addMember() {
    members.insert(
      0,
      AddedMember(name: "", contact: "", email: "", pradesh: userPradesh),
    );
    notifyListeners();
  }

  void removeMember(int index) {
    members.removeAt(index);
    if (members.isEmpty) {
      members.add(
        AddedMember(name: "", contact: "", email: "", pradesh: userPradesh),
      );
    }
    notifyListeners();
  }

  Future<void> importMembersFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'], // xlsx is most stable for this package
        withData: true,
      );

      if (result != null) {
        final platformFile = result.files.single;
        final extension = platformFile.extension?.toLowerCase();

        if (extension != 'xlsx') {
          throw Exception("Only .xlsx files are supported");
        }

        isLoading = true;
        notifyListeners();

        final fileBytes = platformFile.bytes;
        final filePath = platformFile.path;

        if (fileBytes == null && filePath == null) {
          throw Exception("Could not read file data");
        }

        var bytes = fileBytes ?? await File(filePath!).readAsBytes();
        var excel = Excel.decodeBytes(bytes);

        int importedCount = 0;
        for (var table in excel.tables.keys) {
          var sheet = excel.tables[table];
          if (sheet == null) continue;

          // Process rows, skipping the header (index 0)
          for (int i = 1; i < sheet.maxRows; i++) {
            var row = sheet.rows[i];
            if (row.isEmpty) continue;

            // Extract values safely. excel package returns Data objects
            String name = row.length > 0 ? row[0]?.value?.toString() ?? "" : "";
            String contact = row.length > 1
                ? row[1]?.value?.toString() ?? ""
                : "";
            String pradesh = shouldLockPradeshToRequester
                ? userPradesh
                : row.length > 2
                ? row[2]?.value?.toString() ?? userPradesh
                : userPradesh;

            if (name.trim().isNotEmpty) {
              members.insert(
                0,
                AddedMember(
                  name: name.trim(),
                  contact: contact.trim(),
                  email: "",
                  pradesh: pradesh.trim().isEmpty
                      ? userPradesh
                      : pradesh.trim(),
                ),
              );
              importedCount++;
            }
          }
        }

        if (importedCount > 0) {
          members.removeWhere(
            (m) =>
                m.name.isEmpty &&
                m.contact.isEmpty &&
                m.id == null,
          );

          if (members.isEmpty) {
            members.add(
              AddedMember(
                name: "",
                contact: "",
                email: "",
                pradesh: userPradesh,
              ),
            );
          }
        }

        isLoading = false;
        notify("Imported $importedCount members from Excel");
        notifyListeners();
      }
    } catch (e) {
      isLoading = false;
      notify(
        e.toString().contains("xlsx")
            ? "Please select a valid .xlsx file"
            : "Failed to import Excel data",
        isError: true,
      );
      notifyListeners();
      debugPrint("Excel import error: $e");
    }
  }

  AccommodationRequest? submit() {
    if (requestNameCtrl.text.trim().isEmpty ||
        checkIn == null ||
        checkOut == null ||
        !isCheckInAllowed ||
        !isCheckOutAllowed ||
        members.isEmpty) {
      return null;
    }

    final submittedMembers = members
        .where((m) => m.name.isNotEmpty)
        .map(
          (m) => AddedMember(
            id: m.id,
            name: m.name,
            contact: m.contact,
            email: m.email,
            pradesh: shouldLockPradeshToRequester ? userPradesh : m.pradesh,
          ),
        )
        .toList();

    return AccommodationRequest(
      id: editingRequest?.id,
      userId: editingRequest?.userId,
      requestName: requestNameCtrl.text.trim(),
      checkIn: checkIn!,
      checkOut: checkOut!,
      members: submittedMembers,
      notes: notesCtrl.text,
      notifyEmail: editingRequest?.notifyEmail ?? '',
      status: editingRequest?.status ?? 'PENDING',
      allocations: editingRequest?.allocations ?? const [],
    );
  }

  Future<bool> createRequest(AccommodationRequest request) async {
    isLoading = true;
    notifyListeners();

    final data = {
      "request_name": request.requestName,
      "check_in": request.checkIn.toIso8601String().split('T').first,
      "check_out": request.checkOut.toIso8601String().split('T').first,
      "total_people": request.members.length,
      "notes": request.notes.isNotEmpty ? "${request.notes}\n[SENT_TO_ADMIN]" : "[SENT_TO_ADMIN]",
      "members": request.members
          .map(
            (m) => {
              "name": m.name,
              "contact": m.contact,
              "pradesh": m.pradesh,
              "email": m.email,
            },
          )
          .toList(),
    };

    final token = await Prefs.getToken();
    if (token == null || token.isEmpty) {
      isLoading = false;
      notifyListeners();
      return false;
    }

    final success = await useCase.execute(data, token);

    isLoading = false;
    if (success) {
      notify("Request created successfully!");
      
      // Notify admins about new request (Push)
      PushNotificationService().triggerNotification(
        topic: 'admins',
        title: 'New Request Received',
        body: 'A new accommodation request "${request.requestName}" has been submitted by a user.',
        data: {
          'type': 'NEW_REQUEST',
          'requestName': request.requestName,
        },
      );

      // Notify admins about new request (Real-time in-app)
      NotificationService().sendAdminNotification({
        'userName': request.members.isNotEmpty ? request.members.first.name : 'A user',
        'requestName': request.requestName,
      });
    } else {
      notify(
        "Failed to create request. Please check your connection.",
        isError: true,
      );
    }
    notifyListeners();

    return success;
  }

  Future<bool> updateExistingRequest(
    AccommodationRequest request,
    Future<bool> Function(AccommodationRequest) updater,
  ) async {
    isLoading = true;
    notifyListeners();

    final success = await updater(request);

    isLoading = false;
    notifyListeners();

    return success;
  }
}
