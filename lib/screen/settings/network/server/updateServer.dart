import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:eosio_passid_mobile_app/utils/storage.dart';
import 'package:eosio_passid_mobile_app/constants/constants.dart';
import 'package:eosio_passid_mobile_app/utils/structure.dart';
import 'package:card_settings/card_settings.dart';
import 'package:eosio_passid_mobile_app/screen/alert.dart';
import 'package:eosio_passid_mobile_app/screen/settings/custom/CustomCardSettingsButtonDelete.dart';
import 'package:logging/logging.dart';

class SettingsUpdateServer extends StatelessWidget {
  final _log = Logger('Settings.SettingsUpdateServer');

  NetworkType networkType;
  Server server;
  //to check if any field has been updated
  Server serverToUpdate;

  SettingsUpdateServer({@required this.networkType, @required this.server})
  {
    this.serverToUpdate = new Server.clone(server);
    //init validation fields
    this.server.initValidation();
  }

  void onButtonPressedDelete({@required BuildContext context}) async {
    _log.fine("Button 'delete' clicked");
    bool answer = await showAlert<bool>(
        context: context,
        title: Text("Are you sure you want to delete na item?"),
        actions: <PlatformDialogAction>[
          PlatformDialogAction(
              child: PlatformText('No'),
              onPressed: () => Navigator.pop(context, false)
          ),
          PlatformDialogAction(
              child: PlatformText('Yes'),
              onPressed: () => Navigator.pop(context, true)
          ),
        ],
        closeOnBackPressed: true);
    if ( await answer){
      Storage storage = Storage();
      for (var element in storage.nodeSet.nodes[this.networkType].servers){
        if (this.server.compare(element)){
          _log.finest("Element found in database.");
          element.clone(serverToUpdate);
          storage.nodeSet.nodes[this.networkType].delete(element);
          storage.save();
          Navigator.pop(context);
          break;
        }
      }
    }
  }

  void onButtonPressedSave({@required BuildContext context, bool showNotification = true})
  {
    _log.fine("Save clicked");
    Storage storage = Storage();

    //copy values to storage if there is any change
    if (!this.server.compare(this.serverToUpdate)) {
      _log.finer("No data has been changed since last save/open.");
        for (var element in storage.nodeSet.nodes[this.networkType].servers){
        if (this.server.compare(element)){
          _log.finest("Element found in database. Clone the new data to this element.");
          element.clone(serverToUpdate);
          this.server.clone(this.serverToUpdate);
          storage.save(callback: (successfull){
            if (successfull && showNotification && context != null)
              showAlert(
                  context: context,
                  title: Text("The data have been saved successfully"),
                  closeOnBackPressed: true);
          });
          break;
        }
      }
    }
  }

  Future<bool> onWillPop(BuildContext context) async {
    if (!this.server.compare(this.serverToUpdate)) {
      bool answer = await showAlert<bool>(
          context: context,
          title: Text("The data has been changed."),
          actions: [
            PlatformDialogAction(
                child: PlatformText('Back'),
                onPressed: () {
                  Navigator.pop(context, false);
                  return false;
                }),
            PlatformDialogAction(
                child: PlatformText('Save and go',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  onButtonPressedSave(context: context, showNotification: false);
                  Navigator.pop(context, true);
                  return true;
                })
          ]);
      return new Future.value(answer);
    } else
      return new Future.value(true);
  }

  String validator(String value){
    _log.finer("URL: $value");
    if (value == null || value.isEmpty) {
      _log.finest("URL; value is null.");
      this.serverToUpdate.setValidationError("name", "Field 'url' is empty.");
      return 'URL is required.';
    }
    if (RegExp(r'[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&=]*)').hasMatch(value) == false){
      _log.finest("URL; regular expression does not match.");
      this.serverToUpdate.setValidationError("name", "Field 'URL' not match regular expression.");
      return 'Not valid URL address.';
    }
  }

  String onChanged(String value){
    _log.finer("URL: $value");
    if (value == null || value.isEmpty) {
      _log.finest("URL; value is null.");
      //this.serverToUpdate.setValidationError("name", "Field 'url' is empty.");
      //return 'URL is required.';
      return null;
    }
    if (RegExp(r'[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&=]*)').hasMatch(value) == false){
      _log.finest("URL; regular expression does not match.");
      //this.serverToUpdate.setValidationError("name", "Field 'URL' not match regular expression.");
      //return 'Not valid URL address.';
      return null;
    }

    if (value.contains("http:\/\/")){
      _log.finest("http in string");
      value= value.substring(7);
      this.serverToUpdate.isEncryptedEndpoint = false;
    }
    else if (value.contains("https:\/\/")){
      _log.finest("https in string;");
      value = value.substring(8);
      this.serverToUpdate.isEncryptedEndpoint = true;
    }
    else{
      _log.finest("No http in string. Automatic set as https in database.");
      this.serverToUpdate.isEncryptedEndpoint = true;
    }

    if (value.lastIndexOf(new RegExp(r'(:\d)')) > 0){
      _log.finest("Port detected.");
      String port = value.substring(value.lastIndexOf(new RegExp(r'(:\d)')) + 1);
      _log.finest("Port: $port");
      this.serverToUpdate.port = int.parse(port);
      value = value.substring(0, value.lastIndexOf(new RegExp(r'(:\d)')));
    }
    else{
      _log.finest("No port detected");
      this.serverToUpdate.port = this.serverToUpdate.isEncryptedEndpoint? 443 :80;
    }

    _log.finest("Parsed host is: $value");
    this.server.setValidationCorrect("host");
    this.serverToUpdate.host = value;
    return null;
  }

  String initialValue(){
    return this.serverToUpdate.toString();
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    return PlatformScaffold(
        material: (_,__) => MaterialScaffoldData(resizeToAvoidBottomInset: false),
        cupertino: (_,__) => CupertinoPageScaffoldData(resizeToAvoidBottomInset: false),
        appBar: PlatformAppBar(
          //automaticallyImplyLeading: true,
          title: Text("Update network", style: TextStyle(color: Colors.white)),
          trailingActions: <Widget>[
            PlatformIconButton(
                cupertino: (_,__) => CupertinoIconButtonData(
                  icon: Icon( // Save icon
                      const IconData(0xf41F, fontPackage: CupertinoIcons.iconFontPackage, fontFamily: CupertinoIcons.iconFont),
                      color: Colors.white,
                      size: 35
                  ),
                  padding: EdgeInsets.all(0),
                ),
                androidIcon: Icon(Icons.save, size: 35.0),
                material: (_, __) => MaterialIconButtonData(tooltip: 'Save'),
                onPressed: () {
                  onButtonPressedSave(showNotification: true, context: context);
                })
          ],
        ),
        body: WillPopScope(
          onWillPop: () => onWillPop(context),
          child: Form(
              key: _formKey,
              child: Column(children: [
                CardSettings(
                    children: <CardSettingsSection>[
                      CardSettingsSection(
                        children: <CardSettingsWidget>[
                          new CardSettingsText(
                            label: 'URL',
                            maxLength: 50,
                            contentAlign: TextAlign.right,
                            initialValue: initialValue(),
                            //autovalidate: true,
                            //enabled: this.networkType == NetworkType.CUSTOM ? true : false,

                            validator: (value) {
                              return onChanged(value);
                            },
                            onChanged: (value){
                              return onChanged(value);
                            },
                          ),
                        ],
                      ),
                    ]
                ),
                CustomCardSettingsButtonDelete(onPressed: (){
                  onButtonPressedDelete(context: context);
                })
              ])
          ),
        ));
  }
}