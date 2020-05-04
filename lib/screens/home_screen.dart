import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:task_app/config/config.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _taskController = TextEditingController();

  final Firestore _db = Firestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseUser user;

  @override
  void initState() {
    getUid();
    super.initState();
  }

  void getUid() async {
    FirebaseUser u = await _auth.currentUser();
    setState(() {
      user = u;
    });
  }

  void _showAddTaskDialog() {
    showDialog(
        context: context,
        builder: (ctx) {
          return SimpleDialog(
            title: Text('Add Task'),
            children: [
              Container(
                margin: EdgeInsets.all(10),
                child: TextField(
                  controller: _taskController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Write your task",
                    labelText: "Task Name",
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.all(10),
                child: Row(
                  children: [
                    FlatButton(
                      child: Text('Cancel'),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                      },
                    ),
                    RaisedButton(
                      color: primaryColor,
                      child: Text('Add'),
                      onPressed: () async {
                        String task = _taskController.text.trim();

                        _db
                            .collection("users")
                            .document(user.uid)
                            .collection('tasks')
                            .add({
                          "task": task,
                          "date": DateTime.now(),
                        });
                        _taskController.text = '';

                        Navigator.of(ctx).pop();
                      },
                    ),
                  ],
                ),
              )
            ],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: Icon(
          Icons.add,
          color: secondaryColor,
        ),
        elevation: 4,
        backgroundColor: primaryColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.person_outline),
              onPressed: () {
                _auth.signOut();
              },
            )
          ],
        ),
      ),
      body: Container(
          child: StreamBuilder(
        stream: _db
            .collection("users")
            .document(user.uid)
            .collection('tasks')
            .orderBy("date", descending: true)
            .snapshots(),
        builder: (ctx, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.documents.isNotEmpty) {
              return ListView(
                children: snapshot.data.documents.map((snap) {
                  return ListTile(
                    title: Text(snap.data['task']),
                    onTap: () {},
                    leading: Radio(
                      value: true,
                      groupValue: true,
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      onPressed: () async {
                        await _db
                            .document(
                                'users/${user.uid}/tasks/${snap.documentID}')
                            .delete();
                      },
                    ),
                  );
                }).toList(),
              );
            } else {
              return Container(
                child: Center(
                  child: Image(
                    image: AssetImage("assets/no_task.png"),
                  ),
                ),
              );
            }
          }
        },
      )),
    );
  }
}
