import 'package:flutter/material.dart';

import '../views/home_view.dart';

/// The only place that builds [HomeView]. The live route and the catalog
/// both go through here, so they cannot drift apart.
class HomeScreenAssembly {
  HomeScreenAssembly._();

  static Widget assemble({
    required Widget header,
    required Widget tabs,
    required Widget search,
    required Widget status,
    required VoidCallback onStartFlow,
  }) => HomeView(
    header: header,
    tabs: tabs,
    search: search,
    status: status,
    onStartFlow: onStartFlow,
  );
}
