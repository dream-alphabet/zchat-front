import 'package:flutter/material.dart';

// emoji表情列表
final emojiList = [
  '😄',
  '😁',
  '😆',
  '😅',
  '🤣',
  '😂',
  '🙂',
  '🙃',
  '🫠',
  '😉',
  '😊',
  '😇',
  '🥰',
  '😍',
  '🤩',
  '😘',
  '😗',
  '☺️',
  '😙',
  '🥲',
  '😋',
  '😜',
  '🤪',
  '😝',
  '🤑',
  '🤗',
  '🤭',
  '🤔',
  '🫡',
  '🤐',
  '🤨',
  '😐',
  '😑',
  '🤥',
  '🙂‍↔️',
  '😪',
  '🤤',
  '😴',
  '😷',
  '🤢',
  '🤮',
  '🤧',
  '🥵',
  '🥴',
  '😵',
  '🤯',
  '🤠',
  '🥳',
  '😎',
  '🤓',
  '🧐',
  '😕',
  '😯',
  '😮',
  '😳',
  '😰',
  '😨',
  '😭',
  '😱',
  '🥱',
  '😓',
  '😤',
  '😡',
  '😠',
  '😈',
  '👿',
  '💩',
  '🤡',
  '👺',
  '👻',
  '👽',
  '🤖',
  '😺',
  '🙀',
  '😾',
  '😻',
  '😼',
  '😽',
  '🙈',
  '🙉',
  '🙊',
];

// 检查emoji是否支持，通过对比emoji和普通字符的渲染差异
bool isEmojiSupported(String emoji) {
  final emojiPainter = TextPainter(
    text: TextSpan(text: emoji, style: const TextStyle(fontSize: 50)),
    textDirection: TextDirection.ltr,
  )..layout();

  // 测量一个确定存在的字符（如字母A）
  final letterPainter = TextPainter(
    text: const TextSpan(text: 'A', style: TextStyle(fontSize: 50)),
    textDirection: TextDirection.ltr,
  )..layout();

  // Emoji 通常比字母宽，如果宽度相近可能渲染成了方框
  final emojiWidth = emojiPainter.width;
  final letterWidth = letterPainter.width;

  // Emoji 宽度通常至少是字母的 0.8 倍以上
  // 如果太窄，可能是占位符
  return emojiWidth > letterWidth * 0.8;
}

// 当前平台支持的emoji
final supportEmojiList = emojiList.where((emoji) => isEmojiSupported(emoji)).toList();
