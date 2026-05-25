abstract class OcrService {
  Future<String> extractText();
  Future<void> searchInsidePdf();
  Future<void> exportText();
  Future<void> detectQrOrBarcode();
}
