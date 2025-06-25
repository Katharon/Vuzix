import 'package:flutter_vuzix/models/StepCondition.dart';
import 'package:flutter_vuzix/models/VideoMedia.dart';
import 'package:xml/xml.dart';
import '../models/Workflow.dart';
import '../models/WorkflowStep.dart';
import '../models/MediaType.dart';
import '../models/TextMedia.dart';
import '../models/ImageMedia.dart';
import 'XmlManager.dart';

class ConfigParser {
  final XmlManager _xml;
  final String language;

  ConfigParser(this._xml, {required this.language});

  /// [assetPath] z. B.  'assets/config/workflows.xml'
  Future<List<Workflow>> parse(String assetPath) async {
    final xmlString = await _xml.read(assetPath);
    final doc = XmlDocument.parse(xmlString);
    final List<Workflow> result = [];

    for (final wf in doc.findAllElements('workflow')) {
      final names = _parseLocalizedMap(wf.findElements('name').first);
      final steps = _parseSteps(wf.findElements('steps').first);
      // Wir nehmen einfach die erste Sprache als 'workflow.language'
      final langs = wf
          .findAllElements('supportedlanguages')
          .expand((e) => e.findElements('lang'))
          .map((e) => e.text.trim())
          .toList();

      result.add(Workflow(
          names: names, languages: langs, steps: steps, sourceFile: assetPath));
    }
    return result;
  }

  /* ---------- private helpers ---------- */

  List<WorkflowStep> _parseSteps(XmlElement stepsNode) {
    final List<WorkflowStep> list = [];
    for (final stepNode in stepsNode.findElements('step')) {
      final id = _toInt(stepNode.getAttribute('id'));
      final title = _localisedText(stepNode.findElements('title').first);
      final media = _parseMedia(stepNode.findElements('media').first);
      final nextData = _parseNext(stepNode.findElements('next').first);

      list.add(
        WorkflowStep(
          stepId: id,
          title: title,
          media: media,
          nextConditions: nextData,
        ),
      );
    }
    return list;
  }

  List<StepCondition> _parseNext(XmlElement nextNode) {
    final List<StepCondition> out = [];

    // Fall 1: <next>step_3</next>
    if (nextNode.children.whereType<XmlElement>().isEmpty) {
      out.add(
        StepCondition(condition: null, nextStepId: _toInt(nextNode.text)),
      );
      return out;
    }

    // Fall 2: Bedingungen
    for (final cond in nextNode.findElements('condition')) {
      // Language-agnostisch: nimm <value> des ersten Unterknotens
      final valueEl = cond.findAllElements('value').first;
      final target = _toInt(valueEl.text);

      // Beschreibung aus dem ersten Child-Attribut "cond"
      final langNode = cond.findElements(language).firstOrNull;
      final condAttr = langNode?.getAttribute('cond') ??
          cond.children.whereType<XmlElement>().first.getAttribute('cond') ?? '';

      out.add(
        StepCondition(
          condition: condAttr,
          nextStepId: target,
        ),
      );
    }
    return out;
  }

  MediaType _parseMedia(XmlElement mediaNode) {
    if (mediaNode.findElements('text').isNotEmpty) {
      final txt = _localisedText(mediaNode.findElements('text').first);
      return TextMedia(text: txt);
    }
    if (mediaNode.findElements('image').isNotEmpty) {
      final path = _localisedText(mediaNode.findElements('image').first);
      return ImageMedia(assetPath: path);
    }
    if (mediaNode.findElements('video').isNotEmpty) {
      final path = _localisedText(mediaNode.findElements('video').first);
      return VideoMedia(assetPath: path);
    }
    // VideoMedia & Co. könnt ihr später nachrüsten
    throw UnsupportedError('Unsupported <media> type in XML.');
  }

  /* ---------- get Name ---------- */
  /// Wandelt <de>…</de><en>…</en> in  { 'de': '…', 'en': '…' }
  Map<String, String> _parseLocalizedMap(XmlElement parent) {
    final Map<String, String> map = {};
    for (final tag in parent.children.whereType<XmlElement>()) {
      final langCode = tag.name.local.trim(); // z. B. 'de'
      map[langCode] = tag.text.trim();
    }
    return map;
  }

  /* ---------- mini utils ---------- */

  /// Holt für jetzt einfach den deutschen Text oder fallback auf erste Sprache.
  String _localisedText(XmlElement parent) {
    final langNode = parent.findElements(language).firstOrNull;
    if (langNode != null) return langNode.text.trim();

    // Sonst versuche das erste Kind-Element
    final firstChild = parent.children.whereType<XmlElement>().firstOrNull;
    if (firstChild != null) return firstChild.text.trim();

    // Wenn gar nichts gefunden wurde
    return '';
  }

  int _toInt(String? raw) =>
      int.tryParse((raw ?? '').replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
}

/* ---------- dart 3.9 'firstOrNull' helper ---------- */

extension _IterableX<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
