import 'package:eosio_passid_mobile_app/screen/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import "package:eosio_passid_mobile_app/screen/main/stepper/stepEnterAccount/stepEnterAccount.dart";
import "package:eosio_passid_mobile_app/screen/main/stepper/stepper.dart";
import 'package:flutter/cupertino.dart';
import 'package:eosio_passid_mobile_app/utils/storage.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:eosio_passid_mobile_app/screen/customBottomPicker.dart';
import 'package:eosio_passid_mobile_app/utils/size.dart';
import 'package:eosio_passid_mobile_app/screen/theme.dart';

class StepEnterAccountForm extends StatefulWidget {
  StepEnterAccountForm() {}

  @override
  _StepEnterAccountFormState createState() => _StepEnterAccountFormState();
}

class _StepEnterAccountFormState extends State<StepEnterAccountForm> {
  TextEditingController _accountTextController;
  var _storage;

  _StepEnterAccountFormState() {
    this._accountTextController = TextEditingController();
    this._storage = Storage();
  }

  //update fields in account form
  void updateFields() {
    var storage = Storage();
    StepDataEnterAccount storageStepEnterAccount = storage.getStorageData(0);
    _accountTextController.text = storageStepEnterAccount.accountID != null ? storageStepEnterAccount.accountID : "";
  }

  //clear fields in account form
  void emptyFields() {
    _accountTextController.text = "";
  }

  void selectNetworkOld(var context) {
    showPlatformModalSheet(
        context: context,
        builder: (_) => PopupMenuButton(
              itemBuilder: (_) => <PopupMenuItem<String>>[
                PopupMenuItem<String>(child: Text('11'), value: '11'),
                PopupMenuItem<String>(child: Text('22'), value: '22'),
              ],
              onSelected: (value) => {},
            )).whenComplete(() {
    });
  }

  void selectNetwork(
      var context, StepEnterAccountState state, var stepEnterAccountBloc) {
    var storage = Storage();
    StepDataEnterAccount storageStepEnterAccount = storage.getStorageData(0);
    BottomPickerStructure bps = BottomPickerStructure();
    bps.importStorageNodeList(storage.storageNodes(), storage.getSelectedNode(),
        "Select node", "Please select the node");
    CustomBottomPickerState cbps = CustomBottomPickerState(structure: bps);
    cbps.showPicker(context,
        //callback function to manage user click action on selection
        (BottomPickerElement returnedStorageNode) {
      //find the node with the same name as returned name
      for (StorageNode item in storage.storageNodes()) {
        //the same name found -  set selected node as found item
        if (item.name == returnedStorageNode.name) {
          storage.selectedNode = item;
          if (state is FullState) {
            stepEnterAccountBloc.add(AccountConfirmation(
                accountID: storageStepEnterAccount.accountID));
          }
          if (state is DeletedState) {
            stepEnterAccountBloc.add(AccountDelete());
          }
          final stepperBloc = BlocProvider.of<StepperBloc>(context);
          stepperBloc.liveModifyHeader(0, context);
        }
      }
    });
  }

  Widget selectNetworkWithTile(var context,
      StepEnterAccountState state,
      var stepEnterAccountBloc) {
    var storage = Storage();
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
      title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'Network',
              style: TextStyle(
                  fontSize: AndroidThemeST().getValues().themeValues["TILE_BAR"]
                      ["SIZE_TEXT"]),
            ),
            Text(storage.getNode().name,
                style: TextStyle(
                    fontSize: AndroidThemeST()
                        .getValues()
                        .themeValues["TILE_BAR"]["SIZE_TEXT"],
                    color: AndroidThemeST().getValues().themeValues["TILE_BAR"]
                        ["COLOR_TEXT"]))
          ]),
      trailing: Icon(Icons.expand_more),
      onTap: () => selectNetwork(context, state, stepEnterAccountBloc),
    );
  }

  Widget body(BuildContext context, StepEnterAccountState state,
      var stepEnterAccountBloc) {
    var storage = Storage();
    if (state is DeletedState) emptyFields();
    if (state is FullState) updateFields();

    final stepperBloc = BlocProvider.of<StepperBloc>(context);
    return Form(
        autovalidate: true,
        child: Column(children: <Widget>[
          selectNetworkWithTile(context, state, stepEnterAccountBloc),
          if (storage.selectedNode.name != "ZeroPass Server")
            TextFormField(
              controller: _accountTextController,
              decoration: InputDecoration(
                labelText: 'Account name',
              ),
              inputFormatters: <TextInputFormatter>[
                WhitelistingTextInputFormatter(RegExp(r'\b[a-z1-5.]+')),
                LengthLimitingTextInputFormatter(13)
              ],
              validator: (value) =>
                  stepEnterAccountBloc.validatorFunction(value, context)
                      ? stepEnterAccountBloc.validatorText
                      : null,
              onChanged: (value) async {
                //save to storage
                StepDataEnterAccount storageStepEnterAccount =
                    _storage.getStorageData(0);
                storageStepEnterAccount.accountID = _accountTextController.text.length !=0 ? _accountTextController.text : null;
                //save storage
                _storage.save();

                stepperBloc.liveModifyHeader(0, context);
              },
            ),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    final stepEnterAccountBloc = BlocProvider.of<StepEnterAccountBloc>(context);
    return BlocBuilder(
      bloc: stepEnterAccountBloc,
      builder: (BuildContext context, StepEnterAccountState state) {
        return Container(
            width: CustomSize.getMaxWidth(context, STEPPER_ICON_PADDING),
            child: body(context, state, stepEnterAccountBloc));
      },
    );
  }
}
