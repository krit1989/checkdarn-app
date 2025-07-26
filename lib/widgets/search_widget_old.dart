import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
impo  void _selectDestination(SearchResult result) {
    _searchController.text = _getDisplayName(result);
    setState(() {
      _isExpanded = false;
      _searchResults.clear();
    });
    _focusNode.unfocus();
    
    // 🎉 Success haptic feedback
    HapticFeedback.mediumImpact();
    
    // 🚀 Navigate immediately
    widget.onDestinationSelected(result.location, result.displayName);
  }vices/navigation_service.dart';

class SearchWidget extends StatefulWidget {
  final Function(LatLng destination, String name) onDestinationSelected;
  final VoidCallback? onClose;
  
  const SearchWidget({
    super.key,
    required this.onDestinationSelected,
    this.onClose,
  });

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<SearchResult> _searchResults = [];
  bool _isLoading = false;
  bool _isExpanded = false;
  
  // 🚀 Smart Debouncing & Instant Search
  Timer? _debounceTimer;
  String _lastQuery = '';
  static const Duration _debounceDelay = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    
    // 🎯 Show popular places immediately when opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPopularPlaces();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// 🌟 Show Popular Places on Widget Open
  void _showPopularPlaces() {
    _performSearch('เซ็นทรัล'); // This will show popular places instantly
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    
    // Clear timer
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isExpanded = false;
      });
      return;
    }

    if (query.length >= 1) { // Reduced from 2 to 1 for faster response
      // 🚀 Instant search for cached results
      if (query != _lastQuery) {
        _debounceTimer = Timer(_debounceDelay, () {
          _performSearch(query);
        });
      }
    }
  }

  /// 🚀 Enhanced Search with Smart Feedback
  Future<void> _performSearch(String query) async {
    if (query == _lastQuery && _searchResults.isNotEmpty) {
      return; // Skip duplicate searches
    }
    
    _lastQuery = query;
    
    setState(() {
      _isLoading = true;
      _isExpanded = true;
    });

    try {
      print('🔍 SearchWidget: Starting search for "$query"');
      final stopwatch = Stopwatch()..start();
      
      final results = await NavigationService.searchPlaces(query);
      
      stopwatch.stop();
      print('📍 SearchWidget: Got ${results.length} results in ${stopwatch.elapsedMilliseconds}ms');
      
      if (mounted && query == _searchController.text.trim()) { // Check if query is still current
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
        
        // 🎉 Success feedback for fast searches
        if (stopwatch.elapsedMilliseconds < 500 && results.isNotEmpty) {
          HapticFeedback.lightImpact();
        }
      }
    } catch (e) {
      print('❌ SearchWidget error: $e');
      if (mounted) {
        setState(() {
          _searchResults.clear();
          _isLoading = false;
        });
        
        // Enhanced error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.search_off, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ไม่พบผลการค้นหา กรุณาลองคำค้นหาอื่น',
                    style: const TextStyle(fontFamily: 'Kanit'),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _selectDestination(SearchResult result) {
    _searchController.text = _getDisplayName(result);
    setState(() {
      _isExpanded = false;
      _searchResults.clear();
    });
    _focusNode.unfocus();
    
    widget.onDestinationSelected(result.location, _getDisplayName(result));
  }

  String _getDisplayName(SearchResult result) {
    // ลองแยกส่วนที่สำคัญออกมา
    final parts = result.displayName.split(',');
    if (parts.length >= 2) {
      return '${parts[0].trim()}, ${parts[1].trim()}';
    }
    return result.displayName;
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults.clear();
      _isExpanded = false;
    });
    if (widget.onClose != null) {
      widget.onClose!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ช่องค้นหา
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(
                  Icons.search,
                  color: Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    style: const TextStyle(
                      fontFamily: 'Kanit',
                      fontSize: 16,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'ค้นหาจุดหมาย...',
                      hintStyle: TextStyle(
                        fontFamily: 'Kanit',
                        color: Colors.grey,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: _clearSearch,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ผลการค้นหา
          if (_isExpanded) ...[
            const Divider(height: 1),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _searchResults.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'ไม่พบผลการค้นหา',
                            style: TextStyle(
                              fontFamily: 'Kanit',
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final result = _searchResults[index];
                            return _buildSearchResult(result);
                          },
                        ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResult(SearchResult result) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1158F2).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              result.displayIcon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        title: Text(
          result.shortName,
          style: const TextStyle(
            fontFamily: 'Kanit',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.categoryDisplayName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getCategoryColor(result.category).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  result.categoryDisplayName,
                  style: TextStyle(
                    fontFamily: 'Kanit',
                    fontSize: 12,
                    color: _getCategoryColor(result.category),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              result.address,
              style: TextStyle(
                fontFamily: 'Kanit',
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: result.importance != null && result.importance! > 0.5
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ยอดนิยม',
                  style: TextStyle(
                    fontFamily: 'Kanit',
                    fontSize: 10,
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
        onTap: () => _selectDestination(result),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'amenity': return const Color(0xFF4CAF50); // เขียว
      case 'shop': return const Color(0xFF2196F3); // น้ำเงิน
      case 'tourism': return const Color(0xFF9C27B0); // ม่วง
      case 'leisure': return const Color(0xFF00BCD4); // ฟ้าอ่อน
      default: return const Color(0xFF757575); // เทา
    }
  }
}
