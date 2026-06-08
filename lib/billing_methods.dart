import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'providers/child_enrollment_provider.dart';
import 'models/child_model_complete.dart';
import 'models/enrollment_model_complete.dart';
import 'widgets/glass_card.dart';
///
class BillingMethods {
  static Widget buildChildBillingCard(BuildContext context, ChildEnrollmentProvider provider, ChildModel child) {
    final enrollments = provider.getEnrollmentsForChild(child.id);
    final totalDue = provider.getTotalDueForChild(child.id);
    final nextRenewal = provider.getNextRenewalDateForChild(child.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: child.photoUrl != null ? CachedNetworkImageProvider(child.photoUrl!) : null,
                child: child.photoUrl == null ? Text(child.firstName[0]) : null,
              ),
              const SizedBox(width: 12),
              Text(
                child.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              if (totalDue > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${totalDue.toStringAsFixed(0)} DA dû',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                )
              else
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (enrollments.isEmpty)
                  const Text('Aucune inscription active.')
                else
                  ...enrollments.map((e) => buildEnrollmentRow(context, e)),

                if (nextRenewal != null) ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Prochain renouvellement', style: TextStyle(fontSize: 13)),
                      Text(
                        DateFormat('dd/MM/yyyy').format(nextRenewal),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildEnrollmentRow(BuildContext context, EnrollmentModel enrollment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cours #${enrollment.courseId.substring(0, 5)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  'Statut: ${enrollment.paymentStatus.displayName}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${enrollment.totalAmount?.toStringAsFixed(0) ?? "0"} DA',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (enrollment.remainingAmount > 0)
                Text(
                  '-${enrollment.paidAmount?.toStringAsFixed(0) ?? "0"} payé',
                  style: const TextStyle(fontSize: 11, color: Colors.green),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
