import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Semantic Material Symbols glyphs shared by reusable Chewie components.
///
/// Names describe meaning instead of visual variants. Persistent selected
/// states keep the same glyph and express emphasis through color, a container
/// or the shared component's fill axis; action pairs may use different glyphs
/// when their meaning changes.
abstract final class ChewieIcons {
  static const IconData back = Symbols.arrow_back_rounded;
  static const IconData previous = Symbols.chevron_left_rounded;
  static const IconData next = Symbols.chevron_right_rounded;
  static const IconData expand = Symbols.expand_more_rounded;
  static const IconData collapse = Symbols.expand_less_rounded;
  static const IconData arrowUp = Symbols.arrow_upward_rounded;
  static const IconData arrowDown = Symbols.arrow_downward_rounded;
  static const IconData arrowLeft = Symbols.arrow_back_rounded;
  static const IconData arrowRight = Symbols.arrow_forward_rounded;

  static const IconData add = Symbols.add_rounded;
  static const IconData remove = Symbols.remove_rounded;
  static const IconData close = Symbols.close_rounded;
  static const IconData check = Symbols.check_rounded;
  static const IconData copy = Symbols.content_copy_rounded;
  static const IconData copyDone = Symbols.task_alt_rounded;
  static const IconData more = Symbols.more_vert_rounded;
  static const IconData refresh = Symbols.refresh_rounded;
  static const IconData retry = Symbols.restart_alt_rounded;
  static const IconData search = Symbols.search_rounded;
  static const IconData searchOff = Symbols.search_off_rounded;
  static const IconData share = Symbols.share_rounded;
  static const IconData openExternal = Symbols.open_in_new_rounded;
  static const IconData link = Symbols.link_rounded;

  static const IconData info = Symbols.info_rounded;
  static const IconData success = Symbols.check_circle_rounded;
  static const IconData warning = Symbols.warning_rounded;
  static const IconData error = Symbols.cancel_rounded;
  static const IconData cloudAlert = Symbols.cloud_alert_rounded;
  static const IconData imageUnavailable = Symbols.broken_image_rounded;
  static const IconData inbox = Symbols.inbox_rounded;
  static const IconData archive = Symbols.archive_rounded;
  static const IconData star = Symbols.star_rounded;
  static const IconData starHalf = Symbols.star_half_rounded;

  static const IconData pin = Symbols.push_pin_rounded;
  static const IconData minimizeWindow = Symbols.remove_rounded;
  static const IconData maximizeWindow = Symbols.crop_square_rounded;
  static const IconData restoreWindow = Symbols.filter_none_rounded;
  static const IconData closeWindow = Symbols.close_rounded;
  static const IconData square = Symbols.crop_square_rounded;
  static const IconData alarm = Symbols.alarm_rounded;
  static const IconData time = Symbols.schedule_rounded;

  // Glyphs consumed directly by Chewie components, routed through this
  // semantic layer so component code never touches an icon font directly.
  static const IconData home = Symbols.home_rounded;
  static const IconData hash = Symbols.tag_rounded;
  static const IconData globe = Symbols.language_rounded;
  static const IconData textCursorInput = Symbols.input_rounded;
  static const IconData download = Symbols.download_rounded;
  static const IconData trash = Symbols.delete_rounded;
  static const IconData eye = Symbols.visibility_rounded;
  static const IconData eyeOff = Symbols.visibility_off_rounded;
  static const IconData save = Symbols.save_rounded;
}
