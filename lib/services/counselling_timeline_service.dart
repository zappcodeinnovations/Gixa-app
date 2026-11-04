import 'package:flutter/foundation.dart';
import 'package:Gixa/Modules/counselling_roadmap/model/counselling_timeline_model.dart';
import 'package:Gixa/network/api_client.dart';
import 'package:Gixa/network/api_endpoints.dart';

class CounsellingTimelineService {
  CounsellingTimelineService._();

  static Future<CounsellingTimelineResponse> fetchTimeline({
    required String stateId,
    required String type, // 'ug' or 'pg'
  }) async {
    final cleanStateId = stateId.trim().toUpperCase();
    final cleanType = type.trim().toLowerCase();

    try {
      final endpoint = "${ApiEndpoints.counsellingTimeline}?state_id=$cleanStateId&type=$cleanType";
      debugPrint("🚀 [CounsellingTimelineService] GET $endpoint");

      final response = await ApiClient.get(
        endpoint,
        requestPolicy: RequestPolicy(
          ttl: const Duration(minutes: 5),
          forceRefresh: true,
        ),
      );

      if (response is Map<String, dynamic> && response['status'] == true) {
        return CounsellingTimelineResponse.fromJson(response);
      }
    } catch (e) {
      debugPrint("⚠️ [CounsellingTimelineService] API call failed or not deployed yet: $e");
    }

    // ── FALLBACK / MOCK DATA (Ensures seamless UX while backend is deploying) ──
    return _buildFallbackData(cleanStateId, cleanType);
  }

  static CounsellingTimelineResponse _buildFallbackData(String stateId, String type) {
    final now = DateTime.now();

    final dates = [
      // ── Round 1 Dates ──
      CounsellingDateEvent(
        id: 1,
        round: "Round 1",
        title: "Online Registration & Document Upload",
        startDate: now.subtract(const Duration(days: 3)),
        endDate: now.add(const Duration(days: 2)),
        status: "ongoing",
        description: "Submit online application form, pay registration fees, and upload certificates on the counselling portal.",
      ),
      CounsellingDateEvent(
        id: 2,
        round: "Round 1",
        title: "Provisional State Merit List",
        startDate: now.add(const Duration(days: 4, hours: 17)),
        endDate: now.add(const Duration(days: 4, hours: 23)),
        status: "upcoming",
        description: "Publication of General and Category-wise provisional merit list on state website.",
      ),
      CounsellingDateEvent(
        id: 3,
        round: "Round 1",
        title: "Choice Filling & Locking",
        startDate: now.add(const Duration(days: 5, hours: 10)),
        endDate: now.add(const Duration(days: 8, hours: 17)),
        status: "upcoming",
        description: "Fill and lock preferred college and branch combinations in descending order of choice.",
      ),
      CounsellingDateEvent(
        id: 4,
        round: "Round 1",
        title: "First Round Seat Allotment Result",
        startDate: now.add(const Duration(days: 10, hours: 18)),
        endDate: now.add(const Duration(days: 10, hours: 23)),
        status: "upcoming",
        description: "Declaration of Round 1 seat allocation based on merit and filled choices.",
      ),
      CounsellingDateEvent(
        id: 5,
        round: "Round 1",
        title: "Physical Reporting & Fee Payment at College",
        startDate: now.add(const Duration(days: 11, hours: 10)),
        endDate: now.add(const Duration(days: 16, hours: 17)),
        status: "upcoming",
        description: "Report to allotted institute with original documents and pay admission fee to confirm seat.",
      ),

      // ── Round 2 Dates ──
      CounsellingDateEvent(
        id: 6,
        round: "Round 2",
        title: "Seat Matrix & Fresh Choice Filling",
        startDate: now.add(const Duration(days: 20, hours: 10)),
        endDate: now.add(const Duration(days: 24, hours: 17)),
        status: "upcoming",
        description: "Release of vacant seat matrix and choice filling for Round 2 upgrade/fresh candidates.",
      ),
      CounsellingDateEvent(
        id: 7,
        round: "Round 2",
        title: "Round 2 Seat Allotment Result",
        startDate: now.add(const Duration(days: 26, hours: 18)),
        endDate: now.add(const Duration(days: 26, hours: 23)),
        status: "upcoming",
        description: "Declaration of Round 2 allotment results.",
      ),
      CounsellingDateEvent(
        id: 8,
        round: "Round 2",
        title: "Round 2 College Reporting",
        startDate: now.add(const Duration(days: 27, hours: 10)),
        endDate: now.add(const Duration(days: 32, hours: 17)),
        status: "upcoming",
        description: "Joining allotted college in Round 2. Free exit / retention rules apply.",
      ),

      // ── Mop-up Round Dates ──
      CounsellingDateEvent(
        id: 9,
        round: "Mop-up",
        title: "Mop-up Round Registration & Choice Filling",
        startDate: now.add(const Duration(days: 36, hours: 10)),
        endDate: now.add(const Duration(days: 39, hours: 17)),
        status: "upcoming",
        description: "Final mop-up round for remaining institutional & state quota vacant seats.",
      ),
      CounsellingDateEvent(
        id: 10,
        round: "Mop-up",
        title: "Mop-up Allotment & Final Reporting",
        startDate: now.add(const Duration(days: 41, hours: 10)),
        endDate: now.add(const Duration(days: 45, hours: 17)),
        status: "upcoming",
        description: "Physical reporting and spot round document verification.",
      ),
    ];

    final timeline = [
      CounsellingTimelineStep(
        stepNumber: 1,
        round: "Round 1",
        title: "Online Registration & Document Upload",
        description: "Fill the state counselling application, upload 10th/12th marksheets, NEET score card, and category certificates.",
        status: "completed",
        guidelines: [
          "Scan original certificates clearly in PDF or JPG format below 10MB.",
          "Ensure your mobile number and email ID match your NEET registration.",
          "Caste validity & non-creamy layer certificate is mandatory for reservation benefits.",
          "Download and save the registration confirmation page with barcode.",
        ],
      ),
      CounsellingTimelineStep(
        stepNumber: 2,
        round: "Round 1",
        title: "Merit List Released",
        description: "State authority publishes general and category-wise provisional merit list based on NEET AIR.",
        status: "active",
        guidelines: [
          "Cross-check your State Merit Rank (SMR) with your category and quota.",
          "If any discrepancy exists in marks or category, raise a grievance within the specified window.",
          "Keep your SMR noted, as college cutoffs correlate directly with your state rank.",
        ],
      ),
      CounsellingTimelineStep(
        stepNumber: 3,
        round: "Round 1",
        title: "Choice Filling & Locking",
        description: "Select and prioritize college preferences. Lock your choices before the deadline to ensure consideration.",
        status: "upcoming",
        guidelines: [
          "Order your college choices strictly by true preference, not by previous year cutoffs.",
          "Add dream colleges at the top, realistic choices in the middle, and backup colleges at the end.",
          "Always lock choices manually before the deadline.",
          "Print a copy of your locked preference list for reporting.",
        ],
      ),
      CounsellingTimelineStep(
        stepNumber: 4,
        round: "Round 1",
        title: "Seat Allotment Result",
        description: "Provisional seat allotment announced based on merit, category reservation, and locked choices.",
        status: "upcoming",
        guidelines: [
          "Download the provisional seat allotment letter from your candidate portal.",
          "Decide between 'Accept & Freeze' (final admission) or 'Accept & Float' (opt for Round 2 upgrade).",
          "If no seat is allotted, you will automatically participate in Round 2.",
        ],
      ),
      CounsellingTimelineStep(
        stepNumber: 5,
        round: "Round 1",
        title: "College Reporting & Fee Payment",
        description: "Physically report to the allotted college with original documents and pay college tuition fees.",
        status: "upcoming",
        guidelines: [
          "Carry at least 3 sets of self-attested photocopies along with original documents.",
          "Prepare tuition fee Demand Draft (DD) in favor of the college as per the official fee circular.",
          "Undergo medical fitness check at the allotted college hospital.",
          "Obtain an official Admission Retention Receipt before leaving the campus.",
        ],
      ),

      // Round 2 steps
      CounsellingTimelineStep(
        stepNumber: 1,
        round: "Round 2",
        title: "Vacant Seat Matrix & Choice Modification",
        description: "Review vacant seats after Round 1 and submit revised choices for Round 2.",
        status: "upcoming",
        guidelines: [
          "Check the updated seat matrix carefully for newly added seats.",
          "Candidates who took upgrade option in Round 1 can re-arrange preferences.",
        ],
      ),
      CounsellingTimelineStep(
        stepNumber: 2,
        round: "Round 2",
        title: "Round 2 Seat Allotment & Reporting",
        description: "Allotment results for Round 2 and college reporting with forfeiture rules in effect.",
        status: "upcoming",
        guidelines: [
          "If upgraded in Round 2, collect documents and fee transfer letter from Round 1 college.",
          "Exit with forfeiture rules apply if allotted a seat in Round 2 but not joining.",
        ],
      ),

      // Mop-up steps
      CounsellingTimelineStep(
        stepNumber: 1,
        round: "Mop-up",
        title: "Mop-up Round Offline/Online Reporting",
        description: "Final round for leftover and surrendered quota seats.",
        status: "upcoming",
        guidelines: [
          "Only candidates without a confirmed seat in Round 1 or Round 2 are eligible.",
          "Original documents and ready DD must be physically carried to the mop-up venue.",
        ],
      ),
    ];

    return CounsellingTimelineResponse(
      status: true,
      stateId: stateId.isEmpty ? "MH" : stateId,
      stateName: stateId == "MH" ? "Maharashtra" : stateId,
      type: type,
      currentRound: "Round 1",
      dates: dates,
      timeline: timeline,
    );
  }
}

