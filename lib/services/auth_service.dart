import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // REGISTER USER
  Future registerUser({
    required String name,
    required String email,
    required String password,
  }) async {

    UserCredential userCredential =
        await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    String uid = userCredential.user!.uid;

    await _firestore.collection("users").doc(uid).set({
      "name": name,
      "email": email,
      "role": "citizen",
      "created_at": Timestamp.now(),
    });
  }

  // LOGIN USER
  Future loginUser({
    required String email,
    required String password,
  }) async {

    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // LOGOUT
  Future logout() async {
    await _auth.signOut();
  }
}