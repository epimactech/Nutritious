import 'package:flutter/material.dart';
import '../models/producer.dart';
import 'producer_details.dart';

Future<void> showProducerDetailsModal(BuildContext context, Producer producer) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .62,
        minChildSize: .42,
        maxChildSize: .92,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          child: ProducerDetails(producer: producer),
        ),
      ),
    ),
  );
}
