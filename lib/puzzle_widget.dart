
import 'dart:io';
import 'dart:ui';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as ui;
import 'dart:math' as math;


class PuzzleWidget extends StatefulWidget {
  final String imageFile;
  final int gridSize;

  PuzzleWidget({required this.imageFile, required this.gridSize, Key? key})
      : super(key: key);
  // PuzzleWidget({Key? key}) : super(key: key);

  @override
  _PuzzleWidgetState createState() => _PuzzleWidgetState();
}

class _PuzzleWidgetState extends State<PuzzleWidget> {
  // lets setup our puzzle 1st

  // add test button to check crop work
  // well done.. let put callback for success put piece & complete all

  GlobalKey<_JigsawWidgetState> jigKey = new GlobalKey<_JigsawWidgetState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          //color: Colors.blue,
          child: SafeArea(
            child: Center(
              child: Column(
                children: [
                  // let make base for our puzzle widget
                  Container(
                    margin: EdgeInsets.all(10),
                    // decoration: BoxDecoration(border: Border.all(width: 2)),
                    child: JigsawWidget(
                      callbackFinish: () {
                        // check function
                        print("callbackFinish");
                      },
                      callbackSuccess: () {
                        print("callbackSuccess");
                        // lets fix error size
                      },
                      key: jigKey,
                      // set container for our jigsaw image
                      child: Image(
                        fit: BoxFit.cover,
                        image: FileImage(File(widget.imageFile)),
                      ),
                    ),
                  ),
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          child: Text("Clear"),
                          onPressed: () {
                            jigKey.currentState?.resetJigsaw();
                          },
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () async {
                            await jigKey.currentState
                                ?.generaJigsawCropImage(widget.gridSize);

                          },
                          child: Text("Generate"),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}



// make new widget name JigsawWidget
// let move jigsaw blok
class JigsawWidget extends StatefulWidget {
  final Key key;
  final Widget child;
  final Function() callbackSuccess;
  final Function() callbackFinish;

  JigsawWidget(
      {required this.key,
        required this.child,
        required this.callbackFinish,
        required this.callbackSuccess})
      : super(key: key);

  @override
  _JigsawWidgetState createState() => _JigsawWidgetState();
}

class _JigsawWidgetState extends State<JigsawWidget> {
  GlobalKey _globalKey = GlobalKey();
  ui.Image? fullImage;
  Size? size;

  List<List<BlockClass>> images = [];

  ValueNotifier<List<BlockClass>> blocksNotifier =
  ValueNotifier<List<BlockClass>>([]);

  List<BlockClass> blockDone = [];
  List<BlockClass> blockNotDone = [];
  List<BlockClass> blockCorrectPos = [];

  Offset _dropPosition = Offset.zero;

  CarouselController? _carouselController;

  _getImageFromWidget() async {
    print('getImageFromWidget:$_getImageFromWidget()');
    RenderRepaintBoundary? boundary =
    _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    if (boundary != null) {
      size = boundary.size;
      var img = await boundary.toImage();
      var byteData = await img.toByteData(format: ImageByteFormat.png);
      var pngBytes = byteData!.buffer.asUint8List();

      return ui.decodeImage(pngBytes);
    } else {
      // Handle the case when boundary is null
      print('Error: RenderRepaintBoundary is null');
      return null; // or return an appropriate default value
    }
  }

  resetJigsaw() {
    images.clear();

    blocksNotifier = ValueNotifier<List<BlockClass>>([]);

    blocksNotifier.notifyListeners();
    setState(() {});
  }

  Future<void> generaJigsawCropImage(int i) async {
    print('generateJigsawcropImage:$generaJigsawCropImage(i)');
    // 1st we need create a class for block image
    images = List<List<BlockClass>>.empty(growable: true);

    // get image from out boundary

    if (fullImage == null) fullImage = await _getImageFromWidget();

    // split image using crop

    int xSplitCount = i;
    int ySplitCount = i;
    print('xSplitCount: $xSplitCount, ySplitCount: $ySplitCount');

    // i think i know what the problom width & height not correct!
    double widthPerBlock =
        (fullImage?.width ?? 0) / xSplitCount; // change back to width
    double heightPerBlock = (fullImage?.height ?? 0) / ySplitCount;
    print('widthPerBlock: $widthPerBlock, heightPerBlock: $heightPerBlock');

    for (var y = 0; y < ySplitCount; y++) {
      // temporary images
      List<BlockClass> tempImages = [];
      print('tempImages: $tempImages');

      images.add(tempImages);
      for (var x = 0; x < xSplitCount; x++) {
        int randomPosRow = math.Random().nextInt(2) % 2 == 0 ? 1 : -1;
        int randomPosCol = math.Random().nextInt(2) % 2 == 0 ? 1 : -1;

        Offset offsetCenter = Offset(widthPerBlock / 2, heightPerBlock / 2);

        print('randomPosRow: $randomPosRow, randomPosCol: $randomPosCol');
        print('offsetCenter: $offsetCenter');

        // make random jigsaw pointer in or out

        ClassJigsawPos jigsawPosSide = new ClassJigsawPos(
          bottom: y == ySplitCount - 1 ? 0 : randomPosCol,
          left: x == 0
              ? 0
              : -(images[y][x - 1].jigsawBlockWidget?.imageBox.posSide.right ??
              0), // ops.. forgot to dclare
          right: x == xSplitCount - 1 ? 0 : randomPosRow,
          top: y == 0
              ? 0
              : -(images[y - 1][x].jigsawBlockWidget?.imageBox.posSide.bottom ??
              0),
        );
        print(
            'jigsawPosSide - Bottom: ${jigsawPosSide.bottom}, Left: ${jigsawPosSide.left}, Right: ${jigsawPosSide.right}, Top: ${jigsawPosSide.top}');

        double xAxis = widthPerBlock * x;
        double yAxis = heightPerBlock * y; // this is culprit.. haha
        print('xAxis: $xAxis, yAxis: $yAxis');

        // size for pointing
        double minSize = math.min(widthPerBlock, heightPerBlock) / 15 * 4;
        print('minSize: $minSize');

        offsetCenter = Offset(
          (widthPerBlock / 2) + (jigsawPosSide.left == 1 ? minSize : 0),
          (heightPerBlock / 2) + (jigsawPosSide.top == 1 ? minSize : 0),
        );
        print('offsetCenter: $offsetCenter');

        // change axis for posSideEffect
        xAxis -= jigsawPosSide.left == 1 ? minSize : 0;
        yAxis -= jigsawPosSide.top == 1 ? minSize : 0;
        print('Updated xAxis: $xAxis, Updated yAxis: $yAxis');

        // get width & height after change Axis Side Effect
        double widthPerBlockTemp = widthPerBlock +
            (jigsawPosSide.left == 1 ? minSize : 0) +
            (jigsawPosSide.right == 1 ? minSize : 0);
        double heightPerBlockTemp = heightPerBlock +
            (jigsawPosSide.top == 1 ? minSize : 0) +
            (jigsawPosSide.bottom == 1 ? minSize : 0);
        print(
            'widthPerBlockTemp: $widthPerBlockTemp, heightPerBlockTemp: $heightPerBlockTemp');

        ui.Image temp = ui.copyCrop(fullImage!,
            x: xAxis.round(),
            y: yAxis.round(),
            height: heightPerBlockTemp.round(),
            width: widthPerBlockTemp.round());
        print(
            'Cropped Image: Width: ${widthPerBlockTemp.round()}, Height: ${heightPerBlockTemp.round()}, x: ${xAxis.round()}, y: ${yAxis.round()}');

        // get offset for each block show on center base later
        Offset offset = Offset(size!.width / 2 - widthPerBlockTemp / 2,
            size!.height / 2 - heightPerBlockTemp / 2);

        ImageBox imageBox = new ImageBox(
          image: Image.memory(
            ui.encodePng(temp),
            fit: BoxFit.cover,
          ),
          isDone: false,
          offsetCenter: offsetCenter,
          posSide: jigsawPosSide,
          radiusPoint: minSize,
          size: Size(widthPerBlockTemp, heightPerBlockTemp),
        );
        print('ImageBox:');
        print(' - isDone: ${imageBox.isDone}');
        print(' - offsetCenter: ${imageBox.offsetCenter}');
        print(' - posSide: ${imageBox.posSide}');
        print(' - radiusPoint: $minSize');
        print('ImageBox Size: Width: ${imageBox.size?.width ?? 0}, Height: ${imageBox.size?.height ?? 0}');


        images[y].add(
          new BlockClass(
            jigsawBlockWidget: JigsawBlockWidget(
              imageBox: imageBox,
              offsetDefault: offset,
            ),
            offset: offset,
            offsetDefault: Offset(xAxis, yAxis),
            correctPosition: Offset(xAxis, yAxis),
          ),
        );
        print('Added BlockClass to images[$y]:');
        print(' - Offset: $offset');
        print(' - Offset Default: ${Offset(xAxis, yAxis)}');
        print(' - Correct Position: ${Offset(xAxis, yAxis)}');
        print(' - Current number of blocks in images[$y]: ${images[y].length}');
      }
    }

    blocksNotifier.value = images.expand((image) => image).toList();
    // let random a bit so blok puzzle not in incremet order
    // ops..bug .. i found culprit.. seem RepaintBoundary return wrong width on render..fix 1st using height
    // as well
    blocksNotifier.value.shuffle();
    blocksNotifier.notifyListeners();
    setState(() {
      blockCorrectPos.clear();
    });
  }

  @override
  void initState() {
    _carouselController = new CarouselController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size; // Get the screen size

    return ValueListenableBuilder(
      valueListenable: blocksNotifier,
      builder: (context, List<BlockClass> blocks, child) {
        blockNotDone = blocks
            .where((block) =>
        !(block.jigsawBlockWidget?.imageBox.isDropped ?? false))
            .toList();
        blockDone = blocks
            .where((block) =>
        (block.jigsawBlockWidget?.imageBox.isDropped ?? false))
            .toList();

        return Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DragTarget<BlockClass>(
                onAccept: (receivedBlock) {
                  setState(() {
                    receivedBlock.jigsawBlockWidget?.imageBox.isDropped = true;
                    print(
                        "the index of the receivedBlock for blockNotDone is ${blockNotDone.indexOf(receivedBlock)}");
                    print(
                        "the index of the receivedBlock for blockDone is ${blockDone.indexOf(receivedBlock)}");
                    blockNotDone.remove(receivedBlock);
                    blockDone.add(receivedBlock);
                    blockCorrectPos.remove(
                        receivedBlock); // notdone block it will place top
                    blockCorrectPos.add(receivedBlock);
                    // if (!blockCorrectPos.contains(receivedBlock)) {
                    //   blockCorrectPos.insert(0, receivedBlock);
                    // }
                    if (isCorrectPosition(receivedBlock)) {
                      receivedBlock.jigsawBlockWidget?.imageBox
                          .isInCorrectPosition = true;
                      receivedBlock.jigsawBlockWidget?.imageBox.isDone = true;
                      receivedBlock.offset = receivedBlock.correctPosition;
                      if (blockDone.isNotEmpty) {
                        blockDone.removeAt(blockDone.indexOf(receivedBlock));
                        blockDone.insert(0, receivedBlock);
                      }
                      widget.callbackSuccess.call();
                      print("Piece placed correctly.");
                    } else {
                      double horizontalAdjustment =
                          screenSize.width * 0.02; // 2% of screen width
                      double verticalAdjustment =
                          screenSize.height * 0.05; // 5% of screen height
                      setState(() {
                        // Check if the receivedBlock exists in blockCorrectPos
                        if (blockCorrectPos.contains(receivedBlock)) {
                          // Remove the block from its current position if it exists
                          blockCorrectPos.remove(receivedBlock);
                        }
                        // Insert the block at the desired position (0 in this case) if it doesn't exist
                        if (!blockCorrectPos.contains(receivedBlock)) {
                          blockCorrectPos.insert(0, receivedBlock);
                        }
                      });

                      receivedBlock.offset = Offset(
                        _dropPosition.dx - horizontalAdjustment,
                        _dropPosition.dy - verticalAdjustment,
                      );
                    }
                    blocksNotifier.notifyListeners();

                    // Check if all pieces are placed correctly
                    if (blocks.every((block) =>
                    block.jigsawBlockWidget?.imageBox.isDone ?? false)) {
                      resetJigsaw();
                      widget.callbackFinish
                          .call(); // Close the game automatically
                      print(
                          "All pieces are placed correctly. Puzzle completed!");
                    }
                  });
                },
                onMove: (details) {
                  print("details : $_dropPosition");
                  _dropPosition = details.offset;
                  var receivedBlock = details.data;
                  print("receivedblock : $receivedBlock");

                  if (isCorrectPosition(receivedBlock)) {
                    receivedBlock.offset = receivedBlock.correctPosition;
                    receivedBlock
                        .jigsawBlockWidget?.imageBox.isInCorrectPosition =
                    true; // moving time accepting code colour change to green
                    // receivedBlock.jigsawBlockWidget?.imageBox.isDone = true;
                    blocksNotifier.notifyListeners();
                    // widget.callbackSuccess.call();
                  } else {
                    double horizontalAdjustment = screenSize.width * 0.02;
                    double verticalAdjustment = screenSize.height * 0.05;

                    receivedBlock.offset = Offset(
                      _dropPosition.dx - horizontalAdjustment,
                      _dropPosition.dy - verticalAdjustment,
                    );
                  }
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    height: screenSize.width,
                    child: Listener(
                      onPointerUp: (event) {
                        // Additional check after user interaction
                        if (blocks.every((block) =>
                        block.jigsawBlockWidget?.imageBox.isDone ??
                            false)) {
                          resetJigsaw();
                          widget.callbackFinish.call();
                          print(
                              "All pieces are placed correctly. Puzzle completed!");
                        }
                      },
                      child: Stack(
                        children: [
                          if (blocks.isEmpty)
                            RepaintBoundary(
                              key: _globalKey,
                              child: Container(
                                height: double.maxFinite,
                                width: double.maxFinite,
                                child: widget.child,
                              ),
                            ),
                          Offstage(
                            offstage: blocks.isEmpty,
                            child: Container(
                              height: screenSize.height,
                              width: screenSize.width,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.black),
                              ),
                              child: CustomPaint(
                                painter: JigsawPainterBackground(blocks),
                                child: Stack(
                                  children: [
                                    if (blockDone.isNotEmpty)
                                      ...blockDone
                                          .where((block) => ((block
                                          .jigsawBlockWidget
                                          ?.imageBox
                                          .isDone ??
                                          true)))
                                          .toList()
                                          .map((block) {
                                        return Positioned(
                                            left: block.offset?.dx ?? 0,
                                            top: block.offset?.dy ?? 0,
                                            child: Container(
                                                child:
                                                block.jigsawBlockWidget));
                                      }).toList(),
                                    if (blockDone.isNotEmpty)
                                      ...blockCorrectPos.reversed
                                          .where((block) => (!(block
                                          .jigsawBlockWidget
                                          ?.imageBox
                                          .isDone ??
                                          false)))
                                          .toList()
                                          .map((block) {
                                        return Positioned(
                                          left: block.offset?.dx ?? 0,
                                          top: block.offset?.dy ?? 0,
                                          child: Draggable<BlockClass>(
                                            data: block,
                                            feedback: SizedBox(
                                              width: block.jigsawBlockWidget
                                                  ?.imageBox.size?.width ??
                                                  0,
                                              height: block.jigsawBlockWidget
                                                  ?.imageBox.size?.height ??
                                                  0,
                                              child: block.jigsawBlockWidget,
                                            ),
                                            childWhenDragging: Container(),
                                            onDragEnd: (details) {
                                              if (!details.wasAccepted) {
                                                setState(() {
                                                  blockCorrectPos.removeWhere(
                                                          (test) => block == test);
                                                  block
                                                      .jigsawBlockWidget
                                                      ?.imageBox
                                                      .isDropped = false;
                                                  blockDone.remove(block);
                                                  blockNotDone.add(block);
                                                });
                                              }
                                            },
                                            child: block.jigsawBlockWidget!,
                                          ),
                                        );
                                      }).toList(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
              // Carousel containing draggable puzzle pieces
              Container(
                decoration:
                BoxDecoration(border: Border.all(color: Colors.grey)),
                height: 100,
                child: CarouselSlider(
                  options: CarouselOptions(
                    height: 80,
                    viewportFraction: 0.25,
                    enableInfiniteScroll: false,
                    scrollPhysics: BouncingScrollPhysics(),
                  ),
                  items: blockNotDone.map((block) {
                    Size? sizeBlock = block.jigsawBlockWidget?.imageBox.size;
                    return FittedBox(
                      child: Container(
                        width: sizeBlock?.width ?? 0,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: sizeBlock?.height ?? 0,
                        child: Draggable<BlockClass>(
                          data: block,
                          feedback: Container(
                            width: sizeBlock?.width ?? 0,
                            height: sizeBlock?.height ?? 0,
                            child: block.jigsawBlockWidget,
                          ),
                          childWhenDragging: Container(),
                          child: FittedBox(
                            child: Container(
                              width: sizeBlock?.width ?? 0,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              height: sizeBlock?.height ?? 0,
                              child: block.jigsawBlockWidget,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool isCorrectPosition(BlockClass block) {
    const double tolerance = 5.0; // Reduced tolerance for a tighter fit

    if (block.offset == null) return false;

    double dx = (block.offset!.dx - block.correctPosition.dx).abs();
    double dy = (block.offset!.dy - block.correctPosition.dy).abs();
    print(dx);
    print(dy);

    return dx <= tolerance && dy <= tolerance;
  }
}





class JigsawPainterBackground extends CustomPainter {
  List<BlockClass> blocks;

  JigsawPainterBackground(this.blocks);

  @override
  void paint(Canvas canvas, Size size) {
    // Paint object with stroke style
    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
    // ..color=Colors.transparent
      ..strokeCap = StrokeCap.round;

    Path path = Path();

    // Loop through each block to generate the path for the jigsaw pieces
    blocks.forEach((element) {
      // Retrieve the path for the jigsaw piece based on its properties
      Path pathTemp = getPiecePath(
        element.jigsawBlockWidget?.imageBox.size ?? Size(0, 0),
        element.jigsawBlockWidget?.imageBox.radiusPoint ?? 0.0,
        element.jigsawBlockWidget?.imageBox.offsetCenter ?? Offset(0, 0),
        element.jigsawBlockWidget!.imageBox.posSide,
      );

      // Add the generated path to the main path, positioned at the block's default offset
      path.addPath(pathTemp, element.offsetDefault ?? Offset(0, 0));
    });

    // Draw the path on the canvas
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


class BlockClass {
  Offset? offset;
  Offset? offsetDefault;
  Offset correctPosition;
  JigsawBlockWidget? jigsawBlockWidget;

  BlockClass({
    this.offset,
    this.jigsawBlockWidget,  required this.correctPosition,

    this.offsetDefault,
  });
}

class ImageBox {
  Widget? image;
  ClassJigsawPos posSide;
  Offset? offsetCenter;
  Size? size;
  double? radiusPoint;
  bool? isDone;
  bool? isDropped; // New property to track if the block has been dropped
  bool? isInCorrectPosition;

  ImageBox({
    this.image,
    required this.posSide,
    this.isDone,
    this.offsetCenter,
    this.radiusPoint,
    this.size,
    this.isDropped = false,
    this.isInCorrectPosition = false,
  });
}

class ClassJigsawPos {
  int? top, bottom, left, right;

  ClassJigsawPos({this.top, this.bottom, this.left, this.right});
}

class JigsawBlockWidget extends StatefulWidget {
  ImageBox imageBox;
  Offset offsetDefault;

  JigsawBlockWidget(
      {Key? key, required this.imageBox, required this.offsetDefault})
      : super(key: key);

  @override
  _JigsawBlockWidgetState createState() => _JigsawBlockWidgetState();
}

class _JigsawBlockWidgetState extends State<JigsawBlockWidget> {
  // lets start clip crop image so show like jigsaw puzzle

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: PuzzlePieceClipper(imageBox: widget.imageBox),
      child: CustomPaint(
        foregroundPainter: JigsawBlockPainter.JigsawBlockPainter(imageBox: widget.imageBox,),
        child: widget.imageBox
            .image, // it sets the images in  the jig aw puzzle while clicking the generate
      ),
    );
  }
}
class JigsawBlockPainter extends CustomPainter {
  ImageBox? imageBox;

  JigsawBlockPainter.JigsawBlockPainter({this.imageBox});

  @override
  void paint(Canvas canvas, Size size) {
    // Paint the border with different colors depending on whether the piece is done
    Paint paint = Paint()
      ..color = (imageBox?.isInCorrectPosition ?? false)
          ? Colors.green.withOpacity(1) // Green if in correct position
          : Colors.red // Default color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Draw the puzzle piece path
    canvas.drawPath(
      getPiecePath(
        size,
        imageBox?.radiusPoint ?? 0.0,
        imageBox?.offsetCenter ?? Offset.zero,
        imageBox!.posSide,
      ),
      paint,
    );

    if (imageBox?.isDone ?? false) {
      Paint paintDone = Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..style = PaintingStyle.fill
        ..strokeWidth = 2;

      Path path = getPiecePath(
        size,
        imageBox?.radiusPoint ?? 0.0,
        imageBox?.offsetCenter ?? Offset.zero,
        imageBox!.posSide,
      );

      // Draw a fill to indicate the piece is done
      canvas.drawPath(path, paintDone);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}




class PuzzlePieceClipper extends CustomClipper<Path> {
  ImageBox imageBox;
  PuzzlePieceClipper({
    required this.imageBox,
  });
  @override
  Path getClip(Size size) {
    // Ensure that nullable arguments are handled safely
    double radiusPoint = this.imageBox.radiusPoint ?? 0.0;
    Offset offsetCenter = this.imageBox.offsetCenter ?? Offset.zero;
    ClassJigsawPos posSide = this.imageBox.posSide ?? ClassJigsawPos();

    // Call the function with non-nullable arguments
    return getPiecePath(size, radiusPoint, offsetCenter, posSide);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}


getPiecePath(
    Size size,
    double radiusPoint,
    Offset offsetCenter,
    ClassJigsawPos posSide,
    ) {
  Path path = new Path();

  Offset topLeft = Offset(0, 0);
  Offset topRight = Offset(size.width, 0);
  Offset bottomLeft = Offset(0, size.height);
  Offset bottomRight = Offset(size.width, size.height);

  // calculate top point on 4 point
  topLeft = Offset(posSide.left! > 0 ? radiusPoint : 0,
      (posSide.top! > 0) ? radiusPoint : 0) +
      topLeft;
  topRight = Offset(posSide.right! > 0 ? -radiusPoint : 0,
      (posSide.top! > 0) ? radiusPoint : 0) +
      topRight;
  bottomRight = Offset(posSide.right! > 0 ? -radiusPoint : 0,
      (posSide.bottom! > 0) ? -radiusPoint : 0) +
      bottomRight;
  bottomLeft = Offset(posSide.left! > 0 ? radiusPoint : 0,
      (posSide.bottom! > 0) ? -radiusPoint : 0) +
      bottomLeft;

  // calculate mid point for min & max
  double topMiddle = posSide.top == 0
      ? topRight.dy
      : (posSide.top! > 0
      ? topRight.dy - radiusPoint
      : topRight.dy + radiusPoint);
  double bottomMiddle = posSide.bottom == 0
      ? bottomRight.dy
      : (posSide.bottom! > 0
      ? bottomRight.dy + radiusPoint
      : bottomRight.dy - radiusPoint);
  double leftMiddle = posSide.left == 0
      ? topLeft.dx
      : (posSide.left! > 0
      ? topLeft.dx - radiusPoint
      : topLeft.dx + radiusPoint);
  double rightMiddle = posSide.right == 0
      ? topRight.dx
      : (posSide.right! > 0
      ? topRight.dx + radiusPoint
      : topRight.dx - radiusPoint);

  // solve.. wew

  path.moveTo(topLeft.dx, topLeft.dy);
  // top draw
  if (posSide.top != 0)
    path.extendWithPath(
        calculatePoint(Axis.horizontal, topLeft.dy,
            Offset(offsetCenter.dx, topMiddle), radiusPoint),
        Offset.zero);
  path.lineTo(topRight.dx, topRight.dy);
  // right draw
  if (posSide.right != 0)
    path.extendWithPath(
        calculatePoint(Axis.vertical, topRight.dx,
            Offset(rightMiddle, offsetCenter.dy), radiusPoint),
        Offset.zero);
  path.lineTo(bottomRight.dx, bottomRight.dy);
  if (posSide.bottom != 0)
    path.extendWithPath(
        calculatePoint(Axis.horizontal, bottomRight.dy,
            Offset(offsetCenter.dx, bottomMiddle), -radiusPoint),
        Offset.zero);
  path.lineTo(bottomLeft.dx, bottomLeft.dy);
  if (posSide.left != 0)
    path.extendWithPath(
        calculatePoint(Axis.vertical, bottomLeft.dx,
            Offset(leftMiddle, offsetCenter.dy), -radiusPoint),
        Offset.zero);
  path.lineTo(topLeft.dx, topLeft.dy);

  path.close();

  return path;
}

Path calculatePoint(
    Axis axis, double fromPoint, Offset point, double radiusPoint) {
  Path path = Path();
  if (axis == Axis.horizontal) {
    path.moveTo((point.dx - radiusPoint / 2) - 1, fromPoint - 1);

    path.quadraticBezierTo(
      (point.dx - radiusPoint) - 1,
      point.dy - 1,
      point.dx - 1,
      point.dy - 1,
    );

    // End of the "omega" curve: curve outwards again
    path.quadraticBezierTo(
      (point.dx + radiusPoint) - 1,
      (point.dy) - 1,
      (point.dx + radiusPoint / 2) - 1,
      fromPoint - 1,
    );
  } else if (axis == Axis.vertical) {
    path.moveTo(fromPoint - 1, (point.dy - 1) - radiusPoint / 2);

    // Middle of the "omega" curve: curve inwards directly without initial bend
    path.quadraticBezierTo(
      point.dx - 1,
      (point.dy - radiusPoint) - 1,
      point.dx - 1,
      point.dy - 1,
    );

    // End of the "omega" curve: curve outwards again
    path.quadraticBezierTo(
      point.dx - 1,
      (point.dy + radiusPoint) - 1,
      fromPoint - 1,
      (point.dy + radiusPoint / 2) - 1,
    );
  }

  return path;
}

// ok code final
/*
import 'dart:io';
import 'dart:ui';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as ui;
import 'dart:math' as math;


class PuzzleWidget extends StatefulWidget {
  final String imageFile;
  final int gridSize;

  PuzzleWidget({required this.imageFile, required this.gridSize, Key? key})
      : super(key: key);
  // PuzzleWidget({Key? key}) : super(key: key);

  @override
  _PuzzleWidgetState createState() => _PuzzleWidgetState();
}

class _PuzzleWidgetState extends State<PuzzleWidget> {
  // lets setup our puzzle 1st

  // add test button to check crop work
  // well done.. let put callback for success put piece & complete all

  GlobalKey<_JigsawWidgetState> jigKey = new GlobalKey<_JigsawWidgetState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          //color: Colors.blue,
          child: SafeArea(
            child: Center(
              child: Column(
                children: [
                  // let make base for our puzzle widget
                  Container(
                    margin: EdgeInsets.all(10),
                    // decoration: BoxDecoration(border: Border.all(width: 2)),
                    child: JigsawWidget(
                      callbackFinish: () {
                        // check function
                        print("callbackFinish");
                      },
                      callbackSuccess: () {
                        print("callbackSuccess");
                        // lets fix error size
                      },
                      key: jigKey,
                      // set container for our jigsaw image
                      child: Image(
                        fit: BoxFit.cover,
                        image: FileImage(File(widget.imageFile)),
                      ),
                    ),
                  ),
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          child: Text("Clear"),
                          onPressed: () {
                            jigKey.currentState?.resetJigsaw();
                          },
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () async {
                            await jigKey.currentState
                                ?.generaJigsawCropImage(widget.gridSize);

                          },
                          child: Text("Generate"),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}



// make new widget name JigsawWidget
// let move jigsaw blok
class JigsawWidget extends StatefulWidget {
  final Key key;
  final Widget child;
  final Function() callbackSuccess;
  final Function() callbackFinish;

  JigsawWidget(
      {required this.key,
        required this.child,
        required this.callbackFinish,
        required this.callbackSuccess})
      : super(key: key);

  @override
  _JigsawWidgetState createState() => _JigsawWidgetState();
}

class _JigsawWidgetState extends State<JigsawWidget> {
  GlobalKey _globalKey = GlobalKey();
  ui.Image? fullImage;
  Size? size;

  List<List<BlockClass>> images = [];

  ValueNotifier<List<BlockClass>> blocksNotifier =
  ValueNotifier<List<BlockClass>>([]);

  List<BlockClass> blockDone = [];
  List<BlockClass> blockNotDone = [];
  List<BlockClass> blockCorrectPos = [];

  Offset _dropPosition = Offset.zero;

  CarouselController? _carouselController;

  _getImageFromWidget() async {
    print('getImageFromWidget:$_getImageFromWidget()');
    RenderRepaintBoundary? boundary =
    _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    if (boundary != null) {
      size = boundary.size;
      var img = await boundary.toImage();
      var byteData = await img.toByteData(format: ImageByteFormat.png);
      var pngBytes = byteData!.buffer.asUint8List();

      return ui.decodeImage(pngBytes);
    } else {
      // Handle the case when boundary is null
      print('Error: RenderRepaintBoundary is null');
      return null; // or return an appropriate default value
    }
  }

  resetJigsaw() {
    images.clear();

    blocksNotifier = ValueNotifier<List<BlockClass>>([]);

    blocksNotifier.notifyListeners();
    setState(() {});
  }

  Future<void> generaJigsawCropImage(int i) async {
    print('generateJigsawcropImage:$generaJigsawCropImage(i)');
    // 1st we need create a class for block image
    images = List<List<BlockClass>>.empty(growable: true);

    // get image from out boundary

    if (fullImage == null) fullImage = await _getImageFromWidget();

    // split image using crop

    int xSplitCount = i;
    int ySplitCount = i;
    print('xSplitCount: $xSplitCount, ySplitCount: $ySplitCount');

    // i think i know what the problom width & height not correct!
    double widthPerBlock =
        (fullImage?.width ?? 0) / xSplitCount; // change back to width
    double heightPerBlock = (fullImage?.height ?? 0) / ySplitCount;
    print('widthPerBlock: $widthPerBlock, heightPerBlock: $heightPerBlock');

    for (var y = 0; y < ySplitCount; y++) {
      // temporary images
      List<BlockClass> tempImages = [];
      print('tempImages: $tempImages');

      images.add(tempImages);
      for (var x = 0; x < xSplitCount; x++) {
        int randomPosRow = math.Random().nextInt(2) % 2 == 0 ? 1 : -1;
        int randomPosCol = math.Random().nextInt(2) % 2 == 0 ? 1 : -1;

        Offset offsetCenter = Offset(widthPerBlock / 2, heightPerBlock / 2);

        print('randomPosRow: $randomPosRow, randomPosCol: $randomPosCol');
        print('offsetCenter: $offsetCenter');

        // make random jigsaw pointer in or out

        ClassJigsawPos jigsawPosSide = new ClassJigsawPos(
          bottom: y == ySplitCount - 1 ? 0 : randomPosCol,
          left: x == 0
              ? 0
              : -(images[y][x - 1].jigsawBlockWidget?.imageBox.posSide.right ??
              0), // ops.. forgot to dclare
          right: x == xSplitCount - 1 ? 0 : randomPosRow,
          top: y == 0
              ? 0
              : -(images[y - 1][x].jigsawBlockWidget?.imageBox.posSide.bottom ??
              0),
        );
        print(
            'jigsawPosSide - Bottom: ${jigsawPosSide.bottom}, Left: ${jigsawPosSide.left}, Right: ${jigsawPosSide.right}, Top: ${jigsawPosSide.top}');

        double xAxis = widthPerBlock * x;
        double yAxis = heightPerBlock * y; // this is culprit.. haha
        print('xAxis: $xAxis, yAxis: $yAxis');

        // size for pointing
        double minSize = math.min(widthPerBlock, heightPerBlock) / 15 * 4;
        print('minSize: $minSize');

        offsetCenter = Offset(
          (widthPerBlock / 2) + (jigsawPosSide.left == 1 ? minSize : 0),
          (heightPerBlock / 2) + (jigsawPosSide.top == 1 ? minSize : 0),
        );
        print('offsetCenter: $offsetCenter');

        // change axis for posSideEffect
        xAxis -= jigsawPosSide.left == 1 ? minSize : 0;
        yAxis -= jigsawPosSide.top == 1 ? minSize : 0;
        print('Updated xAxis: $xAxis, Updated yAxis: $yAxis');

        // get width & height after change Axis Side Effect
        double widthPerBlockTemp = widthPerBlock +
            (jigsawPosSide.left == 1 ? minSize : 0) +
            (jigsawPosSide.right == 1 ? minSize : 0);
        double heightPerBlockTemp = heightPerBlock +
            (jigsawPosSide.top == 1 ? minSize : 0) +
            (jigsawPosSide.bottom == 1 ? minSize : 0);
        print(
            'widthPerBlockTemp: $widthPerBlockTemp, heightPerBlockTemp: $heightPerBlockTemp');

        ui.Image temp = ui.copyCrop(fullImage!,
            x: xAxis.round(),
            y: yAxis.round(),
            height: heightPerBlockTemp.round(),
            width: widthPerBlockTemp.round());
        print(
            'Cropped Image: Width: ${widthPerBlockTemp.round()}, Height: ${heightPerBlockTemp.round()}, x: ${xAxis.round()}, y: ${yAxis.round()}');

        // get offset for each block show on center base later
        Offset offset = Offset(size!.width / 2 - widthPerBlockTemp / 2,
            size!.height / 2 - heightPerBlockTemp / 2);

        ImageBox imageBox = new ImageBox(
          image: Image.memory(
            ui.encodePng(temp),
            fit: BoxFit.cover,
          ),
          isDone: false,
          offsetCenter: offsetCenter,
          posSide: jigsawPosSide,
          radiusPoint: minSize,
          size: Size(widthPerBlockTemp, heightPerBlockTemp),
        );
        print('ImageBox:');
        print(' - isDone: ${imageBox.isDone}');
        print(' - offsetCenter: ${imageBox.offsetCenter}');
        print(' - posSide: ${imageBox.posSide}');
        print(' - radiusPoint: $minSize');
        print('ImageBox Size: Width: ${imageBox.size?.width ?? 0}, Height: ${imageBox.size?.height ?? 0}');


        images[y].add(
          new BlockClass(
            jigsawBlockWidget: JigsawBlockWidget(
              imageBox: imageBox,
              offsetDefault: offset,
            ),
            offset: offset,
            offsetDefault: Offset(xAxis, yAxis),
            correctPosition: Offset(xAxis, yAxis),
          ),
        );
        print('Added BlockClass to images[$y]:');
        print(' - Offset: $offset');
        print(' - Offset Default: ${Offset(xAxis, yAxis)}');
        print(' - Correct Position: ${Offset(xAxis, yAxis)}');
        print(' - Current number of blocks in images[$y]: ${images[y].length}');
      }
    }

    blocksNotifier.value = images.expand((image) => image).toList();
    // let random a bit so blok puzzle not in incremet order
    // ops..bug .. i found culprit.. seem RepaintBoundary return wrong width on render..fix 1st using height
    // as well
    blocksNotifier.value.shuffle();
    blocksNotifier.notifyListeners();
    setState(() {
      blockCorrectPos.clear();
    });
  }

  @override
  void initState() {
    _carouselController = new CarouselController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size; // Get the screen size

    return ValueListenableBuilder(
      valueListenable: blocksNotifier,
      builder: (context, List<BlockClass> blocks, child) {
        blockNotDone = blocks
            .where((block) =>
        !(block.jigsawBlockWidget?.imageBox.isDropped ?? false))
            .toList();
        blockDone = blocks
            .where((block) =>
        (block.jigsawBlockWidget?.imageBox.isDropped ?? false))
            .toList();

        return Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DragTarget<BlockClass>(
                onAccept: (receivedBlock) {
                  setState(() {
                    receivedBlock.jigsawBlockWidget?.imageBox.isDropped = true;
                    print(
                        "the index of the receivedBlock for blockNotDone is ${blockNotDone.indexOf(receivedBlock)}");
                    print(
                        "the index of the receivedBlock for blockDone is ${blockDone.indexOf(receivedBlock)}");
                    blockNotDone.remove(receivedBlock);
                    blockDone.add(receivedBlock);
                    blockCorrectPos.remove(
                        receivedBlock); // notdone block it will place top
                    blockCorrectPos.add(receivedBlock);
                    // if (!blockCorrectPos.contains(receivedBlock)) {
                    //   blockCorrectPos.insert(0, receivedBlock);
                    // }
                    if (isCorrectPosition(receivedBlock)) {
                      receivedBlock.jigsawBlockWidget?.imageBox
                          .isInCorrectPosition = true;
                      receivedBlock.jigsawBlockWidget?.imageBox.isDone = true;
                      receivedBlock.offset = receivedBlock.correctPosition;
                      if (blockDone.isNotEmpty) {
                        blockDone.removeAt(blockDone.indexOf(receivedBlock));
                        blockDone.insert(0, receivedBlock);
                      }
                      widget.callbackSuccess.call();
                      print("Piece placed correctly.");
                    } else {
                      double horizontalAdjustment =
                          screenSize.width * 0.02; // 2% of screen width
                      double verticalAdjustment =
                          screenSize.height * 0.05; // 5% of screen height
                      setState(() {
                        // Check if the receivedBlock exists in blockCorrectPos
                        if (blockCorrectPos.contains(receivedBlock)) {
                          // Remove the block from its current position if it exists
                          blockCorrectPos.remove(receivedBlock);
                        }
                        // Insert the block at the desired position (0 in this case) if it doesn't exist
                        if (!blockCorrectPos.contains(receivedBlock)) {
                          blockCorrectPos.insert(0, receivedBlock);
                        }
                      });

                      receivedBlock.offset = Offset(
                        _dropPosition.dx - horizontalAdjustment,
                        _dropPosition.dy - verticalAdjustment,
                      );
                    }
                    blocksNotifier.notifyListeners();

                    // Check if all pieces are placed correctly
                    if (blocks.every((block) =>
                    block.jigsawBlockWidget?.imageBox.isDone ?? false)) {
                      resetJigsaw();
                      widget.callbackFinish
                          .call(); // Close the game automatically
                      print(
                          "All pieces are placed correctly. Puzzle completed!");
                    }
                  });
                },
                onMove: (details) {
                  print("details : $_dropPosition");
                  _dropPosition = details.offset;
                  var receivedBlock = details.data;
                  print("receivedblock : $receivedBlock");

                  if (isCorrectPosition(receivedBlock)) {
                    receivedBlock.offset = receivedBlock.correctPosition;
                    receivedBlock
                        .jigsawBlockWidget?.imageBox.isInCorrectPosition =
                    true; // moving time accepting code colour change to green
                    // receivedBlock.jigsawBlockWidget?.imageBox.isDone = true;
                    blocksNotifier.notifyListeners();
                    // widget.callbackSuccess.call();
                  } else {
                    double horizontalAdjustment = screenSize.width * 0.02;
                    double verticalAdjustment = screenSize.height * 0.05;

                    receivedBlock.offset = Offset(
                      _dropPosition.dx - horizontalAdjustment,
                      _dropPosition.dy - verticalAdjustment,
                    );
                  }
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    height: screenSize.width,
                    child: Listener(
                      onPointerUp: (event) {
                        // Additional check after user interaction
                        if (blocks.every((block) =>
                        block.jigsawBlockWidget?.imageBox.isDone ??
                            false)) {
                          resetJigsaw();
                          widget.callbackFinish.call();
                          print(
                              "All pieces are placed correctly. Puzzle completed!");
                        }
                      },
                      child: Stack(
                        children: [
                          if (blocks.isEmpty)
                            RepaintBoundary(
                              key: _globalKey,
                              child: Container(
                                height: double.maxFinite,
                                width: double.maxFinite,
                                child: widget.child,
                              ),
                            ),
                          Offstage(
                            offstage: blocks.isEmpty,
                            child: Container(
                              height: screenSize.height,
                              width: screenSize.width,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.black),
                              ),
                              child: CustomPaint(
                                painter: JigsawPainterBackground(blocks),
                                child: Stack(
                                  children: [
                                    if (blockDone.isNotEmpty)
                                      ...blockDone
                                          .where((block) => ((block
                                          .jigsawBlockWidget
                                          ?.imageBox
                                          .isDone ??
                                          true)))
                                          .toList()
                                          .map((block) {
                                        return Positioned(
                                            left: block.offset?.dx ?? 0,
                                            top: block.offset?.dy ?? 0,
                                            child: Container(
                                                child:
                                                block.jigsawBlockWidget));
                                      }).toList(),
                                    if (blockDone.isNotEmpty)
                                      ...blockCorrectPos.reversed
                                          .where((block) => (!(block
                                          .jigsawBlockWidget
                                          ?.imageBox
                                          .isDone ??
                                          false)))
                                          .toList()
                                          .map((block) {
                                        return Positioned(
                                          left: block.offset?.dx ?? 0,
                                          top: block.offset?.dy ?? 0,
                                          child: Draggable<BlockClass>(
                                            data: block,
                                            feedback: SizedBox(
                                              width: block.jigsawBlockWidget
                                                  ?.imageBox.size?.width ??
                                                  0,
                                              height: block.jigsawBlockWidget
                                                  ?.imageBox.size?.height ??
                                                  0,
                                              child: block.jigsawBlockWidget,
                                            ),
                                            childWhenDragging: Container(),
                                            onDragEnd: (details) {
                                              if (!details.wasAccepted) {
                                                setState(() {
                                                  blockCorrectPos.removeWhere(
                                                          (test) => block == test);
                                                  block
                                                      .jigsawBlockWidget
                                                      ?.imageBox
                                                      .isDropped = false;
                                                  blockDone.remove(block);
                                                  blockNotDone.add(block);
                                                });
                                              }
                                            },
                                            child: block.jigsawBlockWidget!,
                                          ),
                                        );
                                      }).toList(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
              // Carousel containing draggable puzzle pieces
              Container(
                decoration:
                BoxDecoration(border: Border.all(color: Colors.grey)),
                height: 100,
                child: CarouselSlider(
                  options: CarouselOptions(
                    height: 80,
                    viewportFraction: 0.25,
                    enableInfiniteScroll: false,
                    scrollPhysics: BouncingScrollPhysics(),
                  ),
                  items: blockNotDone.map((block) {
                    Size? sizeBlock = block.jigsawBlockWidget?.imageBox.size;
                    return FittedBox(
                      child: Container(
                        width: sizeBlock?.width ?? 0,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: sizeBlock?.height ?? 0,
                        child: Draggable<BlockClass>(
                          data: block,
                          feedback: Container(
                            width: sizeBlock?.width ?? 0,
                            height: sizeBlock?.height ?? 0,
                            child: block.jigsawBlockWidget,
                          ),
                          childWhenDragging: Container(),
                          child: FittedBox(
                            child: Container(
                              width: sizeBlock?.width ?? 0,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              height: sizeBlock?.height ?? 0,
                              child: block.jigsawBlockWidget,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool isCorrectPosition(BlockClass block) {
    const double tolerance = 5.0; // Reduced tolerance for a tighter fit

    if (block.offset == null) return false;

    double dx = (block.offset!.dx - block.correctPosition.dx).abs();
    double dy = (block.offset!.dy - block.correctPosition.dy).abs();
    print(dx);
    print(dy);

    return dx <= tolerance && dy <= tolerance;
  }
}





class JigsawPainterBackground extends CustomPainter {
  List<BlockClass> blocks;

  JigsawPainterBackground(this.blocks);

  @override
  void paint(Canvas canvas, Size size) {
    // Paint object with stroke style
    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
    // ..color=Colors.transparent
      ..strokeCap = StrokeCap.round;

    Path path = Path();

    // Loop through each block to generate the path for the jigsaw pieces
    blocks.forEach((element) {
      // Retrieve the path for the jigsaw piece based on its properties
      Path pathTemp = getPiecePath(
        element.jigsawBlockWidget?.imageBox.size ?? Size(0, 0),
        element.jigsawBlockWidget?.imageBox.radiusPoint ?? 0.0,
        element.jigsawBlockWidget?.imageBox.offsetCenter ?? Offset(0, 0),
        element.jigsawBlockWidget!.imageBox.posSide,
      );

      // Add the generated path to the main path, positioned at the block's default offset
      path.addPath(pathTemp, element.offsetDefault ?? Offset(0, 0));
    });

    // Draw the path on the canvas
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


class BlockClass {
  Offset? offset;
  Offset? offsetDefault;
  Offset correctPosition;
  JigsawBlockWidget? jigsawBlockWidget;

  BlockClass({
    this.offset,
    this.jigsawBlockWidget,  required this.correctPosition,

    this.offsetDefault,
  });
}

class ImageBox {
  Widget? image;
  ClassJigsawPos posSide;
  Offset? offsetCenter;
  Size? size;
  double? radiusPoint;
  bool? isDone;
  bool? isDropped; // New property to track if the block has been dropped
  bool? isInCorrectPosition;

  ImageBox({
    this.image,
    required this.posSide,
    this.isDone,
    this.offsetCenter,
    this.radiusPoint,
    this.size,
    this.isDropped = false,
    this.isInCorrectPosition = false,
  });
}

class ClassJigsawPos {
  int? top, bottom, left, right;

  ClassJigsawPos({this.top, this.bottom, this.left, this.right});
}

class JigsawBlockWidget extends StatefulWidget {
  ImageBox imageBox;
  Offset offsetDefault;

  JigsawBlockWidget(
      {Key? key, required this.imageBox, required this.offsetDefault})
      : super(key: key);

  @override
  _JigsawBlockWidgetState createState() => _JigsawBlockWidgetState();
}

class _JigsawBlockWidgetState extends State<JigsawBlockWidget> {
  // lets start clip crop image so show like jigsaw puzzle

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: PuzzlePieceClipper(imageBox: widget.imageBox),
      child: CustomPaint(
        foregroundPainter: JigsawBlockPainter.JigsawBlockPainter(imageBox: widget.imageBox,),
        child: widget.imageBox
            .image, // it sets the images in  the jig aw puzzle while clicking the generate
      ),
    );
  }
}
class JigsawBlockPainter extends CustomPainter {
  ImageBox? imageBox;

  JigsawBlockPainter.JigsawBlockPainter({this.imageBox});

  @override
  void paint(Canvas canvas, Size size) {
    // Paint the border with different colors depending on whether the piece is done
    Paint paint = Paint()
      ..color = (imageBox?.isInCorrectPosition ?? false)
          ? Colors.green.withOpacity(1) // Green if in correct position
          : Colors.red // Default color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Draw the puzzle piece path
    canvas.drawPath(
      getPiecePath(
        size,
        imageBox?.radiusPoint ?? 0.0,
        imageBox?.offsetCenter ?? Offset.zero,
        imageBox!.posSide,
      ),
      paint,
    );

    if (imageBox?.isDone ?? false) {
      Paint paintDone = Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..style = PaintingStyle.fill
        ..strokeWidth = 2;

      Path path = getPiecePath(
        size,
        imageBox?.radiusPoint ?? 0.0,
        imageBox?.offsetCenter ?? Offset.zero,
        imageBox!.posSide,
      );

      // Draw a fill to indicate the piece is done
      canvas.drawPath(path, paintDone);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}




class PuzzlePieceClipper extends CustomClipper<Path> {
  ImageBox imageBox;
  PuzzlePieceClipper({
    required this.imageBox,
  });
  @override
  Path getClip(Size size) {
    // Ensure that nullable arguments are handled safely
    double radiusPoint = this.imageBox.radiusPoint ?? 0.0;
    Offset offsetCenter = this.imageBox.offsetCenter ?? Offset.zero;
    ClassJigsawPos posSide = this.imageBox.posSide ?? ClassJigsawPos();

    // Call the function with non-nullable arguments
    return getPiecePath(size, radiusPoint, offsetCenter, posSide);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}


getPiecePath(
    Size size,
    double radiusPoint,
    Offset offsetCenter,
    ClassJigsawPos posSide,
    ) {
  Path path = new Path();

  Offset topLeft = Offset(0, 0);
  Offset topRight = Offset(size.width, 0);
  Offset bottomLeft = Offset(0, size.height);
  Offset bottomRight = Offset(size.width, size.height);

  // calculate top point on 4 point
  topLeft = Offset(posSide.left! > 0 ? radiusPoint : 0,
      (posSide.top! > 0) ? radiusPoint : 0) +
      topLeft;
  topRight = Offset(posSide.right! > 0 ? -radiusPoint : 0,
      (posSide.top! > 0) ? radiusPoint : 0) +
      topRight;
  bottomRight = Offset(posSide.right! > 0 ? -radiusPoint : 0,
      (posSide.bottom! > 0) ? -radiusPoint : 0) +
      bottomRight;
  bottomLeft = Offset(posSide.left! > 0 ? radiusPoint : 0,
      (posSide.bottom! > 0) ? -radiusPoint : 0) +
      bottomLeft;

  // calculate mid point for min & max
  double topMiddle = posSide.top == 0
      ? topRight.dy
      : (posSide.top! > 0
      ? topRight.dy - radiusPoint
      : topRight.dy + radiusPoint);
  double bottomMiddle = posSide.bottom == 0
      ? bottomRight.dy
      : (posSide.bottom! > 0
      ? bottomRight.dy + radiusPoint
      : bottomRight.dy - radiusPoint);
  double leftMiddle = posSide.left == 0
      ? topLeft.dx
      : (posSide.left! > 0
      ? topLeft.dx - radiusPoint
      : topLeft.dx + radiusPoint);
  double rightMiddle = posSide.right == 0
      ? topRight.dx
      : (posSide.right! > 0
      ? topRight.dx + radiusPoint
      : topRight.dx - radiusPoint);

  // solve.. wew

  path.moveTo(topLeft.dx, topLeft.dy);
  // top draw
  if (posSide.top != 0)
    path.extendWithPath(
        calculatePoint(Axis.horizontal, topLeft.dy,
            Offset(offsetCenter.dx, topMiddle), radiusPoint),
        Offset.zero);
  path.lineTo(topRight.dx, topRight.dy);
  // right draw
  if (posSide.right != 0)
    path.extendWithPath(
        calculatePoint(Axis.vertical, topRight.dx,
            Offset(rightMiddle, offsetCenter.dy), radiusPoint),
        Offset.zero);
  path.lineTo(bottomRight.dx, bottomRight.dy);
  if (posSide.bottom != 0)
    path.extendWithPath(
        calculatePoint(Axis.horizontal, bottomRight.dy,
            Offset(offsetCenter.dx, bottomMiddle), -radiusPoint),
        Offset.zero);
  path.lineTo(bottomLeft.dx, bottomLeft.dy);
  if (posSide.left != 0)
    path.extendWithPath(
        calculatePoint(Axis.vertical, bottomLeft.dx,
            Offset(leftMiddle, offsetCenter.dy), -radiusPoint),
        Offset.zero);
  path.lineTo(topLeft.dx, topLeft.dy);

  path.close();

  return path;
}

Path calculatePoint(
    Axis axis, double fromPoint, Offset point, double radiusPoint) {
  Path path = Path();
  if (axis == Axis.horizontal) {
    path.moveTo((point.dx - radiusPoint / 2) - 1, fromPoint - 1);

    path.quadraticBezierTo(
      (point.dx - radiusPoint) - 1,
      point.dy - 1,
      point.dx - 1,
      point.dy - 1,
    );

    // End of the "omega" curve: curve outwards again
    path.quadraticBezierTo(
      (point.dx + radiusPoint) - 1,
      (point.dy) - 1,
      (point.dx + radiusPoint / 2) - 1,
      fromPoint - 1,
    );
  } else if (axis == Axis.vertical) {
    path.moveTo(fromPoint - 1, (point.dy - 1) - radiusPoint / 2);

    // Middle of the "omega" curve: curve inwards directly without initial bend
    path.quadraticBezierTo(
      point.dx - 1,
      (point.dy - radiusPoint) - 1,
      point.dx - 1,
      point.dy - 1,
    );

    // End of the "omega" curve: curve outwards again
    path.quadraticBezierTo(
      point.dx - 1,
      (point.dy + radiusPoint) - 1,
      fromPoint - 1,
      (point.dy + radiusPoint / 2) - 1,
    );
  }

  return path;
}


*/