/* Copyright 2018-2021 The MathWorks, Inc. */

define([
    'dojo/_base/declare',
    'dijit/_WidgetBase',
    'mw-dialogs/Dialogs',
    'mw-dialogs/ButtonEnum',
    'mw-form/TextField',
    './IconComboBox',
    'mw-form/CheckBox',
    'dojo/i18n!../l10n/nls/favcommands',
    'mw-mvm/UserMvm',
    'mw-mvm/RunOptions',
    'mw-log/Log'
], function (declare, _WidgetBase, Dialogs, ButtonEnum, TextField, IconComboBox, CheckBox,
    favcommandsL10n, UserMVM, RunOptions, Log) {
    var executeInMatlab = function (category) {
        var mvm, evalPromise;

        mvm = UserMVM.getMVM();
        evalPromise = mvm.eval(category.code, new RunOptions());

        evalPromise.then(function (successMessage) {
            // do nothing
        }, function (error) {
            Log.warn('Failed to execute eval request in CategoryEditorModule with the error: ' + error);
        });
    };

    return declare([_WidgetBase], {
        constructor: function (args) {
            this.categoryActionsModule = args.categoryActionsModule;
            this.categoryWidget = args.widget;
            this.galleryPopupId = args.galleryPopupId;
            this.uiBuilder = args.uiBuilder;

            this._renderForm(args);
        },

        _renderForm: function (categoryData) {
            // SETUP
            var contentArea = document.createElement('div');
            var labelContainerNode = document.createElement('div');
            var iconContainerNode = document.createElement('div');
            var addToQABContainerNode = document.createElement('div');
            var showLabelOnQABContainerNode = document.createElement('div');
            var categoryLabelLabel;
            var categoryIconLabel;
            // var categoryIconButtonNodeKeydownListener;
            // var categoryIconButtonNode;
            // var categoryIconFileChooserNode;
            var categoryAddQabLabel;
            var categoryShowQabLabel;

            contentArea.classList.add('mwCategoryEditorContents');
            labelContainerNode.classList.add('mwCategoryEditorLayoutRow');
            iconContainerNode.classList.add('mwCategoryEditorLayoutRow');
            addToQABContainerNode.classList.add('mwCategoryEditorLayoutRow');
            showLabelOnQABContainerNode.classList.add('mwCategoryEditorLayoutRow');

            // FAVORITE COMMAND "LABEL"
            categoryLabelLabel = document.createElement('div');
            categoryLabelLabel.textContent = favcommandsL10n.favoriteCommandsLabelLabel;
            categoryLabelLabel.classList.add('mwCategoryEditorLabel');
            categoryLabelLabel.classList.add('mwDefaultVisualFamily');
            categoryLabelLabel.classList.add('mwWidget');
            labelContainerNode.appendChild(categoryLabelLabel);

            this.categoryLabel = new TextField({ tag: 'favoriteCategoryLabel' });
            this.categoryLabel.startup();
            this.categoryLabel.domNode.classList.add('mwCategoryEditorControl');
            this.categoryLabel.domNode.classList.add('mwCategoryEditorExpandToFit');
            this.categoryLabel.domNode.classList.add('mwCategoryLabel');
            labelContainerNode.appendChild(this.categoryLabel.domNode);

            // FAVORITE COMMAND "ICON"
            categoryIconLabel = document.createElement('div');
            categoryIconLabel.textContent = favcommandsL10n.favoriteCommandsIconLabel;
            categoryIconLabel.classList.add('mwCategoryEditorLabel');
            categoryIconLabel.classList.add('mwDefaultVisualFamily');
            categoryIconLabel.classList.add('mwWidget');
            iconContainerNode.appendChild(categoryIconLabel);
            var items = this._generateItemList();
            this.categoryIcon = new IconComboBox({
                editable: false,
                items: items,
                value: 'icon_favorite_category_16'
            });
            this.categoryIcon.resize = function () { /* No op */ };
            this.categoryIcon._setWidthAttr = function () { /* No op */ };
            this.categoryIcon.menu.onOpen = function () {
                this.menu.domNode.style.width = this.domNode.getBoundingClientRect().width - 2 + 'px';
            }.bind(this.categoryIcon);
            this.categoryIcon.startup();
            this.categoryIcon.textFieldContainerNode.style.width = 'calc(100% - 22px)';
            this.categoryIcon._textField.domNode.style.width = '100%';
            this.categoryIcon.domNode.classList.add('mwCategoryEditorControl');
            this.categoryIcon.domNode.classList.add('mwCategoryEditorExpandToFit');
            this.categoryIcon.domNode.classList.add('mwCategoryIcon');
            iconContainerNode.appendChild(this.categoryIcon.domNode);

            // categoryIconButtonNodeKeydownListener = function (e) {
            //     // TODO: Determine if we should respond to 'Enter' [keyCode = 13]
            //     if ((e.keyCode === 32)) { // Space
            //         e.target.click();
            //     }
            // };
            // categoryIconButtonNode = document.createElement("label");
            // categoryIconButtonNode.textContent = favcommandsL10n.favoriteCommandsIconButtonLabel;
            // categoryIconButtonNode.classList.add("mwCategoryEditorControl");
            // categoryIconButtonNode.classList.add("mwCategoryIconButton");
            // categoryIconButtonNode.setAttribute("for", "icon-file-input");
            // categoryIconButtonNode.setAttribute("tabindex", "0");
            // categoryIconButtonNode.addEventListener("keydown", categoryIconButtonNodeKeydownListener);
            // iconContainerNode.appendChild(categoryIconButtonNode);

            // categoryIconFileChooserNode = document.createElement("input");
            // categoryIconFileChooserNode.setAttribute("id", "icon-file-input");
            // categoryIconFileChooserNode.setAttribute("type", "file");
            // categoryIconFileChooserNode.classList.add("mwCategoryIconFileChooser");
            // categoryIconFileChooserNode.setAttribute("accept", "image/*");
            // iconContainerNode.appendChild(categoryIconFileChooserNode);

            // FAVORITE COMMAND "ADD TO QAB"
            categoryAddQabLabel = document.createElement('div');
            categoryAddQabLabel.classList.add('mwCategoryEditorLabel');
            categoryAddQabLabel.classList.add('mwDefaultVisualFamily');
            categoryAddQabLabel.classList.add('mwWidget');
            addToQABContainerNode.appendChild(categoryAddQabLabel);

            this.categoryAddQab = new CheckBox({
                text: favcommandsL10n.addToQABCheckBoxLabel
            });
            this.categoryAddQab.startup();
            this.categoryAddQab.domNode.classList.add('mwCategoryEditorControl');
            this.categoryAddQab.domNode.classList.add('mwCategoryAddQab');
            addToQABContainerNode.appendChild(this.categoryAddQab.domNode);

            // FAVORITE COMMAND "SHOW LABEL ON QAB"
            categoryShowQabLabel = document.createElement('div');
            categoryShowQabLabel.classList.add('mwCategoryEditorLabel');
            categoryShowQabLabel.classList.add('mwDefaultVisualFamily');
            categoryShowQabLabel.classList.add('mwWidget');
            showLabelOnQABContainerNode.appendChild(categoryShowQabLabel);

            this.categoryShowQab = new CheckBox({
                text: favcommandsL10n.showLabelInQABCheckBoxLabel
            });
            this.categoryShowQab.startup();
            this.categoryShowQab.domNode.classList.add('mwCategoryEditorControl');
            this.categoryShowQab.domNode.classList.add('mwCategoryShowQab');
            showLabelOnQABContainerNode.appendChild(this.categoryShowQab.domNode);

            // UPDATE FORM DATA
            this._populateForm(categoryData);

            // BUILD DIALOG
            contentArea.appendChild(labelContainerNode);
            contentArea.appendChild(iconContainerNode);
            contentArea.appendChild(addToQABContainerNode);
            contentArea.appendChild(showLabelOnQABContainerNode);

            if (this._dialog) {
                this._dialog.destroy();
            }

            this._dialog = Dialogs.createDialog({
                title: favcommandsL10n.categoryEditorTitle,
                className: 'exampleDialog',
                dialogType: Dialogs.MODAL,
                closeOnEscape: true,
                closable: true,
                draggable: true,
                resizable: true,
                'data-test-id': 'favoriteCategoryEditor',
                content: contentArea,
                buttons: [
                    ButtonEnum.SAVE,
                    ButtonEnum.CANCEL,
                    ButtonEnum.HELP
                ],
                defaultActionButton: ButtonEnum.SAVE
            });

            // HANDLE DIALOG ACTIONS
            // this._dialog.on("close", function () {
            //     categoryIconButtonNode.removeEventListener("keydown", categoryIconButtonNodeKeydownListener);

            //     delete this._dialog;
            // }.bind(this));

            this._dialog.addButtonEventListener(ButtonEnum.SAVE, function () {
                this._saveDialogContents();
            }.bind(this), true);

            this._dialog.addButtonEventListener(ButtonEnum.CANCEL, function () { /* No op */ }, true);

            this._dialog.addButtonEventListener(ButtonEnum.HELP, function () {
                executeInMatlab({ code: "helpview([docroot '/mapfiles/matlab_env.map'], 'matlab_favorites');" });
            }, false);

            this.categoryAddQab.on('change', function () {
                // Only enable the "Show label in QAB" checkbox when "Add to QAB" checkbox is checked, otherwise, it
                // should be disabled.
                this.categoryShowQab.set('disabled', !this.categoryAddQab.get('checked'));
            }.bind(this));

            // SETUP CLEANUP
            this.own(
                this.categoryLabel,
                this.categoryIcon,
                this.categoryAddQab,
                this.categoryShowQab,
                this._dialog
            );
        },

        _generateItemList: function () {
            var alphabet = 'abcdefghijklmnopqrstuvwxyz';
            var numbers = '0123456789';
            var items = [
                {
                    label: favcommandsL10n.favoriteCategoryIconComboBoxLabel,
                    value: 'icon_favorite_category_16',
                    icon: 'icon_favorite_category_16'
                },
                {
                    label: favcommandsL10n.matlabIconComboBoxLabel,
                    value: 'icon_matlab_category_16',
                    icon: 'icon_matlab_category_16'
                },
                {
                    label: favcommandsL10n.simulinkIconComboBoxLabel,
                    value: 'icon_simulink_category_16',
                    icon: 'icon_simulink_category_16'
                },
                {
                    label: favcommandsL10n.helpIconComboBoxLabel,
                    value: 'icon_help_category_16',
                    icon: 'icon_help_category_16'
                }
            ];
            for (var i = 0; i < alphabet.length; i++) {
                var temp = {
                    label: 'Upper Case ' + alphabet.charAt(i).toUpperCase(),
                    value: 'fav_category_' + alphabet.charAt(i),
                    icon: 'fav_category_' + alphabet.charAt(i)
                };
                items.push(temp);
            }
            for (var t = 0; t < alphabet.length; t++) {
                var tempLower = {
                    label: 'Lower Case ' + alphabet.charAt(t),
                    value: 'fav_category_lower_case_' + alphabet.charAt(t),
                    icon: 'fav_category_lower_case_' + alphabet.charAt(t)
                };
                items.push(tempLower);
            }
            for (var k = 0; k < numbers.length; k++) {
                var tempNumber = {
                    label: 'Number ' + numbers.charAt(k),
                    value: 'fav_category_' + numbers.charAt(k),
                    icon: 'fav_category_' + numbers.charAt(k)
                };
                items.push(tempNumber);
            }
            return items;
        },

        _saveDialogContents: function () {
            var item = {};

            item.label = this.categoryLabel.get('value').trim();
            item.title = item.label;
            item.icon = this.categoryIcon.get('icon');
            item.quickAccessIcon = item.icon;
            item.isInQAB = this.categoryAddQab.get('checked');
            item.showText = this.categoryShowQab.get('checked');
            // Setting the parentId allows the QAB control to be added
            item.galleryPopupId = item.parentId = this.galleryPopupId;

            // Update categoryWidget only if its not undefined, since
            // categoryActionsModule.updateCategory expects categoryWidget
            // to be undefined for a new category being created

            if (this.categoryWidget) {
                item.tag = this.categoryWidget.id;
                Object.assign(this.categoryWidget, item);
            }

            this.categoryActionsModule.updateCategory(item);
        },

        _populateForm: function (categoryData) {
            if (categoryData.title && typeof categoryData.title === 'string') {
                this.categoryLabel.set('value', categoryData.title);
            }
            if (categoryData.icon && typeof categoryData.icon === 'string') {
                this.categoryIcon.set('value', categoryData.icon);
            }
            if (categoryData.isInQAB && typeof categoryData.isInQAB === 'boolean') {
                this.categoryAddQab.set('checked', categoryData.isInQAB);

                var tag = categoryData.tag;
                if (tag.indexOf('_qab') < 0) {
                    tag = tag + '_qab';
                }

                var correspondingQABWidget = this.uiBuilder.widgetByTag(tag);
                if (correspondingQABWidget) {
                    var showTextValue = correspondingQABWidget.get('showText');
                    if (typeof showTextValue === 'boolean') {
                        this.categoryShowQab.set('checked', showTextValue);
                    }
                }
            } else {
                this.categoryShowQab.set('disabled', true);
            }
        },

        close: function () {
            if (this._dialog) {
                this._dialog.close();
            }
        },

        destroy: function () {
            if (this._dialog) {
                this._dialog.destroy();
            }
        }
    });
});
