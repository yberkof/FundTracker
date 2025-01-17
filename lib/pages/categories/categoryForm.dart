import 'package:community_material_icon/community_material_icon.dart';
import 'package:firebase_auth/firebase_auth.dart' as FirebaseAuthentication
    show User;
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:fund_tracker/models/category.dart';
import 'package:fund_tracker/services/databaseWrapper.dart';
import 'package:fund_tracker/services/sync.dart';
import 'package:fund_tracker/shared/components.dart';
import 'package:fund_tracker/shared/styles.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class CategoryForm extends StatefulWidget {
  final Category category;
  final int numExistingCategories;
  final bool isUsed;
  final String uid;

  CategoryForm({
    this.category,
    this.numExistingCategories,
    this.isUsed = false,
    this.uid,
  });

  @override
  _CategoryFormState createState() => _CategoryFormState();
}

class _CategoryFormState extends State<CategoryForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  final FocusNode _nameFocus = new FocusNode();

  bool _isNameInFocus = false;

  String _name;
  int _icon;
  Color _iconColor;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _name = widget.category.name ?? '';
    _icon = widget.category.icon;
    _iconColor = widget.category.iconColor;

    _nameController.text = widget.category.name;

    _nameFocus.addListener(_checkFocus);
  }

  void _checkFocus() {
    setState(() {
      _isNameInFocus = _nameFocus.hasFocus;
    });
  }

  _pickIcon() async {
    // IconData icon = await FlutterIconPicker.showIconPicker(context,
    //     iconSize: 40,
    //     iconPickerShape:
    //         RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    //     title:
    //         Text('Pick an icon', style: TextStyle(fontWeight: FontWeight.bold)),
    //     closeChild: Text(
    //       'Close',
    //       textScaleFactor: 1.25,
    //     ),
    //     searchHintText: 'Search icon...',
    //     noResultsText: 'No results for:');
    //
    // _icon = icon.codePoint;
    // setState(() {});
    //
    // debugPrint('Picked Icon:  $icon');
  }

  @override
  Widget build(BuildContext context) {
    final _user = Provider.of<FirebaseAuthentication.User>(context);
    final isEditMode =
        !widget.category.equalTo(Category.empty(widget.numExistingCategories));
    return widget.isUsed != null
        ? Scaffold(
            appBar: AppBar(
              title: title(isEditMode),
              actions: isEditMode && !widget.isUsed
                  ? <Widget>[
                      DeleteIcon(
                        context,
                        itemDesc: 'category',
                        deleteFunction: () => DatabaseWrapper(_user.uid)
                            .deleteCategories([widget.category]),
                        syncFunction: SyncService(_user.uid).syncCategories,
                      )
                    ]
                  : null, // add reset category here for defaults
            ),
            body: isLoading
                ? Loader()
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding: formPadding,
                      children: <Widget>[
                        SizedBox(height: 10.0),
                        TextFormField(
                          controller: _nameController,
                          focusNode: _nameFocus,
                          validator: (val) {
                            if (val.isEmpty) {
                              return 'Enter a name for this category.';
                            }
                            return null;
                          },
                          decoration: clearInput(
                            labelText: 'Name',
                            enabled: _name.isNotEmpty && _isNameInFocus,
                            onPressed: () {
                              setState(() => _name = '');
                              _nameController.safeClear();
                            },
                          ),
                          textCapitalization: TextCapitalization.words,
                          onChanged: (val) {
                            setState(() => _name = val);
                          },
                        ),
                        SizedBox(height: 10.0),
                        FlatButton(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text('Icon'),
                              Icon(
                                IconData(
                                  _icon,
                                  fontFamily: 'MaterialIcons',
                                  fontPackage: null,
                                ),
                              ),
                            ],
                          ),
                          onPressed: () async {
                            await _pickIcon();
                          },
                        ),
                        SizedBox(height: 10.0),
                        FlatButton(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text('Icon Color'),
                              Icon(
                                CommunityMaterialIcons.circle,
                                color: _iconColor,
                              ),
                            ],
                          ),
                          onPressed: () async {
                            Color color = await Navigator.of(context)
                                .push(MaterialPageRoute(
                              builder: (context) {
                                return CategoryColorPicker(
                                  currentColor: _iconColor,
                                );
                              },
                            ));
                            if (color != null) {
                              setState(() => _iconColor = color);
                            }
                          },
                        ),
                        SizedBox(height: 10.0),
                        Icon(
                          IconData(
                            _icon,
                            fontFamily: 'MaterialDesignIconFont',
                            fontPackage: 'community_material_icon',
                          ),
                          color: _iconColor,
                        ),
                        SizedBox(height: 10.0),
                        RaisedButton(
                          color: Theme.of(context).primaryColor,
                          child: Text(
                            isEditMode ? 'Save' : 'Add',
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () async {
                            if (_formKey.currentState.validate()) {
                              Category category = Category(
                                cid: widget.category.cid ?? Uuid().v1(),
                                name: _name,
                                icon: _icon,
                                iconColor: _iconColor,
                                enabled: widget.category.enabled ?? true,
                                unfiltered: widget.category.unfiltered ?? true,
                                orderIndex: widget.category.orderIndex ??
                                    widget.numExistingCategories,
                                uid: _user.uid,
                              );
                              setState(() => isLoading = true);
                              isEditMode
                                  ? await DatabaseWrapper(_user.uid)
                                      .updateCategories([category])
                                  : await DatabaseWrapper(_user.uid)
                                      .addCategories([category]);
                              SyncService(_user.uid).syncPeriods();
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
          )
        : Container();
  }

  Widget title(bool isEditMode) {
    return Text(isEditMode ? 'Edit Category' : 'Add Category');
  }
}

class CategoryColorPicker extends StatefulWidget {
  final Color currentColor;

  const CategoryColorPicker({Key key, this.currentColor}) : super(key: key);

  @override
  State<CategoryColorPicker> createState() => _CategoryColorPickerState();
}

class _CategoryColorPickerState extends State<CategoryColorPicker> {
  Color screenPickerColor;

  // Color for the picker in a dialog using onChanged.
  Color dialogPickerColor;

  // Color for picker using the color select dialog.
  Color dialogSelectColor;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    screenPickerColor = widget.currentColor; // Material blue.
    dialogPickerColor = widget.currentColor; // Material red.
    dialogSelectColor = widget.currentColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Icon Color Picker'),
      ),
      body: Container(
        padding: formPadding,
        child: Column(
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Card(
                  elevation: 2,
                  child: ColorPicker(
                    // Use the screenPickerColor as start color.
                    color: screenPickerColor,
                    // Update the screenPickerColor using the callback.
                    onColorChanged: (Color color) =>
                        setState(() => screenPickerColor = color),
                    width: 44,
                    height: 44,
                    borderRadius: 22,
                    heading: Text(
                      'Select color',
                      style: Theme.of(context).textTheme.headline5,
                    ),
                    subheading: Text(
                      'Select color shade',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                ),
              ),
            ),
            RaisedButton(
              color: Theme.of(context).primaryColor,
              child: Text(
                'Select',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () => Navigator.of(context).pop(screenPickerColor),
            )
          ],
        ),
      ),
    );
  }
}

extension on TextEditingController {
  void safeClear() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      this.clear();
    });
  }
}
