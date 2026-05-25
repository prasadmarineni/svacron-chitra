abstract class StorageService {
  Future<void> importFromGallery();
  Future<void> importPdf();
  Future<void> exportPdf();
  Future<void> exportJpg();
  Future<void> exportPng();
  Future<void> exportZip();
  Future<void> share();
  Future<void> printFile();
  Future<void> exportToCloud(String provider);
}
