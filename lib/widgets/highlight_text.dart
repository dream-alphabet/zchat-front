import 'package:flutter/material.dart';

// 高亮范围模型（左闭右开）
class HighlightRange {
  final int start;
  final int end;

  HighlightRange(this.start, this.end);

  @override
  String toString() => '[$start, $end)';
}

// 高亮文本组件
class HighlightText extends StatelessWidget {
  // 原始文本
  final String text;
  // 高亮范围
  final List<HighlightRange> ranges;
  // 非高亮样式
  final TextStyle normalStyle;
  // 高亮样式
  final TextStyle highlightStyle;
  // 最大行数
  final int? maxLines;
  // 溢出处理
  final TextOverflow overflow;

  const HighlightText({
    super.key,
    required this.text,
    this.ranges = const [],
    required this.normalStyle,
    required this.highlightStyle,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  @override
  Widget build(BuildContext context) {
    // 没有高亮范围，直接返回全部正常样式文本
    if (ranges.isEmpty) {
      return Text(text, style: normalStyle, maxLines: maxLines, overflow: overflow);
    }
    // 给范围数组排序
    final sorted = List<HighlightRange>.from(ranges)
      ..sort((a, b) => a.start.compareTo(b.start));
    // 开始拼接文本
    final List<TextSpan> spans = [];
    int currentPos = 0;
    for (final range in sorted) {
      // 普通文本
      if (range.start > currentPos) {
        spans.add(
          TextSpan(
            text: text.substring(currentPos, range.start),
            style: normalStyle,
          ),
        );
      }
      // 高亮文本
      spans.add(TextSpan(
        text: text.substring(range.start, range.end),
        style: highlightStyle
      ));
      currentPos = range.end;
    }
    // 剩余普通文本
    if (currentPos < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentPos),
        style: normalStyle,
      ));
    }
    return RichText(
      text: TextSpan(
        style: normalStyle,
        children: spans,
      ),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

// 高亮计算工具类
class HighlightHelper {
  // 空白分隔正则(static final避免每次调用重新编译)
  static final _whitespaceRegExp = RegExp(r'\s+');

  // 计算高亮区间
  // [text] 原始文本
  // [keyword] 搜索关键词（支持空格分隔多个词）
  // 返回 List[HighlightRange]，已合并重叠区间
  static List<HighlightRange> computeHighlightRanges(String text, String keyword) {
    if (keyword.isEmpty || text.isEmpty) return [];

    final lowerText = text.toLowerCase();
    final lowerKeyword = keyword.toLowerCase();

    // 1. 尝试精确匹配（支持多关键词空格分隔）
    final List<HighlightRange> exactRanges = _findExactMatches(lowerText, lowerKeyword);
    if (exactRanges.isNotEmpty) {
      return _mergeRanges(exactRanges);
    }

    // 2. 精确匹配失败，使用最长公共子串（容错）
    final best = _findLongestCommonSubstring(lowerText, lowerKeyword);
    if (best != null) {
      return [best];
    }

    return [];
  }

  // 精确匹配：用空格分割关键词，分别在文本中查找
  static List<HighlightRange> _findExactMatches(String text, String keyword) {
    final ranges = <HighlightRange>[];
    final keywords = keyword.split(_whitespaceRegExp).where((k) => k.isNotEmpty).toList();
    for (final kw in keywords) {
      int start = 0;
      while (true) {
        final index = text.indexOf(kw, start);
        if (index == -1) break;
        ranges.add(HighlightRange(index, index + kw.length));
        start = index + kw.length;
      }
    }
    ranges.sort((a, b) => a.start.compareTo(b.start));
    return ranges;
  }

  // 最长公共子串（滑动窗口）
  static HighlightRange? _findLongestCommonSubstring(String text, String keyword) {
    int maxLen = 0;
    int bestStart = -1;

    for (int i = 0; i < text.length; i++) {
      for (int j = i + 1; j <= text.length; j++) {
        final sub = text.substring(i, j);
        if (sub.length <= maxLen) continue;
        if (keyword.contains(sub)) {
          maxLen = sub.length;
          bestStart = i;
        }
      }
    }
    if (bestStart != -1) {
      return HighlightRange(bestStart, bestStart + maxLen);
    }
    return null;
  }

  // 合并重叠/相邻区间
  static List<HighlightRange> _mergeRanges(List<HighlightRange> ranges) {
    if (ranges.length <= 1) return ranges;
    final merged = <HighlightRange>[];
    var current = ranges[0];
    for (int i = 1; i < ranges.length; i++) {
      final next = ranges[i];
      if (next.start <= current.end) {
        // 合并
        current = HighlightRange(current.start, current.end > next.end ? current.end : next.end);
      } else {
        merged.add(current);
        current = next;
      }
    }
    merged.add(current);
    return merged;
  }
}
