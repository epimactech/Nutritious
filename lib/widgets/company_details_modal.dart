import 'package:flutter/material.dart';
import '../models/company.dart';
import 'company_details.dart';

Future<void> showCompanyDetailsModal(BuildContext context, Company company) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (_) => SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .62,
        minChildSize: .42,
        maxChildSize: .92,
        builder: (_, controller) => SingleChildScrollView(controller: controller, child: CompanyDetails(company: company)),
      ),
    ),
  );
}
