import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simpletouch/airtouch_comms/airtouch_comms.dart';
import 'package:simpletouch/models/ac.dart';

class ACModeButtons extends StatelessWidget {
  const ACModeButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AirtouchComms>(
      builder: (ctx, comms, _) {
        if (!comms.connectedToConsole ||
            comms.connectedACStatus == null ||
            comms.connectedACStatus!.isEmpty) {
          return Container();
        }

        final mode = comms.connectedACStatus![0].mode;
        return Row(
          spacing: 8.0,
          children: [
            ...ACMode.values.map((currentMode) {
              final activeMode = currentMode == mode;

              final button =
                  activeMode ? FilledButton.icon : FilledButton.tonalIcon;

              return Expanded(
                child: SizedBox(
                  height: 48,
                  child: button(
                    onPressed: () {},
                    label: Icon(acModeToIconMap[currentMode]),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
