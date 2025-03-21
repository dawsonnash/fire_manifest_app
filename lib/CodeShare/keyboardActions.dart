import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

import 'variables.dart';

KeyboardActionsConfig keyboardActionsConfig({
  required List<FocusNode> focusNodes,
}) {
  return KeyboardActionsConfig(
    keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
    keyboardBarColor: const Color(0xFFCAD1D9), // Apple keyboard color
    actions: focusNodes.map((focusNode) {
      return KeyboardActionsItem(
        focusNode: focusNode,
        toolbarButtons: [
              (node) {
            return GestureDetector(
              onTap: () => node.unfocus(),
              child: Container(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'Done',
                  style: TextStyle(
                    color: const Color(0xFF0978ED),
                    fontWeight: FontWeight.bold,
                    fontSize: AppData.text16
                  ),
                ),
              ),
            );
          },
        ],
      );
    }).toList(),
  );
}
