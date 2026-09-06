// ============================================================================
// invoice_delivery.dart
// ----------------------------------------------------------------------------
// Thin wrapper over the `printing` plugin for the three platform actions a
// generated invoice PDF supports:
//   * print    -> Printing.layoutPdf   (OS print dialog; browser print on web)
//   * share    -> Printing.sharePdf    (share sheet on mobile; download on web)
//   * download -> Printing.sharePdf    (mobile share sheet has "Save to Files";
//                                       web downloads the file directly)
//
// `Printing.info()` reports what the current platform can actually do, so the
// UI can hide an action rather than fail it.
// ============================================================================

import 'dart:typed_data';

import 'package:printing/printing.dart';

import 'invoice.dart';
import 'invoice_pdf.dart';

class InvoicePlatformCapabilities {
  final bool canPrint;
  final bool canShare;
  final bool canPreview; // rasterisation (pdf.js on web) available

  const InvoicePlatformCapabilities({
    required this.canPrint,
    required this.canShare,
    required this.canPreview,
  });

  static Future<InvoicePlatformCapabilities> detect() async {
    try {
      final info = await Printing.info();
      return InvoicePlatformCapabilities(
        canPrint: info.canPrint,
        canShare: info.canShare,
        canPreview: info.canRaster,
      );
    } catch (_) {
      return const InvoicePlatformCapabilities(
        canPrint: false,
        canShare: false,
        canPreview: false,
      );
    }
  }
}

class InvoiceDelivery {
  InvoiceDelivery(this.invoice, this.bytes);

  final Invoice invoice;
  final Uint8List bytes;

  static Future<InvoiceDelivery> forInvoice(Invoice invoice) async {
    final bytes = await InvoicePdf.build(invoice);
    return InvoiceDelivery(invoice, bytes);
  }

  String get fileName {
    final safe = invoice.invoiceNumber.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return 'SnapBee_Invoice_$safe.pdf';
  }

  Future<void> printDocument() => Printing.layoutPdf(
        name: fileName,
        onLayout: (_) async => bytes,
      );

  Future<bool> share() => Printing.sharePdf(bytes: bytes, filename: fileName);

  /// On web this saves the file to the browser's downloads; on mobile it
  /// opens the share sheet whose "Save to Files" is the download path.
  Future<bool> download() => Printing.sharePdf(bytes: bytes, filename: fileName);
}
