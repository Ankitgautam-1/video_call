import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseUtils {
  static Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleSignInAccount =
          await GoogleSignIn().signIn();
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount!.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );
      log('credential: ${credential}');

      final user = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      return user.user;
    } catch (e) {
      log("error login $e ");
      return null;
    }
  }

  static Future<void> createRoom(String title) async {
    try {
      await FirebaseFirestore.instance
          .collection('live')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .set(
        {
          'username': FirebaseAuth.instance.currentUser!.displayName,
          'userProfile': FirebaseAuth.instance.currentUser != null
              ? FirebaseAuth.instance.currentUser?.photoURL
              : '',
          'title': title,
          'timestamp': Timestamp.now(),
          'liveCount': 0,
          'isActive': true,
        },
      );
    } catch (_) {
      print('Error : $_');
    }
  }

  static Future<void> addEvent(
    String roomId,
    String messege,
    String username,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('live')
          .doc(roomId)
          .collection('events')
          .add(
        {
          'username': username,
          'messege': messege,
          'timestamp': Timestamp.now(),
        },
      );
    } catch (_) {}
  }

  static Future<void> deleteRoom(String roomId) async {
    final data = (await FirebaseFirestore.instance
        .collection('live')
        .doc(roomId)
        .collection('events')
        .get());
    for (var element in data.docs) {
      FirebaseFirestore.instance
          .collection('live')
          .doc(roomId)
          .collection('events')
          .doc(element.id)
          .delete();
    }

    FirebaseFirestore.instance.collection('live').doc(roomId).delete();
  }

  static Future<void> addUserToStream(String roomId) async {
    final data =
        (await FirebaseFirestore.instance.collection('live').doc(roomId).get())
            .get('liveCount');

    await FirebaseFirestore.instance.collection('live').doc(roomId).update(
      {
        'liveCount': data + 1,
      },
    );
  }

  static Future<void> removeUserToStream(String roomId) async {
    final data =
        (await FirebaseFirestore.instance.collection('live').doc(roomId).get())
            .get('liveCount');
    if (data > 0) {
      await FirebaseFirestore.instance.collection('live').doc(roomId).update(
        {
          'liveCount': data - 1,
        },
      );
    }
  }
}
