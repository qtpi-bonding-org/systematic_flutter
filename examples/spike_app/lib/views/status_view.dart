import 'package:flutter/material.dart';
import 'package:systematic_ui/systematic_ui.dart';

import '../l10n/l10n_key_resolver.g.dart';
import '../status/status_cubit.dart';

class StatusView extends StatelessWidget {
  const StatusView({super.key, required this.data});

  final StatusData data;

  @override
  Widget build(BuildContext context) =>
      Text(context.resolveLabel(L10nKeys.statusTick(count: data.tick)));
}
