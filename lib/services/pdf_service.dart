import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter/services.dart' show rootBundle;

class PDFDocument {
  final String name;
  final String content;
  final DateTime uploadedAt;

  PDFDocument({
    required this.name,
    required this.content,
    required this.uploadedAt,
  });
}

class PDFService {
  
  // Assets에서 PDF 파일들을 자동으로 로드하는 메서드
  Future<String> loadAssetPDFs() async {
    try {
      developer.log('Assets PDF 로드 시작', name: 'PDFService');
      
      List<String> pdfAssets = [
        'assets/pdfs/2025_Spring_PPT.pdf',
        'assets/pdfs/2025_OTbook.pdf',
      ];
      
      String combinedContext = '';
      
      for (int i = 0; i < pdfAssets.length; i++) {
        try {
          // Asset에서 PDF 바이트 로드
          final ByteData pdfData = await rootBundle.load(pdfAssets[i]);
          final Uint8List pdfBytes = pdfData.buffer.asUint8List();
          
          // 텍스트 추출
          final String extractedText = await extractTextFromPDF(pdfBytes);
          
          // 디버깅: 추출된 텍스트의 처음 500자 출력
          String preview = extractedText.length > 500 ? extractedText.substring(0, 500) : extractedText;
          developer.log('PDF ${i + 1} 텍스트 미리보기: $preview', name: 'PDFService');
          
          // Add to context (including filename)
          String fileName = pdfAssets[i].split('/').last;
          combinedContext += '=== Document ${i + 1}: $fileName ===\n';
          
          // Pro version: More text usage available (relaxed token limits)
          String limitedText = extractedText.length > 50000 ? 
            '${extractedText.substring(0, 50000)}\n\n[Text partially omitted...]' : extractedText;
          
          combinedContext += '$limitedText\n\n';
          
          developer.log('PDF ${i + 1} 로드 완료: ${pdfAssets[i]}, 원본 텍스트 길이: ${extractedText.length}자, 사용된 텍스트 길이: ${limitedText.length}자', name: 'PDFService');
        } catch (e) {
          developer.log('PDF ${i + 1} 로드 실패: ${pdfAssets[i]} - $e', name: 'PDFService');
          // Add warning text for individual file load failure
          combinedContext += '=== Document ${i + 1} (Load Failed) ===\n';
          combinedContext += 'Unable to load document.\n\n';
        }
      }
      
      developer.log('모든 Assets PDF 로드 완료. 총 컨텍스트 길이: ${combinedContext.length}', name: 'PDFService');
      
      return combinedContext;
    } catch (e) {
      developer.log('Assets PDF 로드 오류: $e', name: 'PDFService');
      throw Exception('Unable to load PDF documents: $e');
    }
  }
  


  // PDF에서 텍스트 추출
  Future<String> extractTextFromPDF(Uint8List pdfBytes) async {
    try {
      developer.log('PDF 텍스트 추출 시작', name: 'PDFService');
      
      // PDF 문서 로드
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
      
      String extractedText = '';
      
      // 각 페이지에서 텍스트 추출
      for (int i = 0; i < document.pages.count; i++) {
        final String pageText = PdfTextExtractor(document).extractText(startPageIndex: i, endPageIndex: i);
        extractedText += '$pageText\n\n';
        
        developer.log('페이지 ${i + 1} 텍스트 추출 완료', name: 'PDFService');
      }
      
      // 문서 해제
      document.dispose();
      
      // 텍스트 정리
      extractedText = _cleanText(extractedText);
      
      developer.log('PDF 텍스트 추출 완료. 총 글자 수: ${extractedText.length}', name: 'PDFService');
      
      if (extractedText.trim().isEmpty) {
        throw Exception('Unable to extract text from PDF. It may be an image or scanned PDF.');
      }
      
      return extractedText;
    } catch (e) {
      developer.log('PDF 텍스트 추출 오류: $e', name: 'PDFService');
      throw Exception('PDF text extraction failed: $e');
    }
  }



  // 텍스트 정리 함수
  String _cleanText(String text) {
    // 불필요한 공백 및 특수문자 정리
    text = text.replaceAll(RegExp(r'\s+'), ' '); // 연속된 공백을 하나로
    text = text.replaceAll(RegExp(r'\n\s*\n'), '\n\n'); // 연속된 줄바꿈 정리
    text = text.trim();
    
    return text;
  }


} 