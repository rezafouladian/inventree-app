import 'package:InvenTree/widget/dialogs.dart';
import 'package:InvenTree/widget/fields.dart';
import 'package:InvenTree/widget/spinner.dart';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../api.dart';
import '../preferences.dart';
import '../user_profile.dart';

class InvenTreeLoginSettingsWidget extends StatefulWidget {

  @override
  _InvenTreeLoginSettingsState createState() => _InvenTreeLoginSettingsState();
}


class _InvenTreeLoginSettingsState extends State<InvenTreeLoginSettingsWidget> {

  final GlobalKey<_InvenTreeLoginSettingsState> _loginKey = GlobalKey<_InvenTreeLoginSettingsState>();

  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();

  final GlobalKey<FormState> _addProfileKey = new GlobalKey<FormState>();

  List<UserProfile> profiles;

  _InvenTreeLoginSettingsState() {
    _reload();
  }

  void _reload() async {

    profiles = await UserProfileDBManager().getAllProfiles();

    setState(() {
    });
  }

  void _editProfile(BuildContext context, {UserProfile userProfile, bool createNew = false}) {

    var _name;
    var _server;
    var _username;
    var _password;

    UserProfile profile;

    if (userProfile != null) {
      profile = userProfile;
    }

    showFormDialog(
      I18N.of(context).profileAdd,
      key: _addProfileKey,
      callback: () {
          if (createNew) {
            // TODO - create the new profile...
            UserProfile profile = UserProfile(
              name: _name,
              server: _server,
              username: _username,
              password: _password
            );

            _addProfile(profile);
          } else {

            profile.name = _name;
            profile.server = _server;
            profile.username = _username;
            profile.password = _password;

            _updateProfile(profile);

          }
      },
      fields: <Widget> [
        StringField(
          label: I18N.of(context).name,
          hint: "Enter profile name",
          initial: createNew ? '' : profile.name,
          onSaved: (value) => _name = value,
          validator: _validateProfileName,
        ),
        StringField(
          label: I18N.of(context).server,
          hint: "http[s]://<server>:<port>",
          initial: createNew ? '' : profile.server,
          validator: _validateServer,
          onSaved: (value) => _server = value,
        ),
        StringField(
          label: I18N.of(context).username,
          hint: "Enter username",
          initial: createNew ? '' : profile.username,
          onSaved: (value) => _username = value,
          validator: _validateUsername,
        ),
        StringField(
          label: I18N.of(context).password,
          hint: "Enter password",
          initial: createNew ? '' : profile.password,
          onSaved: (value) => _password = value,
          validator: _validatePassword,
        )
      ]
    );
  }

  String _validateProfileName(String value) {

    if (value.isEmpty) {
      return 'Profile name cannot be empty';
    }

    // TODO: Check if a profile already exists with ths name

    return null;
  }

  String _validateServer(String value) {

    if (value.isEmpty) {
      return 'Server cannot be empty';
    }

    if (!value.startsWith("http:") && !value.startsWith("https:")) {
      return 'Server must start with http[s]';
    }

    // TODO: URL validator

    return null;
  }

  String _validateUsername(String value) {
    if (value.isEmpty) {
      return 'Username cannot be empty';
    }

    return null;
  }

  String _validatePassword(String value) {
    if (value.isEmpty) {
      return 'Password cannot be empty';
    }

    return null;
  }

  void _selectProfile(BuildContext context, UserProfile profile) async {

    // Disconnect InvenTree
    InvenTreeAPI().disconnectFromServer();

    await UserProfileDBManager().selectProfile(profile.key);

    _reload();

    // Attempt server login (this will load the newly selected profile
    InvenTreeAPI().connectToServer(_loginKey.currentContext).then((result) {
      _reload();
    });

    _reload();
  }

  void _deleteProfile(UserProfile profile) async {

    await UserProfileDBManager().deleteProfile(profile);

    _reload();

    if (InvenTreeAPI().isConnected() && profile.key == InvenTreeAPI().profile.key) {
      InvenTreeAPI().disconnectFromServer();
    }
  }

  void _updateProfile(UserProfile profile) async {

    await UserProfileDBManager().updateProfile(profile);

    _reload();

    if (InvenTreeAPI().isConnected() && profile.key == InvenTreeAPI().profile.key) {
      // Attempt server login (this will load the newly selected profile

      InvenTreeAPI().connectToServer(_loginKey.currentContext).then((result) {
        _reload();
      });
    }
  }

  void _addProfile(UserProfile profile) async {

    await UserProfileDBManager().addProfile(profile);

    _reload();
  }

  Widget _getProfileIcon(UserProfile profile) {

    // Not selected? No icon for you!
    if (profile == null || !profile.selected) return null;

    // Selected, but (for some reason) not the same as the API...
    if (InvenTreeAPI().profile == null || InvenTreeAPI().profile.key != profile.key) {
      return FaIcon(
        FontAwesomeIcons.questionCircle,
        color: Color.fromRGBO(250, 150, 50, 1)
      );
    }

    // Reflect the connection status of the server
    if (InvenTreeAPI().isConnected()) {
      return FaIcon(
        FontAwesomeIcons.checkCircle,
        color: Color.fromRGBO(50, 250, 50, 1)
      );
    } else if (InvenTreeAPI().isConnecting()) {
      return Spinner(
        icon: FontAwesomeIcons.spinner,
        color: Color.fromRGBO(50, 50, 250, 1),
      );
    } else {
      return FaIcon(
        FontAwesomeIcons.timesCircle,
        color: Color.fromRGBO(250, 50, 50, 1),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    final Size screenSize = MediaQuery.of(context).size;

    List<Widget> children = [];

    if (profiles != null && profiles.length > 0) {
      for (int idx = 0; idx < profiles.length; idx++) {
        UserProfile profile = profiles[idx];

        children.add(ListTile(
          title: Text(
            profile.name,
          ),
          tileColor: profile.selected ? Color.fromRGBO(0, 0, 0, 0.05) : null,
          subtitle: Text("${profile.server}"),
          trailing: _getProfileIcon(profile),
          onTap: () {
            _selectProfile(context, profile);
          },
          onLongPress: () {
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return SimpleDialog(
                    title: Text(profile.name),
                    children: <Widget>[
                      Divider(),
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _selectProfile(context, profile);
                        },
                        child: Text(I18N.of(context).profileSelect),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _editProfile(context, userProfile: profile);
                        },
                        child: Text(I18N.of(context).profileEdit),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Navigator.of(context, rootNavigator: true).pop();
                          confirmationDialog(
                              I18N.of(context).delete,
                              I18N.of(context).profileDelete + "?",
                              onAccept: () {
                                _deleteProfile(profile);
                              }
                          );
                        },
                        child: Text(I18N.of(context).profileDelete),
                      )
                    ],
                  );
                }
            );
          },
        ));
      }
    } else {
      // No profile available!
      children.add(
        ListTile(
          title: Text("No profiles available"),
        )
      );
    }

    return Scaffold(
      key: _loginKey,
      appBar: AppBar(
        title: Text(I18N.of(context).profileSelect),
      ),
      body: Container(
        child: ListView(
          children: ListTile.divideTiles(
            context: context,
            tiles: children
          ).toList(),
        )
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(FontAwesomeIcons.plus),
        onPressed: () {
          _editProfile(context, createNew: true);
        },
      )
    );
  }
}