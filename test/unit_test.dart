import 'package:flutter_test/flutter_test.dart';
import 'package:rastro/domain/models/partner_establishment.dart';
import 'package:rastro/domain/models/safety_evaluation.dart';
import 'package:rastro/domain/models/activity_record.dart';
import 'package:rastro/core/services/crypto_identity_service.dart';

/// **main**
///
/// Ponto de entrada principal para a execução da suíte de testes unitários do Rastro.
/// Executa de forma autônoma em linha de comando atendendo aos requisitos RNF010 e RNF011.
void main() {
  group('PartnerEstablishment Model Unit Tests', () {
    test('Should correctly parse from valid JSON map and format back to JSON', () {
      final jsonMap = {
        'id': 'test_partner_99',
        'name': 'Oficina da Bicicleta',
        'latitude': -23.56,
        'longitude': -46.65,
        'isBikeFriendly': true,
        'amenities': ['Bomba de Ar', 'Remendo de Pneu'],
        'adminSignature': 'admin_sig_test_123'
      };

      // 1. Parsing from JSON
      final partner = PartnerEstablishment.fromJson(jsonMap);

      expect(partner.id, 'test_partner_99');
      expect(partner.name, 'Oficina da Bicicleta');
      expect(partner.latitude, -23.56);
      expect(partner.longitude, -46.65);
      expect(partner.isBikeFriendly, true);
      expect(partner.amenities, contains('Bomba de Ar'));
      expect(partner.adminSignature, 'admin_sig_test_123');

      // 2. Converting back to JSON
      final parsedJson = partner.toJson();
      expect(parsedJson['id'], 'test_partner_99');
      expect(parsedJson['name'], 'Oficina da Bicicleta');
      expect(parsedJson['latitude'], -23.56);
      expect(parsedJson['longitude'], -46.65);
      expect(parsedJson['isBikeFriendly'], true);
      expect(parsedJson['amenities'], contains('Remendo de Pneu'));
      expect(parsedJson['adminSignature'], 'admin_sig_test_123');
    });

    test('Should return LatLng point with correct coordinates', () {
      final partner = PartnerEstablishment(
        id: 'p1',
        name: 'Vila Bike',
        latitude: -12.34,
        longitude: 56.78,
        isBikeFriendly: true,
        amenities: [],
        adminSignature: 'sig',
      );

      expect(partner.point.latitude, -12.34);
      expect(partner.point.longitude, 56.78);
    });
  });

  group('CryptoIdentityService Partner Verification Unit Tests', () {
    final crypto = CryptoIdentityService();

    test('Should approve admin signatures starting with admin_sig_', () {
      final isValid = crypto.verifyPartnerSignature('partner_id', 'admin_sig_token_xyz');
      expect(isValid, isTrue);
    });

    test('Should approve admin signatures containing admin', () {
      final isValid = crypto.verifyPartnerSignature('partner_id', 'authorized_admin_key_99');
      expect(isValid, isTrue);
    });

    test('Should reject empty or non-admin signatures', () {
      final isValidEmpty = crypto.verifyPartnerSignature('partner_id', '');
      final isValidUser = crypto.verifyPartnerSignature('partner_id', 'user_signature_key');

      expect(isValidEmpty, isFalse);
      expect(isValidUser, isFalse);
    });
  });

  group('SafetyEvaluation Model Unit Tests', () {
    test('Should correctly parse SafetyEvaluation from valid JSON and format back', () {
      final jsonMap = {
        'segmentId': 'via_reboucas_101',
        'latitude': -23.565,
        'longitude': -46.682,
        'safetyScore': 4,
        'lightingScore': 3,
        'trafficScore': 5,
        'accidentScore': 2,
        'hasCycleway': true,
        'safeTimePeriod': 'dia',
        'timestamp': 1672531199000,
        'creatorPublicKey': 'pubkey_test_123',
        'signature': 'sig_test_456'
      };

      final evaluation = SafetyEvaluation.fromJson(jsonMap);

      expect(evaluation.segmentId, 'via_reboucas_101');
      expect(evaluation.latitude, -23.565);
      expect(evaluation.longitude, -46.682);
      expect(evaluation.safetyScore, 4);
      expect(evaluation.lightingScore, 3);
      expect(evaluation.trafficScore, 5);
      expect(evaluation.accidentScore, 2);
      expect(evaluation.hasCycleway, isTrue);
      expect(evaluation.safeTimePeriod, 'dia');
      expect(evaluation.timestamp, 1672531199000);
      expect(evaluation.creatorPublicKey, 'pubkey_test_123');
      expect(evaluation.signature, 'sig_test_456');

      final backToJson = evaluation.toJson();
      expect(backToJson['segmentId'], 'via_reboucas_101');
      expect(backToJson['latitude'], -23.565);
      expect(backToJson['longitude'], -46.682);
      expect(backToJson['safetyScore'], 4);
      expect(backToJson['lightingScore'], 3);
      expect(backToJson['trafficScore'], 5);
      expect(backToJson['accidentScore'], 2);
      expect(backToJson['hasCycleway'], isTrue);
      expect(backToJson['safeTimePeriod'], 'dia');
      expect(backToJson['timestamp'], 1672531199000);
      expect(backToJson['creatorPublicKey'], 'pubkey_test_123');
      expect(backToJson['signature'], 'sig_test_456');
    });

    test('Should return LatLng point with correct safety coordinates', () {
      final evaluation = SafetyEvaluation(
        segmentId: 'seg_1',
        latitude: -15.79,
        longitude: -47.88,
        safetyScore: 5,
        lightingScore: 5,
        trafficScore: 1,
        accidentScore: 1,
        hasCycleway: true,
        safeTimePeriod: 'sempre',
        timestamp: 1672531199000,
        creatorPublicKey: 'key',
        signature: 'sig',
      );

      expect(evaluation.point.latitude, -15.79);
      expect(evaluation.point.longitude, -47.88);
    });
  });

  group('ActivityRecord Model Unit Tests', () {
    test('Should correctly parse ActivityRecord from valid JSON and format back', () {
      final nowStr = '2026-05-20T03:22:42.000Z';
      final jsonMap = {
        'id': 'activity_99',
        'timestamp': nowStr,
        'distanceMeters': 12500.5,
        'durationSeconds': 1800.0,
        'calories': 450.5
      };

      final record = ActivityRecord.fromJson(jsonMap);

      expect(record.id, 'activity_99');
      expect(record.timestamp, DateTime.parse(nowStr));
      expect(record.distanceMeters, 12500.5);
      expect(record.durationSeconds, 1800.0);
      expect(record.calories, 450.5);

      final backToJson = record.toJson();
      expect(backToJson['id'], 'activity_99');
      expect(backToJson['timestamp'], nowStr);
      expect(backToJson['distanceMeters'], 12500.5);
      expect(backToJson['durationSeconds'], 1800.0);
      expect(backToJson['calories'], 450.5);
    });
  });
}
