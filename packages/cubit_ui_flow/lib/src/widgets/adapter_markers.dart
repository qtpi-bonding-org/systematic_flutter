import 'package:flutter/widgets.dart';

/// Marks a stateless widget as an adapter: the boundary between a Cubit and
/// dumb presentation widgets. Carries no behaviour; it exists so lints can
/// tell adapters apart from presentation widgets.
abstract class AdapterWidget extends StatelessWidget {
  const AdapterWidget({super.key});
}

/// Stateful counterpart of [AdapterWidget]. Carries no behaviour; it exists
/// so lints can tell stateful adapters apart from presentation widgets.
abstract class StatefulAdapterWidget extends StatefulWidget {
  const StatefulAdapterWidget({super.key});
}
