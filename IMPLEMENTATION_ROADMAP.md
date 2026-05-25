# Svacron Chitra - Implementation Roadmap

## Phase 1: ✅ Complete - Camera Pipeline with Edge Detection
**Status**: Implemented May 26, 2026

### Completed Features
- Real-time camera capture with visual guides
- Image enhancement with filters (grayscale, B&W, enhanced, edges)
- Contrast/brightness/saturation adjustments
- Auto crop and straighten
- Image rotation
- Batch image management
- Full integration with scanner page

---

## Phase 2: Advanced Image Filters & Enhancement
**Estimated Duration**: 2-3 days  
**Priority**: HIGH (improves image quality before OCR)

### Requirements
```yaml
# New Dependencies
opencv: ^0.8.0          # Advanced image processing
image_jpeg: ^1.0.0      # JPEG compression control
```

### Components to Create

#### 1. AdvancedFiltersService (`lib/src/core/services/advanced_filters_service.dart`)
```dart
class AdvancedFiltersService {
  // Color correction
  Future<Uint8List> whiteBalance(String imagePath, double temp);
  Future<Uint8List> adjustSaturation(String imagePath, double saturation);
  Future<Uint8List> adjustHue(String imagePath, double hue);
  
  // Shadow/Highlight
  Future<Uint8List> adjustShadows(String imagePath, double amount);
  Future<Uint8List> adjustHighlights(String imagePath, double amount);
  
  // Noise & Sharpness
  Future<Uint8List> denoiseImage(String imagePath);
  Future<Uint8List> sharpenImage(String imagePath, double amount);
  
  // Quality Assessment
  Future<double> detectBlur(String imagePath);
  Future<String> assessImageQuality(String imagePath);
}
```

#### 2. QualityAssessmentScreen (New)
```
UI Elements:
- Quality score display (0-100%)
- Blur warning badge
- Brightness check
- Document detection confidence
- Recommendation messages

Warnings to Show:
- Document edges not detected
- Image too dark/bright
- Possible blur detected
- Small document in frame
```

#### 3. AdvancedEnhancementTab (Update ImageEnhancementScreen)
```
New Tab Section:
- Color Temperature slider (2000K-9000K)
- Saturation slider
- Hue adjustment
- Shadow/Highlight sliders
- Sharpness slider
- Denoise toggle
- Quality assessment button
```

### UI Mockup
```
[Enhanced Filters]
  - Advanced Adjustments Tab
    - Color Temperature: ▬●───── (preset: Daylight)
    - Saturation: ───●──── 
    - Shadows: ──────●──
    - Highlights: ──●─────
    - Sharpness: ────●───
  - Quality Check Card
    - Quality: 92/100 ✓
    - Blur: None ✓
    - Document Detected ✓
    - Ready for OCR ✓
```

### Implementation Flow
1. Create `AdvancedFiltersService` with filter methods
2. Add "Advanced" tab to `ImageEnhancementScreen`
3. Integrate sliders for color/shadow adjustments
4. Implement blur detection algorithm
5. Create quality assessment display
6. Add warning banners
7. Update PDF export to use best quality version

### Testing Checklist
- [ ] Color temperature changes visible
- [ ] Saturation adjustments work
- [ ] Shadows/highlights enhance properly
- [ ] Blur detection alerts on blurry images
- [ ] Quality score updates in real-time
- [ ] Denoising removes artifacts
- [ ] Sharpening enhances text clarity

---

## Phase 3: OCR Integration & Searchable PDFs
**Estimated Duration**: 3-4 days  
**Priority**: HIGH (core feature of app)

### Requirements
```yaml
# Already included
google_mlkit_text_recognition: ^0.15.0

# New
google_mlkit_document_scanner: ^0.10.0
syncfusion_flutter_pdf: ^20.0.0        # Advanced PDF features
```

### Components to Create

#### 1. OcrService (`lib/src/core/services/ocr_service.dart`)
```dart
class OcrService {
  // Text extraction
  Future<String> extractText(String imagePath);
  Future<List<TextBox>> extractTextBoxes(String imagePath);
  
  // Batch OCR
  Future<String> extractTextFromImages(List<String> imagePaths);
  
  // Language support
  Future<void> setLanguage(String languageCode);
  List<String> getSupportedLanguages();
  
  // Confidence metrics
  Future<OcrResult> extractTextWithConfidence(String imagePath);
}

class OcrResult {
  String text;
  double confidence;
  List<TextBox> textBoxes;
  DateTime processedAt;
}

class TextBox {
  String text;
  Rect bounds;
  double confidence;
}
```

#### 2. OcrPage Enhancement
```
New Features:
- Language selector dropdown
- Real-time OCR preview
- Copy to clipboard button
- Search within extracted text
- Export options (TXT, DOCX)
- Confidence score display

Layout:
┌─────────────────────────────┐
│ Language: [English ▼]       │
├─────────────────────────────┤
│ Preview Image    │ OCR Text  │
│ (thumbnail)      │ (editable)│
├─────────────────────────────┤
│ [Copy] [Export] [Search]    │
└─────────────────────────────┘
```

#### 3. SearchableOcrService (`lib/src/core/services/searchable_ocr_service.dart`)
```dart
class SearchableOcrService {
  // Index OCR text
  Future<void> indexOcrText(String docId, String text);
  
  // Full-text search
  Future<List<SearchResult>> search(String query);
  
  // Highlight in original
  Future<List<Rect>> findTextInImage(
    String imagePath, 
    String searchText,
  );
  
  // Export searchable PDF
  Future<String> createSearchablePdf(
    List<String> imagePaths,
    List<String> ocrTexts,
  );
}

class SearchResult {
  String docId;
  String snippet;
  double relevance;
  List<int> matchPositions;
}
```

#### 4. SearchablePdfGenerator (`lib/src/core/services/searchable_pdf_generator.dart`)
```dart
class SearchablePdfGenerator {
  // Create PDF with OCR layer
  Future<String> generateSearchablePdf(
    List<String> imagePaths,
    List<String> ocrTexts,
  );
  
  // Embed OCR text as invisible layer
  // Original image as visible layer
  // Text selectable but invisible
}
```

### UI Components

#### OcrProcessingDialog (New)
```
Displays:
- Page X of Y
- Processing animation
- Estimated time remaining
- Cancel button

Shows real-time OCR confidence
```

#### SearchPdfPage (New Tab in Organize)
```
Search Interface:
- Search bar
- Recent searches
- Search results list with snippet preview
- "View in PDF" button
- "Copy" button per result
```

### Implementation Flow
1. Implement `OcrService` with ML Kit integration
2. Create batch OCR processing
3. Add language selection UI
4. Implement `SearchableOcrService`
5. Create searchable PDF generator
6. Add search UI to organize tab
7. Create search results display
8. Test with various languages

### Testing Checklist
- [ ] Single image OCR extraction
- [ ] Batch OCR processing
- [ ] Language switching works
- [ ] Confidence scores calculated
- [ ] Searchable PDF generated
- [ ] Text layer invisible but searchable
- [ ] Special characters handled
- [ ] Performance acceptable (<2s per page)

---

## Phase 4: Real PDF Editing Engine
**Estimated Duration**: 4-5 days  
**Priority**: MEDIUM (nice-to-have but expected)

### Requirements
```yaml
syncfusion_flutter_pdf: ^20.0.0
pdf_painter: ^2.0.0
advance_pdf_viewer: ^2.0.0
```

### Components to Create

#### 1. PdfEditService (`lib/src/core/services/pdf_edit_service.dart`)
```dart
class PdfEditService {
  // Merge PDFs
  Future<String> mergePdfs(List<String> pdfPaths, String outputName);
  
  // Split PDF
  Future<List<String>> splitPdf(
    String pdfPath, 
    List<int> pageNumbers,
  );
  
  // Reorder pages
  Future<String> reorderPages(String pdfPath, List<int> newOrder);
  
  // Rotate pages
  Future<String> rotatePages(
    String pdfPath,
    List<int> pageNumbers,
    double degrees,
  );
  
  // Compress PDF
  Future<String> compressPdf(String pdfPath);
  
  // Add annotations
  Future<String> addAnnotation(
    String pdfPath,
    int pageNum,
    PdfAnnotation annotation,
  );
  
  // Digital signature
  Future<String> signPdf(String pdfPath, String signerName);
}

class PdfAnnotation {
  String type; // 'text', 'highlight', 'circle', 'line'
  Rect bounds;
  String content;
  Color color;
  DateTime createdAt;
}
```

#### 2. PdfToolsPage Enhancement
```
New Sections:
┌──────────────────────────┐
│ PDF Operations           │
├──────────────────────────┤
│ [Merge] [Split]          │
│ [Rotate] [Reorder]       │
│ [Compress] [Protect]     │
│ [Sign] [Watermark]       │
└──────────────────────────┘

Pages:
- Merge PDFs: Select multiple → Preview → Merge
- Split PDF: Choose pages to split
- Reorder: Drag-drop page ordering
- Rotate: Select pages and rotation angle
- Compress: Choose compression level
```

#### 3. PageReorderingScreen (New)
```
UI:
- PDF page thumbnails in grid
- Drag-drop to reorder
- Delete page button (X on thumbnail)
- Duplicate page button (copy icon)
- Add blank page button
- Preview on the right
- Save button

Supports:
- Drag-drop reordering
- Multi-select with checkboxes
- Quick preview of each page
```

#### 4. PdfAnnotationTools (New Widget)
```
Drawing Tools:
- Text annotation (tap to add text box)
- Highlight (draw rectangle)
- Underline (draw line)
- Circle annotation
- Freehand drawing
- Color picker
- Undo/Redo

Controls:
- Tool selector
- Color palette
- Line width slider
- Clear all button
```

### Implementation Flow
1. Implement `PdfEditService` with pdf package
2. Create merge functionality
3. Create split functionality
4. Implement page reordering UI
5. Add rotate pages feature
6. Implement compression
7. Create annotation tools
8. Add digital signature support
9. Test with various PDF sources

### Testing Checklist
- [ ] Merge 2+ PDFs successfully
- [ ] Split PDF into components
- [ ] Reorder pages maintains content
- [ ] Rotate preserves quality
- [ ] Compress reduces size without losing quality
- [ ] Annotations saved correctly
- [ ] Digital signature works
- [ ] Performance acceptable for large PDFs

---

## Phase 5: Local Database & File Storage
**Estimated Duration**: 3-4 days  
**Priority**: HIGH (necessary for app functionality)

### Requirements
```yaml
sqflite: ^2.3.0           # SQLite database
path_provider: ^2.1.0     # Already included
hive: ^2.2.0              # Fast local storage
hive_flutter: ^1.1.0
```

### Database Schema

```sql
-- Documents Table
CREATE TABLE documents (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  folder_id TEXT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  is_favorite BOOLEAN,
  is_encrypted BOOLEAN,
  ocr_text TEXT,
  file_size INTEGER,
  page_count INTEGER,
  FOREIGN KEY (folder_id) REFERENCES folders(id)
);

-- Document Pages Table
CREATE TABLE document_pages (
  id TEXT PRIMARY KEY,
  document_id TEXT NOT NULL,
  page_number INTEGER,
  image_path TEXT,
  ocr_text TEXT,
  metadata JSON,
  created_at TIMESTAMP,
  FOREIGN KEY (document_id) REFERENCES documents(id)
);

-- Folders Table
CREATE TABLE folders (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  parent_id TEXT,
  is_locked BOOLEAN,
  is_hidden BOOLEAN,
  created_at TIMESTAMP,
  FOREIGN KEY (parent_id) REFERENCES folders(id)
);

-- Tags Table
CREATE TABLE tags (
  id TEXT PRIMARY KEY,
  name TEXT UNIQUE,
  color TEXT,
  created_at TIMESTAMP
);

-- Document-Tag Junction
CREATE TABLE document_tags (
  document_id TEXT,
  tag_id TEXT,
  PRIMARY KEY (document_id, tag_id),
  FOREIGN KEY (document_id) REFERENCES documents(id),
  FOREIGN KEY (tag_id) REFERENCES tags(id)
);

-- Trash Table
CREATE TABLE trash (
  id TEXT PRIMARY KEY,
  document_id TEXT,
  deleted_at TIMESTAMP,
  FOREIGN KEY (document_id) REFERENCES documents(id)
);
```

### Components to Create

#### 1. DatabaseService (`lib/src/core/services/database_service.dart`)
```dart
class DatabaseService {
  // Initialization
  Future<void> initialize();
  
  // Documents
  Future<String> saveDocument(ChitraDocument doc);
  Future<ChitraDocument?> getDocument(String id);
  Future<List<ChitraDocument>> getAllDocuments();
  Future<void> deleteDocument(String id);
  Future<void> updateDocument(ChitraDocument doc);
  
  // Folders
  Future<String> createFolder(String name, String? parentId);
  Future<List<ChitraFolder>> getFolderContents(String folderId);
  Future<void> moveDocument(String docId, String folderId);
  
  // Search
  Future<List<ChitraDocument>> searchDocuments(String query);
  Future<List<ChitraDocument>> searchByTag(String tagName);
  
  // Tags
  Future<void> addTag(String tagName, String color);
  Future<void> tagDocument(String docId, String tagId);
  Future<List<String>> getDocumentTags(String docId);
}
```

#### 2. FileStorageService (`lib/src/core/services/file_storage_service.dart`)
```dart
class FileStorageService {
  // File management
  Future<String> saveImage(XFile image);
  Future<String> savePdf(File pdfFile);
  Future<void> deleteFile(String path);
  
  // Batch operations
  Future<List<String>> batchSaveImages(List<XFile> images);
  
  // File info
  Future<int> getFileSize(String path);
  Future<int> getTotalStorageUsed();
  Future<int> getAvailableStorage();
  
  // Cleanup
  Future<void> cleanupTempFiles();
  Future<void> optimizeStorage();
}
```

#### 3. FolderManagementService (`lib/src/core/services/folder_management_service.dart`)
```dart
class FolderManagementService {
  // Create/Delete folders
  Future<String> createFolder(String name);
  Future<String> createSubfolder(String name, String parentId);
  Future<void> deleteFolder(String folderId);
  Future<void> renameFolder(String folderId, String newName);
  
  // Organization
  Future<void> moveDocumentToFolder(String docId, String folderId);
  Future<List<ChitraDocument>> getDocumentsInFolder(String folderId);
  
  // Lock/Hide
  Future<void> lockFolder(String folderId, String pin);
  Future<void> hideFolder(String folderId);
  Future<bool> verifyFolderPin(String folderId, String pin);
}
```

#### 4. TrashService (`lib/src/core/services/trash_service.dart`)
```dart
class TrashService {
  // Trash management
  Future<void> moveToTrash(String docId);
  Future<List<ChitraDocument>> getTrashItems();
  Future<void> restoreFromTrash(String docId);
  Future<void> permanentlyDelete(String docId);
  Future<void> emptyTrash();
}
```

### UI Components

#### FolderBrowserPage (Update OrganizePage)
```
Features:
- Folder tree view
- Create folder button
- Favorite documents section
- Recent documents
- Trash folder
- Bulk operations (move, delete, tag)

Layout:
┌─────────────────────┐
│ 📁 All Documents    │
│   ├─ 📁 Invoices    │
│   ├─ 📁 Receipts    │
│   └─ 📁 IDs         │
├─────────────────────┤
│ ⭐ Favorites (3)     │
│ 🕐 Recent (5)        │
│ 🗑️  Trash (2)        │
└─────────────────────┘
```

#### DocumentDetailsPage (New)
```
Displays:
- Document preview
- Metadata (size, date, pages)
- Tags
- Folder location
- Edit name
- Move to folder
- Delete/Restore buttons
- Share button
```

#### TrashPage (New)
```
Shows:
- Deleted documents list
- Date deleted
- Original location
- Restore button
- Permanent delete button
- Empty trash button
- Filter by date
```

### Implementation Flow
1. Create SQLite database with migrations
2. Implement `DatabaseService`
3. Implement `FileStorageService`
4. Implement `FolderManagementService`
5. Create folder browser UI
6. Add drag-drop document movement
7. Implement trash functionality
8. Add search integration with database
9. Create backup/restore functionality

### Testing Checklist
- [ ] Database creates successfully
- [ ] Documents saved and retrieved
- [ ] Folder hierarchy works
- [ ] Search returns correct results
- [ ] Tags assigned properly
- [ ] Trash functionality works
- [ ] File storage organized correctly
- [ ] Database queries optimized

---

## Phase 6: Cloud Integration
**Estimated Duration**: 4-5 days  
**Priority**: MEDIUM (nice-to-have)

### Requirements
```yaml
google_sign_in: ^6.1.0
google_maps_flutter: ^2.0.0  # For Google Drive
dropbox_sdk: ^1.0.0
one_drive_sdk: ^1.0.0
firebase_storage: ^11.0.0
```

### Components to Create

#### 1. CloudSyncService (`lib/src/core/services/cloud_sync_service.dart`)
```dart
class CloudSyncService {
  // Generic cloud operations
  Future<void> uploadDocument(String docId);
  Future<void> downloadDocument(String docId);
  Future<void> syncAll();
  Future<void> syncSelective(List<String> docIds);
  
  // Conflict resolution
  Future<void> resolveConflict(
    String docId, 
    CloudVersion local, 
    CloudVersion remote,
  );
  
  // Sync status
  Stream<SyncStatus> getSyncStatus();
  Future<List<String>> getPendingUploads();
}

class SyncStatus {
  final bool isSyncing;
  final int filesProcessed;
  final int totalFiles;
  final String currentFile;
  final DateTime lastSync;
}
```

#### 2. GoogleDriveService (`lib/src/core/services/google_drive_service.dart`)
```dart
class GoogleDriveService {
  // Authentication
  Future<void> authenticate();
  Future<void> signOut();
  Future<bool> isAuthenticated();
  
  // Upload/Download
  Future<String> uploadFile(File file, String folderName);
  Future<void> downloadFile(String fileId, String savePath);
  
  // Folder management
  Future<String> createFolder(String name);
  Future<List<GoogleDriveFile>> listFiles();
}
```

#### 3. DropboxService (`lib/src/core/services/dropbox_service.dart`)
```dart
class DropboxService {
  // Similar to GoogleDriveService
  Future<void> authenticate();
  Future<String> uploadFile(File file, String path);
  Future<void> downloadFile(String path, String savePath);
}
```

#### 4. CloudSettingsPage (Update SettingsPage)
```
UI:
┌─────────────────────────────┐
│ ☁️ Cloud Services           │
├─────────────────────────────┤
│ Google Drive                │
│ ✓ Connected (user@email)    │
│ [Sync Now] [Settings]       │
├─────────────────────────────┤
│ Dropbox                     │
│ ○ Not Connected             │
│ [Connect]                   │
├─────────────────────────────┤
│ OneDrive                    │
│ ○ Not Connected             │
│ [Connect]                   │
├─────────────────────────────┤
│ Auto Sync: [ON/OFF]         │
│ Sync Over WiFi Only: [ON]   │
│ Last Sync: 5 minutes ago    │
└─────────────────────────────┘
```

### Implementation Flow
1. Set up Google Sign-In
2. Implement Google Drive integration
3. Implement Dropbox integration
4. Implement OneDrive integration
5. Create cloud sync manager
6. Add conflict resolution UI
7. Create cloud settings page
8. Add background sync capability

### Testing Checklist
- [ ] Google Drive authentication works
- [ ] Files upload successfully
- [ ] Files download correctly
- [ ] Dropbox integration works
- [ ] OneDrive integration works
- [ ] Sync status displays correctly
- [ ] Conflict resolution works
- [ ] Background sync doesn't drain battery

---

## Recommended Implementation Order

1. **Phase 1** ✅ (Complete) - Core camera pipeline
2. **Phase 2** (Next) - Advanced filters for quality
3. **Phase 3** (After Phase 2) - OCR for text extraction
4. **Phase 4** (After Phase 3) - PDF editing
5. **Phase 5** (After Phase 4) - Local storage & DB
6. **Phase 6** (Final) - Cloud integration

## Development Guidelines

### Code Style
- Follow Dart conventions (dartfmt)
- Use strong typing (avoid dynamic)
- Add documentation comments
- Group imports logically
- Name constants UPPER_CASE_WITH_UNDERSCORES

### Testing
- Unit test services
- Widget test UI components
- Integration test critical flows
- Test error scenarios

### Performance
- Lazy load large lists
- Use pagination for search results
- Compress images before storing
- Cache frequently accessed data
- Profile with Flutter DevTools

### Error Handling
- Show user-friendly error messages
- Log technical details to console
- Provide recovery options
- Never crash silently

---

## Quick Start for Continuing Developer

To continue from Phase 1:

1. Review PHASE_1_IMPLEMENTATION.md
2. Test the current camera pipeline
3. Plan Phase 2 features in detail
4. Start with `AdvancedFiltersService`
5. Update `ImageEnhancementScreen` with new UI
6. Test quality assessment

**Good luck with Phase 2! 🚀**
