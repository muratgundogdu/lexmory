import 'package:flutter_riverpod/legacy.dart';

/// Provider to control which tab is selected in the Library Archive (Library vs Collection)
final libraryTabProvider = StateProvider<int>((ref) => 0);

/// Transient signal provider to request a scroll focus on the current active room
final libraryFocusRequestProvider = StateProvider<bool>((ref) => true);
