// 크립토 코어 의존성 주입 — KeyService(마스터키 캐시) + QuoteCipher(AES-GCM 본문 암복호).
//
// QuoteRepository·QuoteOutbox·envelope_repository가 모두 이 두 인스턴스를 공유.
// flutter_secure_storage는 native handle 하나면 충분해서 앱 1 인스턴스.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/key_service.dart';
import '../data/quote_cipher.dart';

final keyServiceProvider = Provider<KeyService>((ref) => KeyService());

final quoteCipherProvider = Provider<QuoteCipher>((ref) => QuoteCipher());
