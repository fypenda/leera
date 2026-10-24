import 'package:flutter_test/flutter_test.dart';
import 'package:leera/features/english/presentation/english_feedback_page.dart';

void main() {
  test('headlines are shown without their emoji', () {
    expect(withoutEmoji('Too short to assess 🎤'), 'Too short to assess');
    expect(withoutEmoji('No essay to assess yet 📝'), 'No essay to assess yet');
    expect(withoutEmoji('Clear and well built 🎉'), 'Clear and well built');
    expect(withoutEmoji('Two ✍️ in 👨‍👩‍👧 one'), 'Two in one');
    expect(withoutEmoji('A B2 level, 100% clear'), 'A B2 level, 100% clear');
  });
}
