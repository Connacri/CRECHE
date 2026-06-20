import 'package:flutter_test/flutter_test.dart';
import 'package:creche/models/enrollment_model_complete.dart';

void main() {
  group('EnrollmentModel financial logic', () {
    test('remainingAmount calculates correctly', () {
      final enrollment = EnrollmentModel(
        id: '1',
        courseId: 'c1',
        childId: 'ch1',
        parentId: 'p1',
        status: EnrollmentStatus.approved,
        enrolledAt: DateTime.now(),
        paymentStatus: PaymentStatus.partial,
        totalAmount: 1000,
        paidAmount: 400,
      );

      expect(enrollment.remainingAmount, 600);
    });

    test('isFullyPaid returns true when remainingAmount is 0', () {
      final enrollment = EnrollmentModel(
        id: '1',
        courseId: 'c1',
        childId: 'ch1',
        parentId: 'p1',
        status: EnrollmentStatus.approved,
        enrolledAt: DateTime.now(),
        paymentStatus: PaymentStatus.paid,
        totalAmount: 1000,
        paidAmount: 1000,
      );

      expect(enrollment.isFullyPaid, true);
    });
  });
}
