import 'package:flutter/material.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  @override
  _CustomAppBarState createState() => _CustomAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  bool isSearching = false; // Flag to toggle search bar visibility
  TextEditingController _searchController = TextEditingController(); // Text controller

  @override
  Widget build(BuildContext context) {
    // Get screen width using MediaQuery
    double screenWidth = MediaQuery.of(context).size.width;

    // Set the search bar width to 80% of the screen width, you can adjust this value
    double searchBarWidth = screenWidth * 0.95; // 95% of screen width

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: !isSearching // Hide logo when searching
          ? Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: 150,
          height: 150,
          child: Image.asset('assets/tarumt_logo.png', fit: BoxFit.contain),
        ),
      )
          : Container(), // Empty container when searching is active
      actions: [
        isSearching
            ? Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // Wrap the TextField in a Container and set width to 80% of screen width
              Container(
                width: searchBarWidth, // Set responsive width
                child: TextField(
                  controller: _searchController,
                  autofocus: true, // Automatically focus the TextField
                  decoration: InputDecoration(
                    hintText: 'Search anything...',
                    hintStyle: TextStyle(
                      color: Colors.grey, // Optional: Customize the hint text color
                    ),
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _searchController.clear(); // Clear the search field
                          isSearching = false; // Hide search bar and show logo
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Color(0xFFF0F0F0),
                    contentPadding: EdgeInsets.symmetric(vertical: 0), // Center vertically
                  ),
                  textAlignVertical: TextAlignVertical.center, // Vertically center the text
                ),
              ),
            ],
          ),
        )
            : // Show search icon when not searching
        IconButton(
          icon: Icon(Icons.search, color: Colors.black),
          onPressed: () {
            setState(() {
              isSearching = true; // Show search bar and hide logo
            });
          },
        ),
      ],
    );
  }
}
