import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
// Note: file_picker is optional. We avoid importing it so the app builds even
// when the dependency hasn't been fetched. If you add file_picker to
// pubspec and run `flutter pub get`, you can re-enable file attachments by
// switching _handleAttachFile() to use FilePicker.
import 'quiz_hub_screen.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../services/data_service.dart';
import '../models/post.dart';
import '../widgets/tweet_post_card.dart';
import '../widgets/icons/x_retweet_icon.dart';
import '../theme/app_theme.dart';
import '../services/simple_auth_service.dart';
import '../services/roles_service.dart';
import '../screens/post_activity_screen.dart';
import '../screens/create_note_flow/teacher_note_creation_screen.dart';
import '../services/members_service.dart';
import '../services/invites_service.dart';
import 'user_profile_screen.dart';
import 'create_class_screen.dart';
import 'class_note_stepper_screen.dart';
import '../widgets/equal_width_buttons_row.dart';
import '../widgets/setting_switch_row.dart';
import '../core/user/handle.dart';
import '../models/class_note.dart';
import '../models/college.dart';
import '../models/class_topic.dart';
import '../features/notes/class_notes_store.dart';
// Removed unused tweet widgets imports

part 'ios_messages/replies_route.dart';
part 'ios_messages/minimalist_message_page.dart';
part 'ios_messages/full_page_classes_screen.dart';
part 'ios_messages/spotify_style_hero.dart';
part 'ios_messages/inbox_list.dart';
part 'ios_messages/classes_experience.dart';
part 'ios_messages/create_class_page.dart';
part 'ios_messages/college_detail_screen.dart';
part 'ios_messages/discussion_thread_page.dart';
part 'ios_messages/thread_models.dart';

part 'ios_messages/interaction_widgets.dart';
part 'ios_messages/message_comments_page.dart';
part 'ios_messages/comment_tile.dart';

part 'ios_messages/class_notes_card.dart';
part 'ios_messages/class_message_model.dart';
part 'ios_messages/class_library_tab.dart';
part 'ios_messages/class_students_tab.dart';

part 'ios_messages/college_screen_state.dart';

part 'ios_messages/class_feed_tab.dart';

part 'ios_messages/topic_feed.dart';
part 'ios_messages/class_composer.dart';
part 'ios_messages/class_message_tile.dart';

part 'ios_messages/create_class_wizard_widgets.dart';

// WhatsApp color palette for Classes screen
const Color _whatsAppGreen = Color(0xFF25D366);
const Color _whatsAppDarkGreen = Color(0xFF128C7E);
const Color _whatsAppLightGreen = Color(0xFFDCF8C6);
const Color _whatsAppTeal = Color(0xFF075E54);

// (moved to ios_messages/create_class_page.dart)

// (moved to ios_messages/create_class_wizard_widgets.dart)
