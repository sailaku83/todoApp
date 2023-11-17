import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'dart:developer';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const keyApplicationId = 'VXQhpMlSVQtWGD3aZ8gopmubRqjAg1gQLYgBYeCa';
  const keyClientKey = 'G6cKhAx3aOPXXBK5WcDCyDGKq6thu5LoaaCQEBS5';
  const keyParseServerUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(keyApplicationId, keyParseServerUrl,
      clientKey: keyClientKey, debug: true);

  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final todoController = TextEditingController();
  final descriptionController = TextEditingController();

  bool isEdit = false;
  String editedId = "";
  String buttonText = "Add Task";
  bool isButtonEnabled = true;
  bool isTextFieldEnabled = true;
  bool isViewPanelEnabled = false;
  DateTime? selectedDate;

  void reset() {
    setState(() {
      todoController.clear();
      descriptionController.clear();
      isEdit = false;
      editedId = "";
      buttonText = "Add Task";
      isButtonEnabled = true;
      isViewPanelEnabled = false;
      selectedDate = null;
    });
  }

  void addToDo() async {
    if (isEdit) {
      var todo = ParseObject('Todo')
        ..objectId = editedId
        ..set('description', descriptionController.text)
        ..set('taskDate', selectedDate?.toLocal())
        ..set('title', todoController.text);
      await todo.save();
      setState(() {
        const snackBar = SnackBar(
          content: Text("Task updated successfully!"),
          duration: Duration(seconds: 1),
        );
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(snackBar);
      });
      setState(() {
        todoController.clear();
        descriptionController.clear();
        isEdit = false;
        editedId = "";
        buttonText = "Add Task";
        isButtonEnabled = true;
        isViewPanelEnabled = false;
        selectedDate = null;
      });
    } else {
      if (todoController.text.trim().isEmpty || selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Empty Task Title/Task Date"),
          duration: Duration(seconds: 2),
        ));
        return;
      }
      await saveTodo(
          todoController.text, descriptionController.text, selectedDate);
      setState(() {
        todoController.clear();
        descriptionController.clear();
        selectedDate = null;
        isViewPanelEnabled = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("My Todo List"),
          backgroundColor: Colors.orangeAccent,
          centerTitle: true,
        ),
        body: Column(
          children: <Widget>[
            Container(
                padding: const EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
                child: Row(
                  children: <Widget>[
                    Visibility(
                        visible: isViewPanelEnabled,
                        child: Expanded(
                            child: TextField(
                          autocorrect: true,
                          textCapitalization: TextCapitalization.sentences,
                          controller: todoController,
                          enabled: isTextFieldEnabled,
                          decoration: const InputDecoration(
                              labelText: "Title",
                              labelStyle: TextStyle(color: Colors.lightGreen)),
                        ))),
                  ],
                )),
            Container(
                padding: const EdgeInsets.fromLTRB(17.0, 20.0, 7.0, 1.0),
                child: Row(
                  children: <Widget>[
                    Visibility(
                        visible: isViewPanelEnabled,
                        child: Expanded(
                          child: TextField(
                              autocorrect: true,
                              keyboardType: TextInputType.multiline,
                              maxLines: 3,
                              textCapitalization: TextCapitalization.sentences,
                              controller: descriptionController,
                              enabled: isTextFieldEnabled,
                              decoration: const InputDecoration(
                                  labelText: "Description",
                                  labelStyle:
                                      TextStyle(color: Colors.lightGreen),
                                  focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          width: 1, color: Colors.brown)))),
                        )),
                  ],
                )),
            Container(
                padding: const EdgeInsets.fromLTRB(17.0, 20.0, 7.0, 1.0),
                child: Row(
                  children: <Widget>[
                    Visibility(
                        visible: isViewPanelEnabled,
                        child: Expanded(
                          child: TextField(
                            readOnly: true,
                            enabled: isTextFieldEnabled,
                            controller: TextEditingController(
                              text: selectedDate != null
                                  ? selectedDate!.toString().split(' ')[0]
                                  : '',
                            ),
                            onTap: () => _selectDate(context),
                            decoration: const InputDecoration(
                              labelText: "Please select task date",
                              labelStyle: TextStyle(color: Colors.lightGreen),
                            ),
                          ),
                        )),
                  ],
                )),
            Container(
                padding: const EdgeInsets.fromLTRB(300.0, 5.0, 1.0, 5.0),
                child: Row(
                  children: <Widget>[
                    Visibility(
                      visible: isButtonEnabled && isViewPanelEnabled,
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.green,
                          ),
                          onPressed: addToDo,
                          child: Text(buttonText)),
                    )
                  ],
                )),
            Expanded(
                child: FutureBuilder<List<ParseObject>>(
                    future: getTodo(),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.none:
                        case ConnectionState.waiting:
                          return Center(
                            child: Container(
                                width: 100,
                                height: 100,
                                child: const CircularProgressIndicator()),
                          );
                        default:
                          if (snapshot.hasError) {
                            return const Center(
                              child: Text("Error..."),
                            );
                          }
                          if (!snapshot.hasData) {
                            return const Center(
                              child: Text("No Data..."),
                            );
                          } else {
                            var tempTaskDate = "";
                            bool isFirstRow = true;
                            return ListView.builder(
                                padding: const EdgeInsets.only(top: 10.0),
                                shrinkWrap: true,
                                itemCount: snapshot.data!.length,
                                itemBuilder: (context, index) {
                                  //*************************************
                                  //Get Parse Object Values
                                  log('data: $index');
                                  final varTodo = snapshot.data![index];
                                  final varTitle =
                                      varTodo.get<String>('title')!;
                                  final varTaskDateUTC =
                                      varTodo.get<DateTime>('taskDate')!;
                                  final DateTime varTaskDate =
                                      varTaskDateUTC.toLocal();
                                  final varDescription =
                                      varTodo.get<String>('description')!;

                                  //*************************************
                                  if (isFirstRow ||
                                      (!(tempTaskDate ==
                                          varTaskDate.toString()))) {
                                    isFirstRow = false;
                                    tempTaskDate = varTaskDate.toString();
                                    return Column(
                                      children: [
                                        ListTile(
                                          title:
                                              Text(tempTaskDate.split(' ')[0]),
                                          leading: const CircleAvatar(
                                            backgroundColor: Colors.brown,
                                            foregroundColor: Colors.white,
                                            child: Icon(Icons.calendar_month),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.delete,
                                                    color: Colors.orange),
                                                onPressed: () async {
                                                  await purgeByDate(
                                                      varTaskDate);
                                                  setState(() {
                                                    const snackBar = SnackBar(
                                                      content: Text(
                                                          "Tasks for selected date deleted!"),
                                                      duration:
                                                          Duration(seconds: 2),
                                                    );
                                                    ScaffoldMessenger.of(
                                                        context)
                                                      ..removeCurrentSnackBar()
                                                      ..showSnackBar(snackBar);
                                                  });
                                                },
                                              )
                                            ],
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(varTitle),
                                          leading: const CircleAvatar(
                                            backgroundColor: Colors.black,
                                            foregroundColor: Colors.white,
                                            child: Icon(Icons
                                                .format_list_bulleted_outlined),
                                          ),
                                          trailing: PopupMenuButton(
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                //open edit page
                                                //navigateToEditPage(item);
                                                updateTodo(
                                                    varTodo.objectId!,
                                                    varTitle,
                                                    varDescription,
                                                    varTaskDate);
                                              } else if (value == 'delete') {
                                                //open delete page
                                                // ()   async {
                                                //   await
                                                deleteTodo(varTodo.objectId!);
                                                setState(() {
                                                  const snackBar = SnackBar(
                                                    content:
                                                        Text("Task deleted!"),
                                                    duration:
                                                        Duration(seconds: 2),
                                                  );
                                                  ScaffoldMessenger.of(context)
                                                    ..removeCurrentSnackBar()
                                                    ..showSnackBar(snackBar);
                                                });
                                                // };
                                              } else if (value == 'view') {
                                                //open edit page
                                                //navigateToEditPage(item);
                                                viewDetails(
                                                    varTodo.objectId!,
                                                    varTitle,
                                                    varDescription,
                                                    varTaskDate);
                                              }
                                            },
                                            itemBuilder: (context) {
                                              return [
                                                const PopupMenuItem(
                                                  value: 'view',
                                                  child: Text('View Details'),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'edit',
                                                  child: Text('Edit'),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Text('Delete'),
                                                ),
                                              ];
                                            },
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                  return ListTile(
                                    title: Text(varTitle),
                                    leading: const CircleAvatar(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      child: Icon(
                                          Icons.format_list_bulleted_outlined),
                                    ),
                                    trailing: PopupMenuButton(
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          //open edit page
                                          //navigateToEditPage(item);
                                          updateTodo(
                                              varTodo.objectId!,
                                              varTitle,
                                              varDescription,
                                              varTaskDate);
                                        } else if (value == 'delete') {
                                          //open delete page
                                          // ()   async {
                                          //   await
                                          deleteTodo(varTodo.objectId!);
                                          setState(() {
                                            const snackBar = SnackBar(
                                              content: Text("Task deleted!"),
                                              duration: Duration(seconds: 2),
                                            );
                                            ScaffoldMessenger.of(context)
                                              ..removeCurrentSnackBar()
                                              ..showSnackBar(snackBar);
                                          });
                                          // };
                                        } else if (value == 'view') {
                                          //open edit page
                                          //navigateToEditPage(item);
                                          viewDetails(
                                              varTodo.objectId!,
                                              varTitle,
                                              varDescription,
                                              varTaskDate);
                                        }
                                      },
                                      itemBuilder: (context) {
                                        return [
                                          const PopupMenuItem(
                                            value: 'view',
                                            child: Text('View Details'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Edit'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Delete'),
                                          ),
                                        ];
                                      },
                                    ),
                                  );
                                });
                          }
                      }
                    }))
          ],
        ),
        floatingActionButton:
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          FloatingActionButton.extended(
            onPressed: resetToAdd,
            heroTag: "Add Todo",
            label: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Add Todo',
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
            backgroundColor: Colors.amberAccent,
            elevation: 1,
          ),
          const SizedBox(width: 16.0),
          FloatingActionButton.extended(
            onPressed: reset,
            heroTag: "Reset",
            label: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Reset',
                style: TextStyle(
                  color: Colors.amberAccent,
                ),
              ),
            ),
            backgroundColor: Colors.black,
            elevation: 1,
          ),
          const SizedBox(width: 16.0),
          FloatingActionButton.extended(
            onPressed: purgeAll,
            heroTag: "Purge All",
            label: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Purge All',
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
            backgroundColor: Colors.amberAccent,
            elevation: 1,
          ),
        ])
        /*   floatingActionButton: FloatingActionButton.extended(
        onPressed: resetToAdd,
        label: const Text(
          'Add Todo',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.amberAccent,
        elevation: 1,
      ),*/

        );
  }

  /**
   *
   */
  Future<void> saveTodo(
      String title, String description, DateTime? selectedDate) async {
    log('Inside savetoDo $title');
    DateTime dateOnly =
        DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);
    log('date $dateOnly');
    final todo = ParseObject('Todo')
      ..set('title', title)
      ..set('description', description)
      ..set('taskDate', dateOnly)
      ..set('done', false);
    await todo.save();
  }

  /**
   *
   */
  Future<List<ParseObject>> getTodo() async {
    QueryBuilder<ParseObject> queryTodo =
        QueryBuilder<ParseObject>(ParseObject('Todo'));
    queryTodo.orderByDescending('taskDate');
    final ParseResponse apiResponse = await queryTodo.query();

    if (apiResponse.success && apiResponse.results != null) {
      return apiResponse.results as List<ParseObject>;
    } else {
      return [];
    }
  }

  /**
   *
   */
  Future<void> updateTodo(String objectId, String title, String description,
      DateTime varTaskDate) async {
    todoController.text = title;
    descriptionController.text = description;
    isEdit = true;
    editedId = objectId;
    selectedDate = varTaskDate;
    setState(() {
      isViewPanelEnabled = true;
      isButtonEnabled = true;
      buttonText = "Modify Task";
      isTextFieldEnabled = true;
    });
  }

  Future<void> resetToAdd() async {
    setState(() {
      isViewPanelEnabled = true;
      isButtonEnabled = true;
      buttonText = "Add Task";
      isTextFieldEnabled = true;
      todoController.clear();
      descriptionController.clear();
      selectedDate = null;
    });
  }

  Future<void> deleteTodo(String id) async {
    print("Delete$id");
    var todo = ParseObject('Todo')..objectId = id;
    await todo.delete();
  }

  purgeAll() async {
    log("Delete All");
    final query = QueryBuilder(ParseObject('Todo'));
    try {
      final ParseResponse response = await query.query();
      if (response.success && response.results != null) {
        final List<ParseObject> results = response.results as List<ParseObject>;

        // Delete all fetched objects
        for (final parseObject in results) {
          await parseObject.delete();
        }
        log('All objects deleted successfully');
      } else {
        log('Query failed: ${response.error?.message}');
      }
    } catch (e) {
      log('Error: $e');
    }
    setState(() {
      todoController.clear();
      descriptionController.clear();
      isEdit = false;
      editedId = "";
      buttonText = "Add Task";
      isButtonEnabled = true;
      isViewPanelEnabled = false;
      selectedDate = null;
    });
  }

  void viewDetails(String objectId, String varTitle, String varDescription,
      DateTime varTaskDate) {
    todoController.text = varTitle;
    descriptionController.text = varDescription;
    selectedDate = varTaskDate;
    setState(() {
      isViewPanelEnabled = true;
      isButtonEnabled = false;
      isTextFieldEnabled = false;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime(2024, 12, 31),
      locale: const Locale('en', 'IN'), // Set the desired locale
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked.toLocal();
      });
    }
  }

  purgeByDate(DateTime varTaskDate) async {
    log("purgeByDate$varTaskDate");
    final query = QueryBuilder(ParseObject('Todo'));
    query.whereEqualTo('taskDate', varTaskDate);
    try {
      final ParseResponse response = await query.query();
      if (response.success && response.results != null) {
        final List<ParseObject> results = response.results as List<ParseObject>;

        // Delete all fetched objects
        for (final parseObject in results) {
          await parseObject.delete();
        }
        log('purgeByDate deleted successfully');
      } else {
        log('Query failed: ${response.error?.message}');
      }
    } catch (e) {
      log('Error: $e');
    }
    setState(() {
      todoController.clear();
      descriptionController.clear();
      isEdit = false;
      editedId = "";
      buttonText = "Add Task";
      isButtonEnabled = true;
      isViewPanelEnabled = false;
      selectedDate = null;
    });
  }
}
