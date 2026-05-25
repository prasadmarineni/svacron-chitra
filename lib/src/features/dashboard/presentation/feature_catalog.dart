class FeatureGroup {
  const FeatureGroup({required this.title, required this.items});

  final String title;
  final List<String> items;
}

const featureCatalog = <FeatureGroup>[
  FeatureGroup(
    title: 'Core Scanning',
    items: [
      'Auto edge detection',
      'Manual corner adjustment',
      'Multi-page and batch scanning',
      'Perspective correction, crop, straighten, auto rotate',
      'Shadow, glare reduction and blur warning',
      'Auto enhancement after capture',
    ],
  ),
  FeatureGroup(
    title: 'Image Enhancement',
    items: [
      'Original, Black & White, Magic Color, High Contrast',
      'Grayscale, OCR optimized, low-light enhancement',
      'Brightness, contrast, sharpness and noise reduction',
      'Background whitening and text enhancement',
    ],
  ),
  FeatureGroup(
    title: 'PDF Tools',
    items: [
      'Images to PDF and PDF to Images',
      'Merge, split, rearrange, rotate, delete pages',
      'Compression, password protect, remove password',
      'Watermark, page numbers and digital signature support',
    ],
  ),
  FeatureGroup(
    title: 'OCR and Text',
    items: [
      'OCR text extraction and searchable PDFs',
      'Copy text from image and export to TXT or DOC',
      'Multi-language OCR and QR/barcode detection',
      'Optional handwriting detection in advanced mode',
    ],
  ),
  FeatureGroup(
    title: 'Organization and Security',
    items: [
      'Folders, tags, favorites, recent and trash',
      'Search and sort by date, name, size, folder',
      'App lock, folder lock and hidden sensitive folders',
      'Encrypted PDFs and confidential watermarking',
    ],
  ),
];
