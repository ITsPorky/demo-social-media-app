import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo_social_media_app/components/drawer.dart';
import 'package:demo_social_media_app/components/text_field.dart';
import 'package:demo_social_media_app/components/wall_post.dart';
import 'package:demo_social_media_app/pages/profile_page.dart';
import 'package:demo_social_media_app/helper/helper_methods.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // User
  final currentUser = FirebaseAuth.instance.currentUser!;

  // Text controller
  final textController = TextEditingController();

  // Sign user out
  void signOut() {
    FirebaseAuth.instance.signOut();
  }

  // Post message
  void postMessage() {
    // Only post if there is something in the text field
    if (textController.text.isNotEmpty) {
      // Store in firebase
      FirebaseFirestore.instance.collection("User Posts").add({
        'UserEmail': currentUser.email,
        'Message': textController.text,
        'TimeStamp': Timestamp.now(),
        'Likes': [],
      });
    }

    // Clear text field after post
    setState(() {
      textController.clear();
    });
  }

  // Navigate to profile page
  void goToProfilePage() {
    // Pop menu drawer
    Navigator.pop(context);

    // Go to profile page
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfilePage(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text(
          "The Wall",
        ),
        centerTitle: true,
        backgroundColor: Colors.grey[900],
      ),
      endDrawer: MyDrawer(
        onProfile: goToProfilePage,
        onSignOut: signOut,
      ),
      body: Center(
        child: Column(children: [
          // The Wall
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("User Posts")
                  .orderBy(
                    "TimeStamp",
                    descending: false,
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      // Get the message
                      final post = snapshot.data!.docs[index];
                      return WallPost(
                        message: post['Message'],
                        user: post['UserEmail'],
                        time: formatDate(post['TimeStamp']),
                        postID: post.id,
                        likes: List<String>.from(post['Likes'] ?? []),
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            ),
          ),

          // Post message
          Padding(
            padding: const EdgeInsets.all(25.0),
            child: Row(
              children: [
                Expanded(
                  child: MyTextField(
                      controller: textController,
                      hintText: "Write something on the wall!",
                      obscureText: false),
                ),

                // Post Button
                IconButton(
                  onPressed: postMessage,
                  icon: const Icon(Icons.post_add_rounded),
                ),
              ],
            ),
          ),

          // Logged in as
          Text(
            'Logged in as: ${currentUser.email!}',
            style: TextStyle(color: Colors.grey[500]),
          ),

          const SizedBox(
            height: 15.0,
          )
        ]),
      ),
    );
  }
}
