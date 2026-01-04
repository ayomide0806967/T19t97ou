import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/core/note/note_repository.dart';
import 'package:my_app/core/supabase/supabase_note_repository.dart';

import '../helpers/supabase_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Supabase Notes E2E', () {
    test('can create note with section and publish', () async {
      if (!SupabaseTestHelper.hasConfig) {
        return;
      }

      final client = await SupabaseTestHelper.ensureSupabaseClient();
      expect(client, isNotNull);

      // Create a lightweight class to attach the note to.
      final classRow = await client!.from('classes').insert({
        'code': 'E2ENOTE',
        'name': 'E2E Note Class',
        'delivery_mode': 'online',
        'is_public': true,
      }).select('id').single();

      final classId = classRow['id'] as String;

      final repo = SupabaseNoteRepository(client);

      final note = await repo.createNote(
        CreateNoteRequest(
          classId: classId,
          title: 'E2E Note',
          description: 'Created by automated test',
          sections: const [
            CreateNoteSectionRequest(
              content: 'First section',
              heading: 'Intro',
            ),
          ],
        ),
      );

      expect(note.classId, classId);

      final sections = await repo.getSections(note.id);
      expect(sections, isNotEmpty);
      expect(sections.first.content, 'First section');

      final published = await repo.publishNote(note.id);
      expect(published.isPublished, isTrue);

      // Clean up test data.
      await client.from('note_sections').delete().eq('note_id', note.id);
      await client.from('class_notes').delete().eq('id', note.id);
      await client.from('classes').delete().eq('id', classId);
    });
  });
}

