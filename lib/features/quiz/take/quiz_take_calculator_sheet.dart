part of 'quiz_take_screen.dart';

extension _QuizTakeCalculatorSheet on _QuizTakeScreenState {
  void _openCalculator() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => const _IOSStyleCalculatorSheet(),
    );
  }
}

class _IOSStyleCalculatorSheet extends StatefulWidget {
  const _IOSStyleCalculatorSheet();

  @override
  State<_IOSStyleCalculatorSheet> createState() =>
      _IOSStyleCalculatorSheetState();
}

class _IOSStyleCalculatorSheetState extends State<_IOSStyleCalculatorSheet> {
  String _display = '0';
  double? _firstOperand;
  String? _pendingOperator;
  bool _resetOnNextDigit = false;
  String? _lastExpression;
  bool _justEvaluated = false;

  String _formatNumber(double value) {
    final fixed = value.toStringAsFixed(6);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  String get _expressionText {
    if (_lastExpression != null) {
      return _lastExpression!;
    }
    if (_firstOperand == null || _pendingOperator == null) {
      return _display;
    }
    final left = _formatNumber(_firstOperand!);
    final String right = _resetOnNextDigit ? '' : _display;
    if (right.isEmpty) {
      return '$left $_pendingOperator';
    }
    return '$left $_pendingOperator $right';
  }

  void _tapDigit(String digit) {
    setState(() {
      _justEvaluated = false;
      _lastExpression = null;
      if (_resetOnNextDigit) {
        _display = digit == '.' ? '0.' : digit;
        _resetOnNextDigit = false;
        return;
      }
      if (digit == '.') {
        if (_display.contains('.')) return;
        _display = '$_display.';
      } else {
        _display = _display == '0' ? digit : '$_display$digit';
      }
    });
  }

  void _clearAll() {
    setState(() {
      _display = '0';
      _firstOperand = null;
      _pendingOperator = null;
      _resetOnNextDigit = false;
      _lastExpression = null;
      _justEvaluated = false;
    });
  }

  void _toggleSign() {
    setState(() {
      if (_display == '0') return;
      if (_display.startsWith('-')) {
        _display = _display.substring(1);
      } else {
        _display = '-$_display';
      }
    });
  }

  void _percent() {
    final value = double.tryParse(_display);
    if (value == null) return;
    setState(() {
      final result = value / 100;
      _display = _formatNumber(result);
      _lastExpression = null;
      _justEvaluated = false;
    });
  }

  void _setOperator(String op) {
    final value = double.tryParse(_display);
    if (value == null) return;
    setState(() {
      _firstOperand = value;
      _pendingOperator = op;
      _resetOnNextDigit = true;
      _lastExpression = null;
      _justEvaluated = false;
    });
  }

  void _calculate() {
    if (_firstOperand == null || _pendingOperator == null) return;
    final second = double.tryParse(_display);
    if (second == null) return;
    double result = _firstOperand!;
    switch (_pendingOperator) {
      case '+':
        result = _firstOperand! + second;
        break;
      case '−':
        result = _firstOperand! - second;
        break;
      case '×':
        result = _firstOperand! * second;
        break;
      case '÷':
        if (second != 0) {
          result = _firstOperand! / second;
        }
        break;
    }
    setState(() {
      final left = _formatNumber(_firstOperand!);
      final right = _formatNumber(second);
      final resultStr = _formatNumber(result);
      _lastExpression = '$left $_pendingOperator $right = $resultStr';
      _display = resultStr;
      _firstOperand = null;
      _pendingOperator = null;
      _resetOnNextDigit = true;
      _justEvaluated = true;
    });
  }

  Widget _buildButton({
    required String label,
    Color? background,
    Color? foreground,
    double flex = 1,
    VoidCallback? onTap,
  }) {
    return Expanded(
      flex: flex.round(),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: background ?? const Color(0xFF333333),
              borderRadius: BorderRadius.circular(28),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: foreground ?? Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color operatorColor = const Color(0xFFFF9500);
    final Color lightKey = const Color(0xFFA5A5A5);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Text(
                  _expressionText,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Keypad
              Column(
                children: [
                  Row(
                    children: [
                      _buildButton(
                        label: 'AC',
                        background: lightKey,
                        foreground: Colors.black,
                        onTap: _clearAll,
                      ),
                      _buildButton(
                        label: '+/−',
                        background: lightKey,
                        foreground: Colors.black,
                        onTap: _toggleSign,
                      ),
                      _buildButton(
                        label: '%',
                        background: lightKey,
                        foreground: Colors.black,
                        onTap: _percent,
                      ),
                      _buildButton(
                        label: '÷',
                        background: operatorColor,
                        onTap: () => _setOperator('÷'),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton(label: '7', onTap: () => _tapDigit('7')),
                      _buildButton(label: '8', onTap: () => _tapDigit('8')),
                      _buildButton(label: '9', onTap: () => _tapDigit('9')),
                      _buildButton(
                        label: '×',
                        background: operatorColor,
                        onTap: () => _setOperator('×'),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton(label: '4', onTap: () => _tapDigit('4')),
                      _buildButton(label: '5', onTap: () => _tapDigit('5')),
                      _buildButton(label: '6', onTap: () => _tapDigit('6')),
                      _buildButton(
                        label: '−',
                        background: operatorColor,
                        onTap: () => _setOperator('−'),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton(label: '1', onTap: () => _tapDigit('1')),
                      _buildButton(label: '2', onTap: () => _tapDigit('2')),
                      _buildButton(label: '3', onTap: () => _tapDigit('3')),
                      _buildButton(
                        label: '+',
                        background: operatorColor,
                        onTap: () => _setOperator('+'),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton(
                        label: '0',
                        flex: 2,
                        onTap: () => _tapDigit('0'),
                      ),
                      _buildButton(label: '.', onTap: () => _tapDigit('.')),
                      _buildButton(
                        label: '=',
                        background: operatorColor,
                        onTap: _calculate,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
