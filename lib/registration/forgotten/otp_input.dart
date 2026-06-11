import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpInput extends StatefulWidget {
  final Function(String) onCompleted;

  const OtpInput({super.key, required this.onCompleted});

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final controllers = List.generate(6, (_) => TextEditingController());
  final nodes = List.generate(6, (_) => FocusNode());

  void _onChanged(String value, int index) {
    if (value.length > 1) {
      _paste(value);
      return;
    }

    if (value.isNotEmpty && index < 5) {
      nodes[index + 1].requestFocus();
    }

    _check();
  }

  void _paste(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    for (int i = 0; i < digits.length && i < 6; i++) {
      controllers[i].text = digits[i];
    }

    FocusScope.of(context).unfocus();
    _check();
  }

  void _check() {
    final code = controllers.map((e) => e.text).join();

    if (code.length == 6) {
      widget.onCompleted(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        return SizedBox(
          width: 45,
          child: TextField(
            controller: controllers[i],
            focusNode: nodes[i],
            keyboardType: TextInputType.number,
            maxLength: 1,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(
              counterText: "",
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => _onChanged(v, i),
          ),
        );
      }),
    );
  }
}