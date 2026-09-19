import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Product-level icon semantics. Pages should use these names instead of
/// importing an icon font directly.
///
/// Names describe product meaning, never visual variants such as `filled`,
/// `outlined`, `active` or `selected`. A persistent state keeps the same glyph
/// and is expressed by the shared icon component through its fill axis. A
/// different glyph is only valid when the action itself changes, for example
/// play/pause.
abstract final class LoftifyIcons {
  static const IconData home = Symbols.home_rounded;
  static const IconData search = Symbols.search_rounded;
  static const IconData activity = Symbols.favorite_rounded;
  static const IconData profile = Symbols.person_rounded;
  static const IconData logout = Symbols.logout_rounded;
  static const IconData dress = Symbols.checkroom_rounded;
  static const IconData notifications = Symbols.notifications_rounded;
  static const IconData settings = Symbols.settings_rounded;
  static const IconData flag = Symbols.flag_rounded;
  static const IconData copyright = Symbols.copyright_rounded;
  static const IconData block = Symbols.block_rounded;
  static const IconData tag = Symbols.sell_rounded;
  static const IconData shield = Symbols.shield_rounded;
  static const IconData previous = Symbols.chevron_left_rounded;
  static const IconData next = Symbols.chevron_right_rounded;
  static const IconData previousPost = Symbols.keyboard_double_arrow_left_rounded;
  static const IconData nextPost = Symbols.keyboard_double_arrow_right_rounded;
  static const IconData expand = Symbols.expand_more_rounded;
  static const IconData sortDirection = Symbols.swap_vert_rounded;
  static const IconData favorite = Symbols.favorite_rounded;
  static const IconData recommend = Symbols.thumb_up_rounded;
  static const IconData hot = Symbols.local_fire_department_rounded;
  static const IconData egg = Symbols.egg_rounded;
  static const IconData magic = Symbols.auto_awesome_rounded;
  static const IconData select = Symbols.radio_button_unchecked_rounded;
  static const IconData more = Symbols.more_horiz_rounded;
  static const IconData moreVertical = Symbols.more_vert_rounded;
  static const IconData slide = Symbols.keyboard_double_arrow_right_rounded;
  static const IconData edit = Symbols.edit_rounded;
  static const IconData history = Symbols.history_rounded;
  static const IconData premium = Symbols.workspace_premium_rounded;
  static const IconData shop = Symbols.shopping_bag_rounded;
  static const IconData avatarFrame = Symbols.wall_art_rounded;
  static const IconData copy = Symbols.content_copy_rounded;
  static const IconData follow = Symbols.person_add_rounded;
  static const IconData specialFollow = Symbols.star_rounded;
  static const IconData unfollow = Symbols.person_remove_rounded;
  static const IconData bookmark = Symbols.bookmark_rounded;
  static const IconData comment = Symbols.chat_bubble_rounded;
  static const IconData article = Symbols.article_rounded;
  static const IconData invalidContent = Symbols.error_rounded;
  static const IconData originalPost = Symbols.description_rounded;
  static const IconData quote = Symbols.format_quote_rounded;
  static const IconData reblog = Symbols.repeat_rounded;
  static const IconData collection = Symbols.library_books_rounded;
  static const IconData grain = Symbols.grain_rounded;
  static const IconData filter = Symbols.filter_list_rounded;
  static const IconData listLayout = Symbols.view_list_rounded;
  static const IconData gridLayout = Symbols.grid_view_rounded;
  static const IconData scrollTop = Symbols.arrow_upward_rounded;
  static const IconData trendUp = Symbols.trending_up_rounded;
  static const IconData trendDown = Symbols.trending_down_rounded;

  static const IconData refresh = Symbols.refresh_rounded;
  static const IconData save = Symbols.save_rounded;
  static const IconData add = Symbols.add_rounded;
  static const IconData check = Symbols.check_rounded;
  static const IconData empty = Symbols.inbox_rounded;
  static const IconData error = Symbols.cancel_rounded;
  static const IconData warning = Symbols.warning_rounded;
  static const IconData clear = Symbols.close_rounded;
  static const IconData visible = Symbols.visibility_rounded;
  static const IconData hidden = Symbols.visibility_off_rounded;
  static const IconData reset = Symbols.restart_alt_rounded;
  static const IconData openExternal = Symbols.open_in_new_rounded;

  static const IconData merge = Symbols.merge_type_rounded;
  static const IconData bug = Symbols.bug_report_rounded;
  static const IconData commit = Symbols.commit_rounded;
  static const IconData review = Symbols.reviews_rounded;
  static const IconData share = Symbols.share_rounded;
  static const IconData support = Symbols.help_rounded;
  static const IconData contact = Symbols.alternate_email_rounded;
  static const IconData language = Symbols.language_rounded;
  static const IconData group = Symbols.group_rounded;
  static const IconData send = Symbols.send_rounded;
  static const IconData phone = Symbols.smartphone_rounded;
  static const IconData verification = Symbols.verified_user_rounded;
  static const IconData password = Symbols.key_rounded;
  static const IconData lofterId = Symbols.badge_rounded;
  static const IconData email = Symbols.mail_rounded;

  static const IconData generalSettings = Symbols.tune_rounded;
  static const IconData appearance = Symbols.palette_rounded;
  static const IconData image = Symbols.image_rounded;
  static const IconData basicSettings = settings;
  static const IconData experiment = Symbols.science_rounded;
  static const IconData info = Symbols.info_rounded;
  static const IconData about = info;

  static const IconData download = Symbols.download_rounded;
  static const IconData batchDownload = Symbols.move_to_inbox_rounded;
  static const IconData file = Symbols.insert_drive_file_rounded;
  static const IconData video = Symbols.videocam_rounded;
  static const IconData videoUnavailable = Symbols.videocam_off_rounded;
  static const IconData videoSettings = Symbols.video_settings_rounded;
  static const IconData continuousPlayback = Symbols.playlist_play_rounded;
  static const IconData danmaku = Symbols.closed_caption_rounded;
  static const IconData back = Symbols.arrow_back_rounded;
  static const IconData sound = Symbols.volume_up_rounded;
  static const IconData mute = Symbols.volume_off_rounded;
  static const IconData enterFullscreen = Symbols.open_in_full_rounded;
  static const IconData exitFullscreen = Symbols.close_fullscreen_rounded;
  static const IconData pause = Symbols.pause_rounded;
  static const IconData play = Symbols.play_arrow_rounded;
  static const IconData retry = Symbols.restart_alt_rounded;
  static const IconData close = Symbols.close_rounded;
  static const IconData delete = Symbols.delete_rounded;
}
