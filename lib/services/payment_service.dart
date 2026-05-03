import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:asifiwe/models/payment_model.dart';
import 'package:flutter/material.dart'; // Added for context
import 'package:flutterwave_standard/flutterwave.dart'; // Added for money movement
import 'package:uuid/uuid.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // LIVE or TEST Public Key
  final String flutterwavePublicKey = "FLWPUBK_TEST_YOUR_KEY_HERE";

  // --- NEW METHOD: MOVE THE MONEY ---
  Future<void> processLivePayment({
    required BuildContext context,
    required PaymentModel payment,
    required String email,
    required String phoneNumber,
  }) async {
    final String transactionRef = "ASIFIWE-${const Uuid().v4()}";

    final Customer customer = Customer(
      name: "Sunday G", // Replace with real data from your AuthProvider
      phoneNumber: phoneNumber,
      email: email,
    );

    final Flutterwave flutterwave = Flutterwave(
      publicKey: flutterwavePublicKey,
      currency: "UGX",
      redirectUrl: "https://asifiwe-tenant.web.app/callback",
      txRef: transactionRef,
      amount: payment.amount.toString(),
      customer: customer,
      paymentOptions: "card, mobilemoneyuganda", // Supports the UI in image_4fe9f8.png
      customization: Customization(
        title: "Asifiwe Rent Payment",
        description: "Payment for Unit ${payment.propertyId}",
      ),
      isTestMode: true, // Switch to false for real payments
    );

    try {
      final ChargeResponse response = await flutterwave.charge(context);
      if (response.status == "success") {
        // --- CALL YOUR EXISTING FIRESTORE METHOD ---
        // If money movement is successful, update the database record
        await updatePaymentStatus(payment.id, PaymentStatus.paid);
        print("Success: Database updated.");
      }
    } catch (e) {
      print("Payment Error: $e");
    }
  }

  Future<String?> createPayment(PaymentModel payment) async {
    try {
      final doc = await _firestore.collection('payments').add(payment.toMap());
      return doc.id;
    } catch (e) {
      print('Error creating payment: $e');
      return null;
    }
  }

  Stream<List<PaymentModel>> getPaymentsByTenant(String tenantId) {
    return _firestore.collection('payments').where('tenantId', isEqualTo: tenantId).snapshots().map(
      (snapshot) {
        final list = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return PaymentModel.fromMap(data);
        }).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      },
    );
  }

  // ... (Keep getPaymentsByLandlord, getPaymentStats, etc. exactly as they are)

  Future<bool> updatePaymentStatus(String paymentId, PaymentStatus status) async {
    try {
      await _firestore.collection('payments').doc(paymentId).update({
        'status': status.toString().split('.').last,
        'paidDate': status == PaymentStatus.paid ? FieldValue.serverTimestamp() : null,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Stream<List<PaymentModel>> getPaymentsByLandlord(String landlordId) {
    return _firestore
        .collection('payments')
        .where('landlordId', isEqualTo: landlordId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return PaymentModel.fromMap(data);
          }).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<Map<String, dynamic>> getPaymentStats(String landlordId) async {
    final snapshot = await _firestore
        .collection('payments')
        .where('landlordId', isEqualTo: landlordId)
        .get();
    int paid = 0;
    int pending = 0;
    int overdue = 0;
    double totalCollected = 0.0;
    double totalPending = 0.0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final status = PaymentStatus.values.firstWhere((e) => e.name == data['status']);
      final amount = (data['amount'] as num).toDouble();
      if (status == PaymentStatus.paid) {
        paid++;
        totalCollected += amount;
      } else if (status == PaymentStatus.pending) {
        pending++;
        totalPending += amount;
      } else if (status == PaymentStatus.overdue) {
        overdue++;
        totalPending += amount;
      }
    }
    return {
      'paid': paid,
      'pending': pending,
      'overdue': overdue,
      'totalCollected': totalCollected,
      'totalPending': totalPending,
    };
  }

  Stream<List<PaymentModel>> getRecentPayments(String landlordId, {int limit = 10}) {
    return _firestore
        .collection('payments')
        .where('landlordId', isEqualTo: landlordId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return PaymentModel.fromMap(data);
          }).toList();
        });
  }
}
