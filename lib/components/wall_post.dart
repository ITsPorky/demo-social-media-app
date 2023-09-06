import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo_social_media_app/components/comment.dart';
import 'package:demo_social_media_app/components/comment_button.dart';
import 'package:demo_social_media_app/components/like_button.dart';
import 'package:demo_social_media_app/helper/helper_methods.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WallPost extends StatefulWidget {
  final String message;
  final String user;
  final String time;
  final String postID;
  final List<String> likes;
  // final List<String> comments;
  const WallPost({
    super.key,
    required this.message,
    required this.user,
    required this.time,
    required this.postID,
    required this.likes,
    // required this.comments,
  });

  @override
  State<WallPost> createState() => _WallPostState();
}

class _WallPostState extends State<WallPost> {
  // User
  final currentuser = FirebaseAuth.instance.currentUser!;
  bool isLiked = false;

  // Comment text controller
  final _commentTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    isLiked = widget.likes.contains(currentuser.email);
  }

  // Toggle like button
  void toggleLike() {
    setState(() {
      isLiked = !isLiked;
    });

    // Access the document in Firebase
    DocumentReference postRef =
        FirebaseFirestore.instance.collection('User Posts').doc(widget.postID);

    if (isLiked) {
      // If the post is now liked, add the user's email to the 'Likes' field
      postRef.update({
        'Likes': FieldValue.arrayUnion([currentuser.email]),
      });
    } else {
      // If the post is now unliked, remove the user's email form the 'Likes' field
      postRef.update({
        'Likes': FieldValue.arrayRemove([currentuser.email]),
      });
    }
  }

  // Add comment
  void addComment(String commentText) {
    // Write the comment to firestore under the comments collection for this post
    FirebaseFirestore.instance
        .collection("User Posts")
        .doc(widget.postID)
        .collection("Comments")
        .add({
      "CommentText": commentText,
      "CommentedBy": currentuser.email,
      "CommentTime": Timestamp.now(), // remember to format this
    });
  }

  // Show a dialogue to allow for adding comment
  void showCommentDialogue() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Comment"),
        content: TextField(
          controller: _commentTextController,
          decoration: InputDecoration(hintText: "Write a comment..."),
        ),
        actions: [
          // Cancel button
          TextButton(
            onPressed: () {
              // Pop dialogue
              Navigator.pop(context);

              // Clear controller
              _commentTextController.clear();
            },
            child: Text("Cancel"),
          ),
          // Post button
          TextButton(
            onPressed: () {
              // Add comment
              addComment(_commentTextController.text);

              // Pop dialogue
              Navigator.pop(context);

              // Clear controller
              _commentTextController.clear();
            },
            child: Text("Post"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      margin: const EdgeInsets.only(top: 25, left: 25, right: 25),
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Message and user email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.user,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        const Text(" - "),
                        Text(
                          widget.time,
                          style: TextStyle(),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.message,
                    ),
                  ],
                ),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Like Button
              Column(
                children: [
                  LikeButton(
                    isLiked: isLiked,
                    onTap: toggleLike,
                  ),
                  const SizedBox(height: 5),
                  Text(widget.likes.length.toString(),
                      style: TextStyle(
                        color: Colors.grey[400],
                      )),
                ],
              ),
              const SizedBox(width: 10),
              // Comment Button
              Column(
                children: [
                  // Comment Button
                  CommentButton(onTap: showCommentDialogue),
                  const SizedBox(height: 5),
                  // Comment Text
                  Text(
                    '0',
                    style: const TextStyle(color: Colors.grey),
                  )
                ],
              )
            ],
          ),
          const SizedBox(height: 10),

          // Comments
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("User Posts")
                .doc(widget.postID)
                .collection("Comments")
                .orderBy("CommentTime", descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              // Show loading circle if no data
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              return ListView(
                shrinkWrap: true, // for nested lists
                physics: const NeverScrollableScrollPhysics(),
                children: snapshot.data!.docs.map((doc) {
                  // get comment from firebase
                  final commentData = doc.data() as Map<String, dynamic>;
                  // return the comment
                  return Comment(
                    text: commentData["CommentText"],
                    user: commentData["CommentedBy"],
                    time: formatDate(commentData["CommentTime"]),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
