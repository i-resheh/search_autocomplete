import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'components/default_drop_down.dart';
import 'components/default_text_field.dart';
import 'models/position_form.dart';
import 'func_typedef/func_typedef.dart';

/// A `SearchAutocomplete` widget to provide an auto-complete search functionality with a dropdown.
///
/// This widget allows for extensive customization of the search field, dropdown items,
/// and contains hooks for search logic.
///
/// **Constructor Parameters:**
/// - `options`: A list of generic type options that will populate the dropdown.
/// - `initValue`: The initial value that will appear in the search bar.
/// - `getString`: A function that takes an item of generic type `T` and returns its `String` representation.
/// - `onSearch`: A function that handles search logic and is invoked when the user types in the search bar.
/// - `fieldBuilder`: A custom builder function for the search bar. If not provided, a default one is used.
/// - `dropDownBuilder`: A custom builder function for the dropdown items. If not provided, a default one is used.
/// - `onSelected`: A function that fires when an item is selected from the dropdown.
/// - `hintText`: A placeholder text that appears in the search bar.
/// - `emptyDropDown`: A custom builder function that builds a widget to display when the dropdown is empty.
///
class SearchAutocomplete<T> extends StatefulWidget {
  /// A list of options to be displayed in the dropdown.
  ///
  /// This is usually a list of strings but can be a list of any type
  /// as long as it can be mapped to a string representation.
  final List<T> options;

  /// An optional initial value for the search field.
  ///
  /// This can be useful if you have a default value you'd like to have
  /// pre-filled in the search field when the widget first loads.
  final T? initValue;

  /// Function to transform an option object to its string representation.
  ///
  /// This function is used to convert the generic type options to string
  /// to be displayed in the search field and dropdown.
  final String Function(T) getString;

  /// Function that handles the search logic.
  ///
  /// It's invoked when the user types into the search bar.
  /// This function is meant to filter the list of `options`
  /// based on the user's input.
  final ValueSetter<String> onSearch;

  /// A builder function to create a custom search field.
  ///
  /// If this is null, a default search field will be used.
  final TextFieldWithArgs? fieldBuilder;

  /// A builder function to create custom dropdown items.
  ///
  /// If this is null, default dropdown items will be used.
  final DropDownWithArgs<T>? dropDownBuilder;

  /// Callback function that fires when an item is selected from the dropdown.
  ///
  /// This function is invoked with the selected option as its argument.
  final ValueChanged<T>? onSelected;

  /// An optional placeholder text for the search field.
  ///
  /// If this is null, no placeholder will be displayed.
  final String? hintText;

  /// A function to build a custom widget to display when the dropdown is empty.
  ///
  /// If this is null, no widget will be displayed for an empty dropdown.
  final Widget Function(TextEditingController controller, VoidCallback close)?
      emptyDropDown;

  /// Creates a `SearchAutocomplete` widget.
  const SearchAutocomplete({
    super.key,
    required this.options,
    required this.initValue,
    required this.getString,
    required this.onSearch,
    this.fieldBuilder,
    this.dropDownBuilder,
    this.onSelected,
    this.hintText,
    this.emptyDropDown,
  });

  @override
  State<SearchAutocomplete<T>> createState() => _SearchAutocompleteState<T>();
}

class _SearchAutocompleteState<T> extends State<SearchAutocomplete<T>>
    with WidgetsBindingObserver {
  final _controller = TextEditingController();
  bool _showDropdown = false;

  final _optionsStrCtr = StreamController<List<T>>.broadcast();

  OverlayEntry? _overlayEntry;
  Ticker? _ticker;

  final _positionForm = ValueNotifier(const PositionForm());

  void _insertOverlay(BuildContext context) {
    _overlayEntry?.remove();

    _positionForm.value = PositionForm.fromRect(context._globalPaintBounds);

    if (!_positionForm.value.valid) return;

    _overlayEntry = OverlayEntry(
      builder: (_) {
        return ValueListenableBuilder<PositionForm>(
          valueListenable: _positionForm,
          builder: (context, PositionForm positionForm, child) {
            return Stack(
              children: [
                CustomGestureDetector(
                  onTap: _tapOutside,
                  ignoredArea: positionForm.area,
                  child: const SizedBox.expand(),
                ),
                positionForm.wrapAreaUnder(
                  child: Material(
                    color: Colors.transparent,
                    child: _buildDropdown(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _showDropdown = false;
  }

  void _showOverlay() {
    _showDropdown = true;
    _insertOverlay(context);
  }

  _updateInitValue() {
    final value = widget.initValue;
    _controller.text = value != null ? widget.getString(value) : '';
  }

  void _filterOptions() {
    final query = _controller.text;

    widget.onSearch(query);
  }

  void _onFieldTap() {
    setState(() {
      _showOverlay();
    });
  }

  void _onSelect(T option) {
    _postSelectAction();
    widget.onSelected?.call(option);
  }

  void _postSelectAction() {
    const duration = Duration(milliseconds: 150);
    Future.delayed(duration).then((value) {
      setState(() {
        _removeOverlay();
      });
    });
    FocusScope.of(context).unfocus();
  }

  void _tapOutside() {
    setState(() {
      FocusScope.of(context).unfocus();
      _removeOverlay();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final value = widget.initValue;
    _controller.text = value != null ? widget.getString(value) : '';
    _controller.addListener(_filterOptions);

    _ticker = Ticker((timer) {
      if (!_showDropdown) return;
      final positionForm = PositionForm.fromRect(context._globalPaintBounds);

      if (_positionForm.value == positionForm) return;

      _positionForm.value = positionForm;
    })
      ..start();
  }

  @override
  void didChangeTextScaleFactor() {
    if (_showDropdown) {
      _insertOverlay(context);
    }
  }

  @override
  void didUpdateWidget(SearchAutocomplete<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      if (oldWidget.options != widget.options && _showDropdown) {
        _optionsStrCtr.add(widget.options);
      }
      if (oldWidget.initValue != widget.initValue) {
        _updateInitValue();
      }
    });
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _controller.removeListener(_filterOptions);
    _controller.dispose();
    _optionsStrCtr.close();
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.fieldBuilder?.call(
          _controller,
          _onFieldTap,
          _showDropdown,
        ) ??
        DefaultTextField(
          controller: _controller,
          onFieldTap: _onFieldTap,
          showDropdown: _showDropdown,
          hintText: widget.hintText,
        );

    return child;
  }

  Widget _buildDropdown() {
    return StreamBuilder<List<T>>(
      stream: _optionsStrCtr.stream,
      builder: (context, snapshot) {
        final options = snapshot.data ?? widget.options;

        if (options.isEmpty) {
          return widget.emptyDropDown?.call(_controller, _removeOverlay) ??
              const SizedBox.shrink();
        }

        final child = widget.dropDownBuilder?.call(options, _onSelect) ??
            DefaultDropDown<T>(
              options: options,
              onSelected: _onSelect,
              getString: widget.getString,
            );

        return SizedBox(
          width: MediaQuery.sizeOf(context).width,
          height: MediaQuery.sizeOf(context).height,
          child: child,
        );
      },
    );
  }
}

extension _GlobalPaintBounds on BuildContext {
  Rect? get _globalPaintBounds {
    final renderObject = findRenderObject();
    final translation = renderObject?.getTransformTo(null).getTranslation();
    if (translation != null && renderObject?.paintBounds != null) {
      final offset = Offset(translation.x, translation.y);
      return renderObject?.paintBounds.shift(offset);
    } else {
      return null;
    }
  }
}

class CustomGestureDetector extends StatelessWidget {
  final Widget child;
  final Rect ignoredArea;
  final VoidCallback onTap;

  const CustomGestureDetector({
    super.key,
    required this.child,
    required this.ignoredArea,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: <Type, GestureRecognizerFactory>{
        CustomTapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<CustomTapGestureRecognizer>(
          () {
            return CustomTapGestureRecognizer(
              onTap: onTap,
              ignoredArea: ignoredArea,
            );
          },
          (CustomTapGestureRecognizer instance) {},
        ),
      },
      child: child,
    );
  }
}

class CustomTapGestureRecognizer extends TapGestureRecognizer {
  final Rect ignoredArea;

  CustomTapGestureRecognizer({
    required VoidCallback onTap,
    required this.ignoredArea,
  }) : super() {
    this.onTap = onTap;
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (ignoredArea.contains(event.position)) {
      return;
    }
    super.addAllowedPointer(event);
  }
}
