abstract class PdfService {
  Future<void> imagesToPdf();
  Future<void> pdfToImages();
  Future<void> mergePdfs();
  Future<void> splitPdf();
  Future<void> rearrangePages();
  Future<void> passwordProtect();
  Future<void> removePassword();
  Future<void> addWatermark();
  Future<void> addPageNumbers();
}
