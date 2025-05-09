import 'package:bluenote/widgets/guanlam/image_view.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageCarousel extends StatefulWidget {
  final List<String> imageUrls;

  const ImageCarousel({required this.imageUrls, super.key});

  @override
  _ImageCarouselState createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  int _currentPageIndex = 0;

  void _onPageChanged(int index) {
    setState(() {
      _currentPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.imageUrls[0].isNotEmpty
        ? Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 280, // Or make dynamic later
          child: Stack(
            children: [
              PageView.builder(
                itemCount: widget.imageUrls.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImageView(
                            imageUrls: widget.imageUrls,
                          ),
                        ),
                      );
                    },
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 3.0,
                      child: CachedNetworkImage(
                        imageUrl: widget.imageUrls[index],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
              // Top-right index number
              if (widget.imageUrls.length > 1)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${_currentPageIndex + 1} / ${widget.imageUrls.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Bullet indicators
        if (widget.imageUrls.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.imageUrls.length,
                    (index) => AnimatedContainer(
                  duration: Duration(milliseconds: 100),
                  margin: EdgeInsets.symmetric(horizontal: 3),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentPageIndex == index
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
      ],
    )
        : SizedBox(); // If no image
  }
}
