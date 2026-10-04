import '../../Models/ao3_work.dart';

/// Bundled sample so the reader can be demoed without network access
/// (`--dart-define=DEMO_MODE=true`), matching how the rest of the app fakes
/// its API responses.
abstract final class Ao3Demo {
  static Ao3Work sample(int workId) => Ao3Work(
        id: workId,
        title: '演示作品 · A Demo Work',
        author: 'demo_author',
        authorUrl: 'https://archiveofourown.org/users/demo_author',
        tagGroups: const [
          Ao3TagGroup(label: 'Rating', values: ['General Audiences']),
          Ao3TagGroup(label: 'Fandom', values: ['Demo Fandom']),
          Ao3TagGroup(label: 'Additional Tags', values: ['Demo', 'Sample']),
        ],
        language: 'English',
        publishedAt: '2026-10-01',
        words: 240,
        chaptersStat: '2/2',
        summaryHtml:
            '<p>这是 DEMO_MODE 下的内置样章，用来在没有网络或代理时验收阅读页。</p>',
        notesHtml: '<p>演示用前言。</p>',
        chapters: const [
          Ao3Chapter(
            index: 1,
            title: '第一章 · The First Chapter',
            notesHtml: '<p>本章前注。</p>',
            bodyHtml: '<p>这是一段演示正文。</p>'
                '<p>章节正文使用与帖子相同的 HTML 渲染器，所以<strong>加粗</strong>、'
                '<em>斜体</em>和<a href="https://archiveofourown.org">链接</a>都会正常显示。</p>',
            endNotesHtml: '<p>本章尾注。</p>',
          ),
          Ao3Chapter(
            index: 2,
            title: '第二章 · The Second Chapter',
            bodyHtml: '<p>第二章的正文，用来验证章节切换与阅读进度记忆。</p>',
          ),
        ],
      );
}
