import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/source_filter.dart';
import '../providers/search_provider.dart';

class SourcePicker extends ConsumerStatefulWidget {
  final void Function(SourceFilter source) onSourceSelected;

  const SourcePicker({super.key, required this.onSourceSelected});

  @override
  ConsumerState<SourcePicker> createState() => _SourcePickerState();
}

class _SourcePickerState extends ConsumerState<SourcePicker> {
  final _controller = TextEditingController();
  List<SourceFilter> _sources = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchSources(query);
    });
  }

  Future<void> _searchSources(String query) async {
    if (query.length < 2) {
      setState(() => _sources = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final service = ref.read(europresseServiceProvider);
      final results = await service.searchSources(query);
      if (mounted) {
        setState(() {
          _sources = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Rechercher une source...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          )
        else
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _sources.length,
              itemBuilder: (context, index) {
                final source = _sources[index];
                return ListTile(
                  title: Text(source.title),
                  onTap: () => widget.onSourceSelected(source),
                );
              },
            ),
          ),
      ],
    );
  }
}
