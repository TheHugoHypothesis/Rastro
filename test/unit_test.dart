import 'package:flutter_test/flutter_test.dart';
import 'package:rastro/domain/models/partner_establishment.dart';
import 'package:rastro/core/services/crypto_identity_service.dart';

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
}
