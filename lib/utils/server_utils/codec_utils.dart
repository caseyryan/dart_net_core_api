import 'dart:convert';
import 'dart:io';

class CodecUtils {
  CodecUtils._() {
    add(
      ContentType(
        "application",
        "json",
        charset: "utf-8",
      ),
      const JsonCodec(),
    );
    add(
      ContentType(
        "application",
        "x-www-form-urlencoded",
        charset: "utf-8",
      ),
      const _FormCodec(),
    );
    setAllowsCompression(
      ContentType("text", "*"),
      true,
    );
    setAllowsCompression(
      ContentType(
        "application",
        "javascript",
      ),
      true,
    );
    setAllowsCompression(
      ContentType(
        "text",
        "event-stream",
      ),
      false,
    );
  }

  static CodecUtils get instance {
    return _instance;
  }

  static final CodecUtils _instance = CodecUtils._();

  final Map<String, Codec> _primaryTypeCodecs = {};
  final Map<String, Map<String, Codec>> _fullySpecifiedCodecs = {};
  final Map<String, bool> _primaryTypeCompressionMap = {};
  final Map<String, Map<String, bool>> _fullySpecifiedCompressionMap = {};
  final Map<String, Map<String, String?>> _defaultCharsetMap = {};

  void add(
    ContentType contentType,
    Codec codec, {
    bool allowCompression = true,
  }) {
    if (contentType.subType == "*") {
      _primaryTypeCodecs[contentType.primaryType] = codec;
      _primaryTypeCompressionMap[contentType.primaryType] = allowCompression;
    } else {
      final innerCodecs = _fullySpecifiedCodecs[contentType.primaryType] ?? {};
      innerCodecs[contentType.subType] = codec;
      _fullySpecifiedCodecs[contentType.primaryType] = innerCodecs;

      final innerCompress = _fullySpecifiedCompressionMap[contentType.primaryType] ?? {};
      innerCompress[contentType.subType] = allowCompression;
      _fullySpecifiedCompressionMap[contentType.primaryType] = innerCompress;
    }

    if (contentType.charset != null) {
      final innerCodecs = _defaultCharsetMap[contentType.primaryType] ?? {};
      innerCodecs[contentType.subType] = contentType.charset;
      _defaultCharsetMap[contentType.primaryType] = innerCodecs;
    }
  }

  void setAllowsCompression(
    ContentType contentType,
    bool isAllowed,
  ) {
    if (contentType.subType == "*") {
      _primaryTypeCompressionMap[contentType.primaryType] = isAllowed;
    } else {
      final innerCompress = _fullySpecifiedCompressionMap[contentType.primaryType] ?? {};
      innerCompress[contentType.subType] = isAllowed;
      _fullySpecifiedCompressionMap[contentType.primaryType] = innerCompress;
    }
  }

  bool isContentTypeCompressible(
    ContentType? contentType,
  ) {
    final subtypeCompress = _fullySpecifiedCompressionMap[contentType?.primaryType];
    if (subtypeCompress != null) {
      if (subtypeCompress.containsKey(contentType?.subType)) {
        return subtypeCompress[contentType?.subType] ?? false;
      }
    }

    return _primaryTypeCompressionMap[contentType?.primaryType] ?? false;
  }

  Codec<dynamic, List<int>>? codecForContentType(
    ContentType? contentType,
  ) {
    if (contentType == null) {
      return null;
    }

    Codec? contentCodec;
    Codec<String, List<int>>? charsetCodec;

    final subtypes = _fullySpecifiedCodecs[contentType.primaryType];
    if (subtypes != null) {
      contentCodec = subtypes[contentType.subType];
    }

    contentCodec ??= _primaryTypeCodecs[contentType.primaryType];

    if ((contentType.charset?.length ?? 0) > 0) {
      charsetCodec = _codecForCharset(contentType.charset);
    } else if (contentType.primaryType == 'text' && contentCodec == null) {
      charsetCodec = latin1;
    } else {
      charsetCodec = _defaultCharsetCodecForType(contentType);
    }

    if (contentCodec != null) {
      if (charsetCodec != null) {
        return contentCodec.fuse(charsetCodec);
      }
      if (contentCodec is! Codec<dynamic, List<int>>) {
        throw 'Invalid codec selected. Does not emit List<int>.';
      }
      return contentCodec;
    }

    if (charsetCodec != null) {
      return charsetCodec;
    }

    return null;
  }

  Codec<String, List<int>> _codecForCharset(String? charset) {
    final encoding = Encoding.getByName(charset);
    if (encoding == null) {
      throw 'invalid charset "$charset"';
    }

    return encoding;
  }

  Codec<String, List<int>>? _defaultCharsetCodecForType(ContentType type) {
    final inner = _defaultCharsetMap[type.primaryType];
    if (inner == null) {
      return null;
    }

    final encodingName = inner[type.subType] ?? inner["*"];
    if (encodingName == null) {
      return null;
    }

    return Encoding.getByName(encodingName);
  }
}

class _FormCodec extends Codec<Map<String, dynamic>?, dynamic> {
  const _FormCodec();

  @override
  Converter<Map<String, dynamic>, String> get encoder {
    return const _FormEncoder();
  }

  @override
  Converter<String, Map<String, dynamic>> get decoder {
    return const _FormDecoder();
  }
}

class _FormEncoder extends Converter<Map<String, dynamic>, String> {
  const _FormEncoder();

  @override
  String convert(Map<String, dynamic> data) {
    return data.keys.map((k) => _encodePair(k, data[k])).join("&");
  }

  String _encodePair(String key, dynamic value) {
    String encode(String v) => '$key=${Uri.encodeQueryComponent(v)}';
    if (value is List<String>) {
      return value.map(encode).join("&");
    } else if (value is String) {
      return encode(value);
    }

    throw ArgumentError(
      "Cannot encode value '$value' for key '$key'. Must be 'String' or 'List<String>'",
    );
  }
}

class _FormDecoder extends Converter<String, Map<String, dynamic>> {
  const _FormDecoder();

  @override
  Map<String, dynamic> convert(String data) {
    return Uri(query: data).queryParametersAll;
  }

  @override
  _FormSink startChunkedConversion(Sink<Map<String, dynamic>> outSink) {
    return _FormSink(outSink);
  }
}

class _FormSink extends ChunkedConversionSink<String> {
  _FormSink(this._outSink);

  final _FormDecoder decoder = const _FormDecoder();
  final Sink<Map<String, dynamic>> _outSink;
  final StringBuffer _buffer = StringBuffer();

  @override
  void add(String data) {
    _buffer.write(data);
  }

  @override
  void close() {
    _outSink.add(decoder.convert(_buffer.toString()));
    _outSink.close();
  }
}
