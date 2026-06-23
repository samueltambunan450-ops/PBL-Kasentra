# 📊 INVESTIGASI: PDF LAPORAN KEUANGAN - LIBRARY & KEMAMPUAN

**Date:** June 22, 2026  
**Task:** Investigasi library PDF sebelum redesign total  
**Status:** Investigation Complete

---

## 🔍 LIBRARY YANG DIGUNAKAN

### 1. PDF Generation: `pdf` package v3.11.0
**Package:** https://pub.dev/packages/pdf  
**Capabilities:**
- ✅ Generate PDF natively in Dart (no external dependencies)
- ✅ Support text, tables, images, shapes, gradients
- ✅ Custom layouts with `pw.Container`, `pw.Column`, `pw.Row`
- ✅ Multi-page documents with headers/footers
- ✅ Custom colors (PdfColor/PdfColors)
- ✅ Borders, backgrounds, rounded corners
- ⚠️ **NO native chart/graph support** (no PieChart, BarChart widget)

### 2. PDF Preview/Print: `printing` package v5.11.0
**Package:** https://pub.dev/packages/printing  
**Capabilities:**
- ✅ Preview PDF before saving
- ✅ Print directly to printer
- ✅ Share PDF
- ✅ Save to device

### 3. Charts: `fl_chart` package v0.66.2
**Package:** https://pub.dev/packages/fl_chart  
**Current Usage:** LineChart di UI (screen), NOT di PDF  
**Capabilities:**
- ✅ LineChart, BarChart, PieChart, ScatterChart
- ✅ Animated, interactive
- ⚠️ **Flutter widgets only** - cannot be used directly in PDF

---

## 📁 FILE YANG BERTANGGUNG JAWAB

### Primary File:
**`flutter/lib/screens/financial_report_page.dart`**
- Line 1-5: Import statements (`pdf`, `printing`, `fl_chart`)
- Line 243-380: Method `_exportPdf()` - PDF generation logic
- Line 263-381: PDF structure (current simple layout)

### Current PDF Structure (Before Redesign):
```
Header:
  - "Laporan Keuangan KASENTRA" (title)
  - Periode & Cabang info
  - Divider

Body:
  1. Ringkasan Keuangan (simple table)
     - Modal Awal
     - Total Pemasukan
     - Total Pengeluaran
     - Saldo Akhir
  
  2. Detail Transaksi (single table)
     - Columns: Tanggal, Cabang, Kategori, Jenis, Nominal, Keterangan, Dibuat Oleh
     - All transactions mixed together
  
  3. Catatan (simple text box)
     - Formula explanation
     - Print timestamp

Footer:
  - Page numbers only
```

### Current Limitations:
❌ No visual separation between Pemasukan and Pengeluaran  
❌ No charts/graphs  
❌ No financial analysis metrics  
❌ No narrative generation  
❌ Plain layout (not visually appealing)  
❌ No colored cards/boxes for summary  
❌ No icons (text-only)

---

## 🎨 KEMAMPUAN LIBRARY PDF UNTUK REDESIGN

### ✅ CAN DO (Native Support):

#### 1. Colored Header with Gradient
```dart
pw.Container(
  decoration: pw.BoxDecoration(
    gradient: pw.LinearGradient(
      colors: [PdfColors.green800, PdfColors.green600],
    ),
  ),
  child: pw.Text('KASENTRA', style: pw.TextStyle(color: PdfColors.white)),
)
```

#### 2. Colored Cards/Boxes (5 Summary Cards)
```dart
pw.Row(
  children: [
    pw.Expanded(
      child: pw.Container(
        padding: pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: PdfColors.green50,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.green),
        ),
        child: pw.Column(
          children: [
            pw.Text('Modal Awal'),
            pw.Text('Rp 10.000.000', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    ),
    // ... repeat for other 4 cards
  ],
)
```

#### 3. Side-by-Side Tables (2 columns)
```dart
pw.Row(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    pw.Expanded(child: /* Table Pendapatan */),
    pw.SizedBox(width: 16),
    pw.Expanded(child: /* Table Pengeluaran */),
  ],
)
```

#### 4. Formula Box with Background
```dart
pw.Container(
  padding: pw.EdgeInsets.all(10),
  decoration: pw.BoxDecoration(
    color: PdfColors.grey100,
    borderRadius: pw.BorderRadius.circular(6),
  ),
  child: pw.Text('Laba Bersih = Total Pendapatan − Total Pengeluaran'),
)
```

#### 5. Colored Badges/Status Indicators
```dart
pw.Container(
  padding: pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: pw.BoxDecoration(
    color: laba > 0 ? PdfColors.green : PdfColors.red,
    borderRadius: pw.BorderRadius.circular(12),
  ),
  child: pw.Text(
    laba > 0 ? 'SURPLUS' : 'DEFISIT',
    style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
  ),
)
```

#### 6. Analysis Table with Interpretations
```dart
pw.Table(
  columnWidths: {
    0: pw.FlexColumnWidth(2), // Indikator
    1: pw.FlexColumnWidth(1), // Nilai
    2: pw.FlexColumnWidth(3), // Interpretasi
  },
  children: [
    _buildAnalysisRow('Margin Laba Bersih', '25%', 'Setiap Rp 1 pendapatan...'),
    // ... more rows
  ],
)
```

#### 7. Custom Footer
```dart
footer: (ctx) => pw.Row(
  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
  children: [
    pw.Text('Dicetak pada: ${DateFormat(...).format(DateTime.now())}'),
    pw.Text('Dokumen digenerate otomatis oleh KASENTRA'),
  ],
),
```

---

### ❌ CANNOT DO (No Native Support):

#### 1. Icons (Material Icons, Cupertino Icons)
**Problem:** PDF package doesn't support Flutter icon fonts  
**Solution:** Use Unicode symbols or simple shapes
```dart
// ✅ WORKAROUND:
pw.Text('● Modal Awal')  // Circle bullet
pw.Text('↑ Pendapatan')  // Arrow up
pw.Text('↓ Pengeluaran') // Arrow down
pw.Text('₿ Saldo')       // Currency-like symbol

// OR use colored circles:
pw.Container(
  width: 12,
  height: 12,
  decoration: pw.BoxDecoration(
    shape: pw.BoxShape.circle,
    color: PdfColors.green,
  ),
)
```

#### 2. Pie/Donut Chart (native widget)
**Problem:** No `pw.PieChart` widget exists  
**Solution A (Recommended):** Draw chart manually using `pw.CustomPaint`
```dart
pw.CustomPaint(
  size: PdfPoint(200, 200),
  painter: (canvas, size) {
    // Draw arcs manually for each slice
    double startAngle = 0;
    for (var data in expensesByCategory) {
      final sweepAngle = (data.amount / totalExpense) * 2 * pi;
      canvas.drawArc(
        PdfRect.fromLTWH(0, 0, size.x, size.y),
        startAngle,
        sweepAngle,
        PdfColors.blue,
      );
      startAngle += sweepAngle;
    }
  },
)
```

**Solution B (Alternative):** Pre-render chart as image
```dart
// 1. Render fl_chart PieChart as Flutter widget
// 2. Capture widget to image using RepaintBoundary
// 3. Embed image in PDF
final imageBytes = await widgetToImage(pieChartWidget);
doc.addPage(
  pw.Page(
    build: (ctx) => pw.Image(pw.MemoryImage(imageBytes)),
  ),
);
```

**Recommendation:** Use Solution A (manual drawing) for simplicity and smaller PDF size

---

## 🎯 APPROACH FOR REDESIGN

### Section 1: Header (Brand Green)
- ✅ **Gradient background** - Use `pw.BoxDecoration.gradient`
- ⚠️ **Logo icon** - Use colored circle + text instead of image icon
- ✅ **Typography** - Use `pw.TextStyle` with different sizes/weights

### Section 2: Ringkasan Keuangan (5 Cards)
- ✅ **5 horizontal cards** - Use `pw.Row` with 5 `pw.Expanded` containers
- ⚠️ **Icons** - Use Unicode symbols (●, ↑, ↓, ₹, ₿) or colored circles
- ✅ **Colored borders** - Use `pw.BoxDecoration.border`
- ✅ **Formula box below** - Use colored container

### Section 3: Detail Pendapatan & Pengeluaran (Side by Side)
- ✅ **Two tables side by side** - Use `pw.Row` with 2 `pw.Expanded`
- ✅ **Colored headers** - Green for income, red for expense
- ✅ **Totals row** - Colored background, bold text

### Section 4: Analisis Keuangan
- ✅ **Analysis table** - 3 columns (Indikator, Nilai, Interpretasi)
- ✅ **Conditional formatting** - Green/red based on values
- ✅ **Badge** - SURPLUS/DEFISIT colored badge
- ✅ **Edge case handling** - Show "N/A" when division by zero

### Section 5: Komposisi Pengeluaran
- ⚠️ **Pie/Donut chart** - Use `pw.CustomPaint` to draw manually
- ✅ **Legend** - Table with colored squares + labels + percentages

### Section 6: Catatan Naratif
- ✅ **Dynamic text generation** - Use string interpolation
- ✅ **Logic** - Find max expense category, calculate percentages
- ✅ **Formatted box** - Colored background

### Section 7: Footer
- ✅ **Two columns** - Print date (left) + auto-generated text (right)

---

## 📊 PIE CHART IMPLEMENTATION DECISION

### Option A: Manual Drawing with pw.CustomPaint ✅ RECOMMENDED
**Pros:**
- No dependencies
- Smaller PDF size
- Full control over appearance
- Works on all platforms

**Cons:**
- More code (~50 lines)
- Manual arc calculations

**Code Complexity:** Medium

### Option B: Widget to Image
**Pros:**
- Reuse existing fl_chart code
- Easier to implement

**Cons:**
- Requires RepaintBoundary and rendering context
- Larger PDF size (embedded PNG)
- May have platform issues (web vs mobile)
- Additional dependencies

**Code Complexity:** Low, but more fragile

### 🎯 DECISION: Use Option A (Manual Drawing)
**Reason:** More reliable, smaller PDF, better for production

---

## 🛠️ IMPLEMENTATION PLAN

### Phase 1: Structure & Layout (30 min)
1. Create new PDF structure with 7 sections
2. Implement colored header with gradient
3. Build 5 summary cards layout
4. Add side-by-side tables

### Phase 2: Data Calculations (20 min)
5. Calculate financial metrics (margin, ratio, etc.)
6. Handle edge cases (division by zero)
7. Group expenses by category for chart
8. Generate dynamic narrative text

### Phase 3: Chart Drawing (30 min)
9. Implement pie chart drawing with pw.CustomPaint
10. Add legend with colored indicators
11. Calculate percentages and angles

### Phase 4: Styling & Polish (20 min)
12. Apply brand colors throughout
13. Add Unicode symbols for visual interest
14. Fine-tune spacing and alignment
15. Test with various data scenarios

### Total Estimated Time: ~2 hours

---

## ✅ CONCLUSION

**Library Status:** `pdf` package v3.11.0 is SUFFICIENT for all requirements

**Can Implement:**
- ✅ Colored gradient header
- ✅ 5 summary cards with colors
- ✅ Side-by-side tables
- ✅ Analysis table with interpretations
- ✅ Manual pie chart drawing
- ✅ Dynamic narrative generation
- ✅ Professional styling

**Workarounds Needed:**
- ⚠️ Icons → Use Unicode symbols or colored shapes
- ⚠️ Pie chart → Draw manually with CustomPaint

**No Blockers - Ready to Implement!**

---

**Next Step:** Implement redesign based on user requirements
