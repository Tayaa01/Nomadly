import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// A widget that shows 6 boxes for OTP/reset code entry
class OtpDigitInput extends StatefulWidget {
  final ValueChanged<String> onComplete;
  final String? initialValue;
  final int length;

  const OtpDigitInput({
    super.key,
    required this.onComplete,
    this.initialValue,
    this.length = 6,
  });

  @override
  State<OtpDigitInput> createState() => _OtpDigitInputState();
}

class _OtpDigitInputState extends State<OtpDigitInput> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  // Track when all digits are entered
  bool get _isComplete => _controllers.every((c) => c.text.isNotEmpty);

  @override
  void initState() {
    super.initState();

    // Create controllers and focus nodes for each digit
    _controllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(widget.length, (index) => FocusNode());

    // If initial value is provided, populate the fields
    if (widget.initialValue != null) {
      final digits = widget.initialValue!.split('');
      for (int i = 0; i < digits.length && i < widget.length; i++) {
        _controllers[i].text = digits[i];
      }
    }

    // Add listeners to each controller
    for (int i = 0; i < widget.length; i++) {
      _controllers[i].addListener(() {
        _checkAndMoveToNextField(i);
      });
    }
  }

  void _checkAndMoveToNextField(int currentIndex) {
    // If the current field has text and there's a next field, move focus
    if (_controllers[currentIndex].text.isNotEmpty) {
      if (currentIndex < widget.length - 1) {
        FocusScope.of(context).requestFocus(_focusNodes[currentIndex + 1]);
      } else {
        // Last digit was entered, unfocus and trigger onComplete
        _focusNodes[currentIndex].unfocus();
        if (_isComplete) {
          final code = _controllers.map((c) => c.text).join('');
          widget.onComplete(code);
        }
      }
    }
  }

  void _handleBackspace(int currentIndex) {
    // If current field is empty and there's a previous field, go back
    if (_controllers[currentIndex].text.isEmpty && currentIndex > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[currentIndex - 1]);
    }
  }

  @override
  void dispose() {
    // Clean up controllers and focus nodes
    for (int i = 0; i < widget.length; i++) {
      _controllers[i].dispose();
      _focusNodes[i].dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.length, (index) => _buildDigitBox(index)),
    );
  }

  Widget _buildDigitBox(int index) {
    return Container(
      width: 45,
      height: 55,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              _focusNodes[index].hasFocus
                  ? const Color(0xFF4CD964)
                  : const Color(0xFF333333),
          width: _focusNodes[index].hasFocus ? 2 : 1,
        ),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) {
          // Handle backspace navigation
          if (value.isEmpty) {
            _handleBackspace(index);
          }
        },
        onTap: () {
          // Select all text when tapping on a filled box
          if (_controllers[index].text.isNotEmpty) {
            _controllers[index].selection = TextSelection(
              baseOffset: 0,
              extentOffset: _controllers[index].text.length,
            );
          }
        },
      ),
    );
  }
}
