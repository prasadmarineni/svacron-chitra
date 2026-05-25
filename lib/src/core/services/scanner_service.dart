enum ScannerFilter {
  original,
  blackWhite,
  magicColor,
  highContrast,
  grayscale,
  ocrOptimized,
  lowLight,
}

abstract class ScannerService {
  Future<void> startBatchScan();
  Future<void> autoDetectEdges();
  Future<void> applyPerspectiveCorrection();
  Future<void> warnIfBlurDetected();
}
