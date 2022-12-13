import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:native_pdf_renderer/native_pdf_renderer.dart';
import 'package:vs_scrollbar/vs_scrollbar.dart';
import 'dart:io';

import 'pdf_controller.dart';
import 'pdf_info.dart';
import 'pdf_page_view.dart';

typedef OnPageChanged = void Function(int);

class AssetPdfViewer extends StatefulWidget {
  final String assetPath;
  final Axis scrollDirection;
  final PdfController? pdfController;
  final OnPageChanged? onPageChanged;
  final ColorMode colorMode;

  const AssetPdfViewer({
    Key? key,
    required this.assetPath,
    this.scrollDirection = Axis.vertical,
    this.pdfController,
    this.onPageChanged,
    this.colorMode = ColorMode.day,
  }) : super(key: key);

  @override
  _AssetPdfViewerState createState() => _AssetPdfViewerState();
}

class _AssetPdfViewerState extends State<AssetPdfViewer> {
  ScrollController? _scrollController;
  late final Future<PdfInfo> pdfInfo;
  late final int initialPage;
  bool isNeedScrollToTop = false;

  late int currentPageIndex;

  @override
  void initState() {
    super.initState();
    pdfInfo = _loadPdf(widget.assetPath);
    initialPage = widget.pdfController?.intialPage ?? 1;
    currentPageIndex = initialPage - 1;
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _gotoTopOfpage());
    //
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final parentWidth = constraints.maxWidth;
        final parentHeight = constraints.maxHeight;

        if (parentHeight < parentWidth) {
          isNeedScrollToTop = true && widget.scrollDirection == Axis.vertical;
        }

        return FutureBuilder(
          future: pdfInfo,
          builder: (BuildContext context, AsyncSnapshot<PdfInfo> snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text('Something worng'));
            }
            final pdfInfo = snapshot.data!;
            double viewportFraction = findViewportFraction(
                scrollAxis: widget.scrollDirection,
                parentWidth: parentWidth,
                parentHeight: parentHeight,
                pdfWidth: pdfInfo.width,
                pdfHeight: pdfInfo.height);

            _scrollController = PageController(
                initialPage: initialPage - 1,
                viewportFraction: viewportFraction);

            widget.pdfController
                ?.attachController(_scrollController as PageController);

            return Focus(
                onKey: (node, event) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                    if (widget.scrollDirection == Axis.horizontal) {
                      widget.pdfController
                          ?.gotoPage((currentPageIndex + 1) - 1);
                    }

                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                    if (widget.scrollDirection == Axis.horizontal) {
                      widget.pdfController
                          ?.gotoPage((currentPageIndex + 1) + 1);
                    }

                    return KeyEventResult.handled;
                  }

                  if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    if (widget.scrollDirection == Axis.vertical) {
                      final offset = _scrollController?.offset;
                      if (offset != null) {
                        _scrollController
                            ?.jumpTo(offset - 330); // just estimate
                      }
                    }

                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    if (widget.scrollDirection == Axis.vertical) {
                      final offset = _scrollController?.offset;
                      if (offset != null) {
                        _scrollController
                            ?.jumpTo(offset + 330); // just estimate
                      }
                    }

                    return KeyEventResult.handled;
                  }

                  return KeyEventResult.ignored;
                },
                child: _buildPdfView(context, pdfInfo, initialPage));
          },
        );
      },
    );
  }

  Widget _buildPdfView(
    BuildContext context,
    PdfInfo pdfInfo,
    int initialPage,
  ) {
    final scaleEnabled = (Platform.isAndroid || Platform.isIOS) ? true : false;
    return VsScrollbar(
      style: const VsScrollbarStyle(
        thickness: 24,
        color: Color.fromARGB(255, 0, 69, 104),
      ),
      controller: _scrollController,
      child: InteractiveViewer(
        scaleEnabled: scaleEnabled,
        child: PageView.builder(
            controller: _scrollController as PageController,
            scrollDirection: widget.scrollDirection,
            pageSnapping:
                widget.scrollDirection == Axis.horizontal ? true : false,
            onPageChanged: (index) {
              widget.onPageChanged?.call(index + 1);
              currentPageIndex = index;
            },
            itemCount: pdfInfo.pageCount,
            itemBuilder: (context, index) {
              return Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.all(1),
                // padding: const EdgeInsets.all(1),
                color: _getBackGroundColor(widget.colorMode),
                child: PdfPageView(
                  pdfDocument: pdfInfo.document,
                  pageNumber: index + 1,
                  colorMode: widget.colorMode,
                ),
              );
            }),
      ),
    );
  }

  Future<PdfInfo> _loadPdf(String assetPath) async {
    final doc = await PdfDocument.openAsset(assetPath);
    final pageCount = doc.pagesCount;
    final page = pageCount > 55 ? await doc.getPage(55) : await doc.getPage(2);
    final width = page.width;
    final height = page.height;
    page.close();

    return PdfInfo(doc, pageCount, width, height);
  }

  double findViewportFraction(
      {required Axis scrollAxis,
      required double parentWidth,
      required double parentHeight,
      required int pdfWidth,
      required int pdfHeight}) {
    if (scrollAxis == Axis.horizontal) {
      return 1.0;
    }

    final screnAspectRatio = parentHeight / parentWidth;
    final pdfAspectRatio = pdfHeight / pdfWidth;
    return pdfAspectRatio / screnAspectRatio;
  }

  Color _getBackGroundColor(ColorMode colorMode) {
    switch (colorMode) {
      case ColorMode.day:
        return Colors.white;
      case ColorMode.night:
        return Colors.black;
      case ColorMode.speia:
        return const Color.fromARGB(255, 255, 255, 213);
      case ColorMode.grayscale:
        return Colors.grey;
    }
  }

  void _gotoTopOfpage() async {
    // debugPrint('need scroll: $isNeedScrollToTop');
    if (!isNeedScrollToTop) return;

    // _scroll controller is still not initialized
    // need to wait
    await Future.delayed(const Duration(milliseconds: 150));

    double? offset = _scrollController?.offset;
    if (offset == null) return;

    offset = offset - 500;
    if (offset >= 0) {
      _scrollController?.jumpTo(offset);
    } else {
      _scrollController?.jumpTo(0);
    }
  }
}
