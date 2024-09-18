import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vigilant_care/db/db.services.dart';
import 'package:vigilant_care/model/contactsm.dart';
//import 'package:vigilant_care/utils/constants.dart';


class ContactsPage extends StatefulWidget {
  const ContactsPage({Key? key}) : super(key: key);

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Contact> contacts = [];
  List<Contact> contactsFiltered = [];
  DatabaseHelper _databaseHelper = DatabaseHelper();
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    askPermissions();
  }

  Future<void> askPermissions() async {
    PermissionStatus permissionStatus = await getContactsPermissions();
    print('Permission status: $permissionStatus');
    if (permissionStatus == PermissionStatus.granted) {
      // Fetch contacts only when permission is granted
      getAllContacts();
      searchController.addListener(() {
        filterContact();
      });
    } else {
      handInvaliedPermissions(permissionStatus);
    }
  }

  Future<PermissionStatus> getContactsPermissions() async {
    PermissionStatus permission = await Permission.contacts.status;
    if (!permission.isGranted && permission != PermissionStatus.permanentlyDenied) {
      PermissionStatus permissionStatus = await Permission.contacts.request();
      return permissionStatus;
    } else {
      return permission;
    }
  }

  void handInvaliedPermissions(PermissionStatus permissionStatus) {
    if (permissionStatus == PermissionStatus.denied) {
      dialogueBox(context, "Access to the contacts denied by the user");
    } else if (permissionStatus == PermissionStatus.permanentlyDenied) {
      dialogueBox(context, "Access to contacts is permanently denied. Please enable it in settings.");
    }
  }

  Future<void> getAllContacts() async {
    try {
      List<Contact> _contacts = await ContactsService.getContacts(withThumbnails: false);
      print("Fetched ${_contacts.length} contacts");

      if (_contacts.isEmpty) {
        Fluttertoast.showToast(msg: "No contacts found.");
      }

      setState(() {
        contacts = _contacts;
        contacts.sort((a, b) => _compareContacts(a, b));
        filterContact();
      });
    } catch (e) {
      print("Error fetching contacts: $e");
      Fluttertoast.showToast(msg: "Error fetching contacts.");
    }
  }

  int _compareContacts(Contact a, Contact b) {
    String nameA = a.displayName ?? "";
    String nameB = b.displayName ?? "";

    // Check if either name starts with a symbol
    bool isASymbol = RegExp(r'^[^a-zA-Z]').hasMatch(nameA);
    bool isBSymbol = RegExp(r'^[^a-zA-Z]').hasMatch(nameB);

    if (isASymbol && !isBSymbol) {
      return -1; // a should come before b
    } else if (!isASymbol && isBSymbol) {
      return 1; // b should come before a
    } else {
      // Both are symbols or both are letters
      return nameA.compareTo(nameB);
    }
  }

  void filterContact() {
    List<Contact> _contacts = [];
    _contacts.addAll(contacts);

    if (searchController.text.isNotEmpty) {
      _contacts.retainWhere((element) {
        String searchTerm = searchController.text.toLowerCase();
        String searchTermFlattren = flattenPhoneNumber(searchTerm);
        String contactName = element.displayName ?? "";

        bool nameMatch = contactName.toLowerCase().contains(searchTerm);
        if (nameMatch) {
          return true;
        }

        if (element.phones != null && searchTermFlattren.isNotEmpty) {
          var phoneMatch = element.phones!.any((p) {
            String phoneFlattered = flattenPhoneNumber(p.value!);
            return phoneFlattered.contains(searchTermFlattren);
          });
          return phoneMatch;
        }
        return false;
      });
    }

    setState(() {
      contactsFiltered = _contacts;
    });
  }

  String flattenPhoneNumber(String phoneStr) {
    return phoneStr.replaceAllMapped(RegExp(r'^(\+)|\D'), (Match m) {
      return m[0] == "+" ? "+" : "";
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isSearchIng = searchController.text.isNotEmpty;
    bool listItemExit = (contactsFiltered.length > 0 || contacts.length > 0);
    return Scaffold(
      body: contacts.isEmpty
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      autofocus: true,
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: "Search contact",
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  listItemExit
                      ? Expanded(
                          child: ListView.builder(
                            itemCount: isSearchIng
                                ? contactsFiltered.length
                                : contacts.length,
                            itemBuilder: (BuildContext context, int index) {
                              Contact contact = isSearchIng
                                  ? contactsFiltered[index]
                                  : contacts[index];
                              return ListTile(
                                title: Text(contact.displayName ?? ""),
                                subtitle: contact.phones!.isNotEmpty
                                    ? Text(contact.phones!.elementAt(0).value!)
                                    : Text("No phone number"),
                                leading: contact.avatar != null &&
                                        contact.avatar!.isNotEmpty
                                    ? CircleAvatar(
                                        backgroundColor: Color.fromARGB(1, 12, 64, 92),
                                        backgroundImage: MemoryImage(contact.avatar!),
                                      )
                                    : CircleAvatar(
                                        backgroundColor: Color.fromARGB(1, 12, 64, 92),
                                        child: Text(contact.initials()),
                                      ),
                                onTap: () {
                                  if (contact.phones != null && contact.phones!.isNotEmpty) {
                                    final String phoneNum = contact.phones!.elementAt(0).value!;
                                    final String name = contact.displayName!;
                                    _addContact(TContact(phoneNum, name));
                                  } else {
                                    Fluttertoast.showToast(
                                        msg: "Oops! Phone number of this contact does not exist");
                                  }
                                },
                              );
                            },
                          ),
                        )
                      : Container(
                          child: Text("Searching..."),
                        ),
                ],
              ),
            ),
    );
  }

  void _addContact(TContact newContact) async {
    int result = await _databaseHelper.insertContact(newContact);
    if (result != 0) {
      Fluttertoast.showToast(msg: "Contact added successfully");
    } else {
      Fluttertoast.showToast(msg: "Failed to add contact");
    }
    Navigator.of(context).pop(true);
  }

  void dialogueBox(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Permission Denied"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }
}
// class ContactsPage extends StatefulWidget {
//   const ContactsPage({Key? key}) : super(key: key);

//   @override
//   State<ContactsPage> createState() => _ContactsPageState();
// }

// class _ContactsPageState extends State<ContactsPage> {
//   List<Contact> contacts = [];
//   List<Contact> contactsFiltered = [];
//   DatabaseHelper _databaseHelper = DatabaseHelper();

//   TextEditingController searchController = TextEditingController();
//   @override
//   void initState() {
//     super.initState();
//     askPermissions();
//   }

//   String flattenPhoneNumber(String phoneStr) {
//     return phoneStr.replaceAllMapped(RegExp(r'^(\+)|\D'), (Match m) {
//       return m[0] == "+" ? "+" : "";
//     });
//   }

//   filterContact() {
//     List<Contact> _contacts = [];
//     _contacts.addAll(contacts);
//     if (searchController.text.isNotEmpty) {
//       _contacts.retainWhere((element) {
//         String searchTerm = searchController.text.toLowerCase();
//         String searchTermFlattren = flattenPhoneNumber(searchTerm);
//         String contactName = element.displayName ?? "";
//         bool nameMatch = contactName.contains(searchTerm);
//         if (nameMatch == true) {
//           return true;
//         }
//         if (searchTermFlattren.isEmpty) {
//           return false;
//         }
//         var phone = element.phones!.firstWhere((p) {
//           String phnFLattered = flattenPhoneNumber(p.value!);
//           return phnFLattered.contains(searchTermFlattren);
//         });
//         return phone.value != null;
//       });
//     }
//     setState(() {
//       contactsFiltered = _contacts;
//     });
//   }

//   Future<void> askPermissions() async {
//     PermissionStatus permissionStatus = await getContactsPermissions();
//     print('Permission status: $permissionStatus');
//     if (permissionStatus == PermissionStatus.granted) {
//       getAllContacts();
//       searchController.addListener(() {
//       filterContact();
//       });
//     } else {
//       handInvaliedPermissions(permissionStatus);
//     }
//   }

//   handInvaliedPermissions(PermissionStatus permissionStatus) {
//     if (permissionStatus == PermissionStatus.denied) {
//       dialogueBox(context, "Access to the contacts denied by the user");
//     } else if (permissionStatus == PermissionStatus.permanentlyDenied) {
//       dialogueBox(context, "May contact does exist in this device");
//     }
//   }

//   Future<PermissionStatus> getContactsPermissions() async {
//     PermissionStatus permission = await Permission.contacts.status;
//     if (!permission.isGranted && permission != PermissionStatus.permanentlyDenied) {
//       PermissionStatus permissionStatus = await Permission.contacts.request();
//       return permissionStatus;
//     } else {
//       return permission;
//     }
//   }

//   getAllContacts() async {
//     try {
//      List<Contact> _contacts =
//         await ContactsService.getContacts(withThumbnails: false);
//         print("Fetched${_contacts.length} contacts");
      
//       if (_contacts.isEmpty) {
//         Fluttertoast.showToast(msg: "No contacts found.");
//       }

//      setState(() {
//       contacts = _contacts;
//     });
//     } catch (e) {
//       print("Error fetching contacts: $e");
//       Fluttertoast.showToast(msg: "Error fetching contacts.");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     bool isSearchIng = searchController.text.isNotEmpty;
//     bool listItemExit = (contactsFiltered.length > 0 || contacts.length > 0);
//     return Scaffold(
//       body: contacts.length == 0
//           ? Center(child: CircularProgressIndicator())
//           : SafeArea(
//               child: Column(
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: TextField(
//                       autofocus: true,
//                       controller: searchController,
//                       decoration: InputDecoration(
//                           labelText: "search contact",
//                           prefixIcon: Icon(Icons.search)),
//                     ),
//                   ),
//                   listItemExit == true
//                       ? Expanded(
//                           child: ListView.builder(
//                             itemCount: isSearchIng == true
//                                 ? contactsFiltered.length
//                                 : contacts.length,
//                             itemBuilder: (BuildContext context, int index) {
//                               Contact contact = isSearchIng == true
//                                   ? contactsFiltered[index]
//                                   : contacts[index];
//                               return ListTile(
//                                 title: Text(contact.displayName ?? ""),
//                                 subtitle:Text(contact.phones!.elementAt(0)
//                                 .value!) ,
//                                 leading: contact.avatar != null &&
//                                         contact.avatar!.length > 0
//                                     ? CircleAvatar(
//                                         backgroundColor:Color.fromARGB(1, 12, 64, 92),
//                                         backgroundImage:
//                                             MemoryImage(contact.avatar!),
//                                       )
//                                     : CircleAvatar(
//                                         backgroundColor:Color.fromARGB(1, 12, 64, 92),
//                                         child: Text(contact.initials()),
//                                       ),
//                                 onTap: () {
//                                   if (contact.phones!.length > 0) {
//                                     final String phoneNum =
//                                         contact.phones!.elementAt(0).value!;
//                                     final String name = contact.displayName!;
//                                     _addContact(TContact(phoneNum, name));
//                                   } else {
//                                     Fluttertoast.showToast(
//                                         msg:
//                                             "Oops! phone number of this contact does exist");
//                                   }
//                                 },
//                               );
//                             },
//                           ),
//                         )
//                       : Container(
//                           child: Text("searching"),
//                         ),
//                 ],
//               ),
//             ),
//     );
//   }

//   void _addContact(TContact newContact) async {
//     int result = await _databaseHelper.insertContact(newContact);
//     if (result != 0) {
//       Fluttertoast.showToast(msg: "contact added successfully");
//     } else {
//       Fluttertoast.showToast(msg: "Failed to add contacts");
//     }
//     Navigator.of(context).pop(true);
//   }
// }