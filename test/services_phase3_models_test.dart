import 'package:flutter_test/flutter_test.dart';
import 'package:snapbee_customer_app/features/services/models/service_chat_message.dart';
import 'package:snapbee_customer_app/features/services/models/service_invoice.dart';
import 'package:snapbee_customer_app/features/services/models/service_review.dart';

void main() {
  group('ServiceReview.fromJson', () {
    test('parses rating, trims text, takes the reviewer first name from the embed', () {
      final r = ServiceReview.fromJson({
        'rating': 5,
        'review_text': '  Great job  ',
        'created_at': '2026-09-01T10:00:00Z',
        'customers': {'name': 'Asha Kumar'},
      });
      expect(r.rating, 5);
      expect(r.reviewText, 'Great job');
      expect(r.reviewerName, 'Asha');
    });

    test('null text and missing customer name degrade cleanly', () {
      final r = ServiceReview.fromJson({
        'rating': 4,
        'review_text': '   ',
        'created_at': '2026-09-01T10:00:00Z',
      });
      expect(r.reviewText, isNull);
      expect(r.reviewerName, isNull);
    });
  });

  group('ServiceChatMessage.isMine', () {
    ServiceChatMessage m(String type, String sender) => ServiceChatMessage(
          id: 'x', bookingId: 'b', senderType: type, senderId: sender,
          message: 'hi', mediaUrl: null, createdAt: DateTime(2026, 9, 1),
        );
    test('true only for this customer\'s own messages', () {
      expect(m('customer', 'C1').isMine('C1'), isTrue);
      expect(m('customer', 'C2').isMine('C1'), isFalse);
      expect(m('vendor', 'C1').isMine('C1'), isFalse);
      expect(m('customer', 'C1').isMine(null), isFalse);
    });
    test('senderLabel maps the other roles', () {
      expect(m('vendor', 'v').senderLabel, 'Provider');
      expect(m('technician', 't').senderLabel, 'Technician');
      expect(m('customer', 'c').senderLabel, 'You');
    });
  });

  test('ServiceInvoice.fromJson parses the customer-facing lines', () {
    final inv = ServiceInvoice.fromJson({
      'invoice_number': 'SVC-INV-000042',
      'subtotal': 1200,
      'parts_total': 300,
      'extra_work_total': 0,
      'discount_amount': 100,
      'tax_amount': 252,
      'platform_fee_amount': 50,
      'commission_amount': 180,
      'total_amount': 1652,
      'generated_at': '2026-09-02T12:00:00Z',
    });
    expect(inv.invoiceNumber, 'SVC-INV-000042');
    expect(inv.subtotal, 1200);
    expect(inv.discountAmount, 100);
    expect(inv.totalAmount, 1652);
  });
}
