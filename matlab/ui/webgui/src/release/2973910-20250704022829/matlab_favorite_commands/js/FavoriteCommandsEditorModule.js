// Copyright 2018-2021 The MathWorks, Inc.

define([
    'dojo/_base/declare',
    'dijit/registry',
    'dijit/_WidgetBase',
    'mw-dialogs/Dialogs',
    'mw-dialogs/ButtonEnum',
    'mw-form/TextField',
    'mw-form/ComboBox',
    './IconComboBox',
    'mw-form/CheckBox',
    'dojo/i18n!../l10n/nls/favcommands',
    'rtc/RichTextComponentFactory',
    'rtc/RichTextComponentFeatureEnum',
    'rtc/clipboardservice/ClipboardService',
    './FavoriteCommandsEditorPluginRegistry',
    'mw-mvm/UserMvm',
    'mw-mvm/RunOptions',
    'mw-log/Log',
    'settings/settingsService'
], function (
    declare,
    registry,
    _WidgetBase,
    Dialogs,
    ButtonEnum,
    TextField,
    ComboBox,
    ComboBoxIcon,
    CheckBox,
    favcommandsL10n,
    RichTextComponentFactory,
    RichTextComponentFeatureEnum,
    ClipboardService,
    FavoriteCommandsEditorPluginRegistry,
    UserMVM,
    RunOptions,
    Log,
    settingsService
) {
    const executeInMatlab = function (favorite) {
        const mvm = UserMVM.getMVM();
        const evalPromise = mvm.eval(favorite.code, new RunOptions());

        evalPromise.then(function (successMessage) {
            // do nothing
        }, function (error) {
            Log.warn('Failed to execute eval request in FavoriteCommandsEditorModule with the error: ' + error);
        });
    };
    const clipboard = ClipboardService.getBrowserSyncedClipboard();

    return declare([_WidgetBase], {
        constructor: function (args) {
            this.action = args.favoriteAction;
            this.favoriteActions = args.favoriteAction.favoriteActionsModule;
            this.categoryActions = args.favoriteAction.categoryActionsModule;
            this.uiBuilder = args.uiBuilder;

            this._renderForm(args.favoriteAction);
        },

        _renderForm: function (favoriteAction) {
            // SETUP
            const contentArea = document.createElement('div');
            const labelContainerNode = document.createElement('div');
            const codeContainerNode = document.createElement('div');
            const categoryContainerNode = document.createElement('div');
            const iconContainerNode = document.createElement('div');
            const addToQABContainerNode = document.createElement('div');
            const showLabelOnQABContainerNode = document.createElement('div');
            const keyboardTrapLabelContainerNode = document.createElement('div');
            let favoriteCodeWrapperFocusListener;
            let favoriteCodeWrapperBlurListener;
            let favoriteCodeWrapperKeyDownListener;
            let favoriteCodeKeyCaptureFocusListener;
            let favoriteCodeKeyCaptureBlurListener;
            let favoriteCodeKeyCaptureKeyDownListener;
            let favoriteCodeKeyCaptureNode;
            let favoriteCategoryLabel;
            let favoriteIconLabel;
            // eslint-disable-next-line no-unused-vars
            let favoriteIconButtonNodeKeydownListener;
            // eslint-disable-next-line no-unused-vars
            let favoriteIconButtonNode;
            // eslint-disable-next-line no-unused-vars
            let favoriteIconFileChooserNode;
            let favoriteAddQabLabel;
            let favoriteShowQabLabel;

            contentArea.classList.add('mwFavoriteCommandsEditorContents');
            labelContainerNode.classList.add('mwFavoritesEditorLayoutRow');
            codeContainerNode.classList.add('mwFavoritesEditorLayoutRow');
            codeContainerNode.classList.add('mwFavoritesEditorCodeContainer');
            categoryContainerNode.classList.add('mwFavoritesEditorLayoutRow');
            keyboardTrapLabelContainerNode.classList.add('mwFavoritesEditorLayoutRow');
            iconContainerNode.classList.add('mwFavoritesEditorLayoutRow');
            addToQABContainerNode.classList.add('mwFavoritesEditorLayoutRow');
            showLabelOnQABContainerNode.classList.add('mwFavoritesEditorLayoutRow');

            // FAVORITE COMMAND "LABEL"
            const favoriteLabelLabel = document.createElement('div');
            favoriteLabelLabel.textContent = favcommandsL10n.favoriteCommandsLabelLabel;
            favoriteLabelLabel.classList.add('mwFavoritesEditorLabel');
            favoriteLabelLabel.classList.add('mwDefaultVisualFamily');
            favoriteLabelLabel.classList.add('mwWidget');
            labelContainerNode.appendChild(favoriteLabelLabel);

            this.favoriteLabel = new TextField({
                placeholder: favcommandsL10n.favoriteCommandsLabelPlaceholder,
                tag: 'favoriteLabel'
            });
            this.favoriteLabel.startup();
            this.favoriteLabel.domNode.classList.add('mwFavoritesEditorControl');
            this.favoriteLabel.domNode.classList.add('mwFavoritesEditorExpandToFit');
            this.favoriteLabel.domNode.classList.add('mwFavoriteLabel');
            labelContainerNode.appendChild(this.favoriteLabel.domNode);

            // FAVORITE COMMAND "CODE"
            const favoriteCodeLabel = document.createElement('div');
            favoriteCodeLabel.textContent = favcommandsL10n.favoriteCommandsCodeLabel;
            favoriteCodeLabel.classList.add('mwFavoritesEditorLabel');
            favoriteCodeLabel.classList.add('mwDefaultVisualFamily');
            favoriteCodeLabel.classList.add('mwWidget');
            codeContainerNode.appendChild(favoriteCodeLabel);

            const favoriteCodeWrapper = document.createElement('div');
            favoriteCodeWrapper.classList.add('mwFavoriteCodeWrapper');
            favoriteCodeWrapper.classList.add('mwFavoritesEditorControl');
            favoriteCodeWrapper.classList.add('mwFavoritesEditorExpandToFit');
            favoriteCodeWrapper.setAttribute('tabindex', '-1');
            codeContainerNode.appendChild(favoriteCodeWrapper);

            // FAVORITE COMMAND "Keyboard Trap Label"
            const dummyLabel = document.createElement('div');
            dummyLabel.classList.add('mwFavoritesEditorLabel');
            dummyLabel.classList.add('mwDefaultVisualFamily');
            dummyLabel.classList.add('mwWidget');
            keyboardTrapLabelContainerNode.appendChild(dummyLabel);

            const keyboardTrapLabel = document.createElement('div');
            keyboardTrapLabel.classList.add('mwFavoritesEditorLabel');
            keyboardTrapLabel.classList.add('mwDefaultVisualFamily');
            keyboardTrapLabel.classList.add('mwWidget');
            keyboardTrapLabel.classList.add('mwFavoritesEditorExpandToFit');
            keyboardTrapLabel.classList.add('mwFavoritesEditorControl');
            keyboardTrapLabel.classList.add('keyboardTrapLabel');
            keyboardTrapLabel.setAttribute('aria-hidden', 'true');
            keyboardTrapLabel.textContent = favcommandsL10n.favoriteCommandsKeyboardTrapLabel;
            keyboardTrapLabelContainerNode.appendChild(keyboardTrapLabel);

            const rtcArgs = {
                registry: FavoriteCommandsEditorPluginRegistry.plugins,
                features: [
                    RichTextComponentFeatureEnum.CODE_ANALYZER,
                    RichTextComponentFeatureEnum.SYNTAX_HIGHLIGHTING,
                    RichTextComponentFeatureEnum.AUTO_COMPLETION,
                    RichTextComponentFeatureEnum.PAREN_MATCH,
                    RichTextComponentFeatureEnum.CONTEXT_MENU,
                    RichTextComponentFeatureEnum.AUTO_INDENT,
                    RichTextComponentFeatureEnum.VARIABLE_HIGHLIGHTING,
                    RichTextComponentFeatureEnum.FORMAT_CODE,
                    RichTextComponentFeatureEnum.SMART_TAB,
                    RichTextComponentFeatureEnum.SECTIONS.INSERT_SECTION_ACTION,
                    RichTextComponentFeatureEnum.SECTIONS.NEXT_SECTION_ACTION,
                    RichTextComponentFeatureEnum.SECTIONS.PREVIOUS_SECTION_ACTION,
                    RichTextComponentFeatureEnum.FIND_STRING,
                    RichTextComponentFeatureEnum.INDENT_ON_NEWLINE,
                    RichTextComponentFeatureEnum.COMMENT,
                    RichTextComponentFeatureEnum.INDENT,
                    RichTextComponentFeatureEnum.UNDO_REDO,
                    RichTextComponentFeatureEnum.CUT_COPY_PASTE
                ],
                dependencies: {
                    'rtc.settings.backingservice': settingsService
                },
                enabled: [
                    'fe.contextmenu.model',
                    'rtc.backgroundforegroundcolor'
                ],
                clipboard: clipboard
            };

            RichTextComponentFactory.createRTC(rtcArgs).then(function (rtcInstance) {
                this.favoriteCode = rtcInstance;
                favoriteCodeWrapper.appendChild(this.favoriteCode.domNode);

                this.favoriteCode.blur(); // For some reason the RTC widget thinks it has focus when created
                this.favoriteCode.getDocument().setText('% ' + favcommandsL10n.favoriteCommandsCodePlaceholder + '\n');
                this.favoriteCode.domNode.classList.add('mwFavoriteCode');
                this.favoriteCode.domNode.setAttribute('data-test-id', 'favoriteCode');
                favoriteCodeWrapper.appendChild(this.favoriteCode.domNode);

                favoriteCodeWrapperFocusListener = function () {
                    favoriteCodeWrapper.classList.add('mwFocused');
                };
                favoriteCodeWrapperBlurListener = function () {
                    favoriteCodeWrapper.classList.remove('mwFocused');
                };
                favoriteCodeWrapperKeyDownListener = function (e) {
                    if (e.keyCode === 9) { // Tab
                        if (!e.shiftKey) {
                            e.preventDefault();
                            this.favoriteCategory.focus();
                        }
                    }
                }.bind(this);
                favoriteCodeWrapper.addEventListener('focus', favoriteCodeWrapperFocusListener);
                favoriteCodeWrapper.addEventListener('blur', favoriteCodeWrapperBlurListener);
                favoriteCodeWrapper.addEventListener('keydown', favoriteCodeWrapperKeyDownListener);

                favoriteCodeKeyCaptureNode = this.favoriteCode.domNode.getElementsByClassName('keyCapture')[0];
                favoriteCodeKeyCaptureNode.setAttribute('aria-label', favcommandsL10n.codeKeyboardTrapLabel);
                favoriteCodeKeyCaptureFocusListener = function () {
                    favoriteCodeWrapper.classList.add('mwFocusedWithin');
                };
                favoriteCodeKeyCaptureBlurListener = function () {
                    favoriteCodeWrapper.classList.remove('mwFocusedWithin');
                    this.favoriteCode.blur();
                }.bind(this);
                favoriteCodeKeyCaptureKeyDownListener = function (e) {
                    if (e.keyCode === 27) { // Escape
                        favoriteCodeWrapper.focus();
                    }
                };
                favoriteCodeKeyCaptureNode.addEventListener('focus', favoriteCodeKeyCaptureFocusListener);
                favoriteCodeKeyCaptureNode.addEventListener('blur', favoriteCodeKeyCaptureBlurListener);
                favoriteCodeKeyCaptureNode.addEventListener('keydown', favoriteCodeKeyCaptureKeyDownListener);

                // FAVORITE COMMAND "CATEGORY"
                favoriteCategoryLabel = document.createElement('div');
                favoriteCategoryLabel.textContent = favcommandsL10n.favoriteCommandsCategoryLabel;
                favoriteCategoryLabel.classList.add('mwFavoritesEditorLabel');
                favoriteCategoryLabel.classList.add('mwDefaultVisualFamily');
                favoriteCategoryLabel.classList.add('mwWidget');
                categoryContainerNode.appendChild(favoriteCategoryLabel);

                const categories = this.categoryActions.getCategoriesArrayForComboBox();
                this.favoriteCategory = new ComboBox({
                    editable: true,
                    items: categories,
                    tag: 'favoriteCategory',
                    value: categories[0].value
                });
                this.favoriteCategory.resize = function () { /* No op */ };
                this.favoriteCategory._setWidthAttr = function () { /* No op */ };
                this.favoriteCategory.menu.onOpen = function () {
                    this.menu.domNode.style.width = this.domNode.getBoundingClientRect().width - 2 + 'px';
                }.bind(this.favoriteCategory);
                this.favoriteCategory.startup();
                this.favoriteCategory.textFieldContainerNode.style.width = 'calc(100% - 22px)';
                this.favoriteCategory._textField.domNode.style.width = '100%';
                this.favoriteCategory.domNode.classList.add('mwFavoritesEditorControl');
                this.favoriteCategory.domNode.classList.add('mwFavoritesEditorExpandToFit');
                this.favoriteCategory.domNode.classList.add('mwFavoriteCategory');
                categoryContainerNode.appendChild(this.favoriteCategory.domNode);

                // FAVORITE COMMAND "ICON"
                favoriteIconLabel = document.createElement('div');
                favoriteIconLabel.textContent = favcommandsL10n.favoriteCommandsIconLabel;
                favoriteIconLabel.classList.add('mwFavoritesEditorLabel');
                favoriteIconLabel.classList.add('mwDefaultVisualFamily');
                favoriteIconLabel.classList.add('mwWidget');
                iconContainerNode.appendChild(favoriteIconLabel);
                const items = this._generateItemList();
                this.favoriteIcon = new ComboBoxIcon({
                    editable: false,
                    items: items,
                    value: 'icon_favorite_command_16',
                    tag: 'iconComboBox'
                });
                this.favoriteIcon.resize = function () { /* No op */ };
                this.favoriteIcon._setWidthAttr = function () { /* No op */ };
                this.favoriteIcon.menu.onOpen = function () {
                    this.menu.domNode.style.width = this.domNode.getBoundingClientRect().width - 2 + 'px';
                }.bind(this.favoriteIcon);
                this.favoriteIcon.startup();
                this.favoriteIcon.textFieldContainerNode.style.width = 'calc(100% - 22px)';
                this.favoriteIcon._textField.domNode.style.width = '100%';
                this.favoriteIcon.domNode.classList.add('mwFavoritesEditorControl');
                this.favoriteIcon.domNode.classList.add('mwFavoritesEditorExpandToFit');
                this.favoriteIcon.domNode.classList.add('mwFavoriteIcon');
                iconContainerNode.appendChild(this.favoriteIcon.domNode);

                favoriteIconButtonNodeKeydownListener = function (e) {
                    // TODO: Determine if we should respond to 'Enter' [keyCode = 13]
                    if ((e.keyCode === 32)) { // Space
                        e.target.click();
                    }
                };
                // favoriteIconButtonNode = document.createElement("label");
                // favoriteIconButtonNode.textContent = favcommandsL10n.favoriteCommandsIconButtonLabel;
                // favoriteIconButtonNode.classList.add("mwFavoritesEditorControl");
                // favoriteIconButtonNode.classList.add("mwFavoriteIconButton");
                // favoriteIconButtonNode.setAttribute("for", "icon-file-input");
                // favoriteIconButtonNode.setAttribute("tabindex", "0");
                // favoriteIconButtonNode.addEventListener("keydown", favoriteIconButtonNodeKeydownListener);
                // iconContainerNode.appendChild(favoriteIconButtonNode);

                // favoriteIconFileChooserNode = document.createElement("input");
                // favoriteIconFileChooserNode.setAttribute("id", "icon-file-input");
                // favoriteIconFileChooserNode.setAttribute("type", "file");
                // favoriteIconFileChooserNode.classList.add("mwFavoriteIconFileChooser");
                // favoriteIconFileChooserNode.setAttribute("accept", "image/*");
                // iconContainerNode.appendChild(favoriteIconFileChooserNode);

                // FAVORITE COMMAND "ADD TO QAB"
                favoriteAddQabLabel = document.createElement('div');
                favoriteAddQabLabel.classList.add('mwFavoritesEditorLabel');
                favoriteAddQabLabel.classList.add('mwDefaultVisualFamily');
                favoriteAddQabLabel.classList.add('mwWidget');
                addToQABContainerNode.appendChild(favoriteAddQabLabel);

                this.favoriteAddQab = new CheckBox({
                    text: favcommandsL10n.addToQABCheckBoxLabel
                });
                this.favoriteAddQab.startup();
                this.favoriteAddQab.domNode.classList.add('mwFavoritesEditorControl');
                this.favoriteAddQab.domNode.classList.add('mwFavoriteAddQab');
                addToQABContainerNode.appendChild(this.favoriteAddQab.domNode);

                // FAVORITE COMMAND "SHOW LABEL ON QAB"
                favoriteShowQabLabel = document.createElement('div');
                favoriteShowQabLabel.classList.add('mwFavoritesEditorLabel');
                favoriteShowQabLabel.classList.add('mwDefaultVisualFamily');
                favoriteShowQabLabel.classList.add('mwWidget');
                showLabelOnQABContainerNode.appendChild(favoriteShowQabLabel);

                this.favoriteShowQab = new CheckBox({
                    text: favcommandsL10n.showLabelInQABCheckBoxLabel
                });
                this.favoriteShowQab.startup();
                this.favoriteShowQab.domNode.classList.add('mwFavoritesEditorControl');
                this.favoriteShowQab.domNode.classList.add('mwFavoriteShowQab');
                showLabelOnQABContainerNode.appendChild(this.favoriteShowQab.domNode);

                this.own(this.favoriteAddQab.on('change', function (evt) {
                    // Only enable the "Show label in QAB" checkbox when "Add to QAB" checkbox is checked, otherwise, it
                    // should be disabled.
                    if (evt.mwEventData.propertyName === 'checked') {
                        this.favoriteShowQab.set('disabled', !evt.mwEventData.newValue);
                    }
                }.bind(this)));

                // UPDATE FORM DATA
                this._populateForm(favoriteAction);

                // BUILD DIALOG
                contentArea.appendChild(labelContainerNode);
                contentArea.appendChild(codeContainerNode);
                contentArea.appendChild(keyboardTrapLabelContainerNode);
                contentArea.appendChild(categoryContainerNode);
                contentArea.appendChild(iconContainerNode);
                contentArea.appendChild(addToQABContainerNode);
                contentArea.appendChild(showLabelOnQABContainerNode);

                if (this._dialog) {
                    this._dialog.destroy();
                }

                this._dialog = Dialogs.createDialog({
                    title: favcommandsL10n.favoriteCommandsEditorTitle,
                    className: 'exampleDialog',
                    dialogType: Dialogs.MODAL,
                    closeOnEscape: true,
                    closable: true,
                    draggable: true,
                    resizable: true,
                    'data-test-id': 'favoriteCommandsEditor',
                    content: contentArea,
                    buttons: [
                        {
                            type: ButtonEnum.TYPE.SPL1,
                            label: favcommandsL10n.favoriteCommandsTestButtonLabel,
                            'data-test-id': 'TestButton'
                        },
                        ButtonEnum.SAVE,
                        ButtonEnum.CANCEL,
                        ButtonEnum.HELP
                    ],
                    defaultActionButton: ButtonEnum.SAVE
                });

                // HANDLE DIALOG ACTIONS
                this._dialog.on('close', function () {
                    favoriteCodeWrapper.removeEventListener('focus', favoriteCodeWrapperFocusListener);
                    favoriteCodeWrapper.removeEventListener('blur', favoriteCodeWrapperBlurListener);
                    favoriteCodeWrapper.removeEventListener('keydown', favoriteCodeWrapperKeyDownListener);
                    favoriteCodeKeyCaptureNode.removeEventListener('focus', favoriteCodeKeyCaptureFocusListener);
                    favoriteCodeKeyCaptureNode.removeEventListener('blur', favoriteCodeKeyCaptureBlurListener);
                    favoriteCodeKeyCaptureNode.removeEventListener('keydown', favoriteCodeKeyCaptureKeyDownListener);
                    // favoriteIconButtonNode.removeEventListener("keydown", favoriteIconButtonNodeKeydownListener);

                    this.favoriteLabel.inputNode.removeEventListener('keydown', toggleSaveButton);
                    this.favoriteCode.domNode.querySelector('textarea').removeEventListener('keydown', toggleSaveButton, true);
                    this.favoriteCategory.inputNode.removeEventListener('keydown', toggleSaveButton);

                    this.favoriteCode.destroy();

                    delete this._dialog;
                }.bind(this));

                // g2523286: Resize RTC widget (for code block) when the dialog is resized
                this._dialog.on('resize', () => {
                    this.favoriteCode.resize();
                });

                this._dialog.addButtonEventListener(ButtonEnum.TYPE.SPL1, function () {
                    executeInMatlab({ code: this.favoriteCode.getDocument().getText() });
                }.bind(this), false);

                this._dialog.addButtonEventListener(ButtonEnum.SAVE, function () {
                    this._saveDialogContents();
                }.bind(this), true);

                this._dialog.addButtonEventListener(ButtonEnum.CANCEL, function () { /* No op */ }, true);

                this._dialog.addButtonEventListener(ButtonEnum.HELP, function () {
                    executeInMatlab({ code: "helpview([docroot '/mapfiles/matlab_env.map'], 'matlab_favorites');" });
                }, false);

                const toggleSaveButton = function () {
                    // Use setTimeout to allow text to update in TextField before checking value
                    setTimeout(function () {
                        if (this._dialog) { // if the dialog still exists
                            if ((this.favoriteCode.getDocument().getText().trim() ||
                                    this.favoriteLabel.inputNode.value.trim()) &&
                                this.favoriteCategory.inputNode.value.trim()) {
                                this._dialog.enableButton(ButtonEnum.SAVE);
                            } else {
                                this._dialog.disableButton(ButtonEnum.SAVE);
                            }
                        }
                    }.bind(this), 0);
                }.bind(this);

                this.favoriteLabel.inputNode.addEventListener('keydown', toggleSaveButton);
                this.favoriteCode.domNode.querySelector('textarea').addEventListener('keydown', toggleSaveButton, true);
                this.favoriteCategory.inputNode.addEventListener('keydown', toggleSaveButton);

                // SETUP CLEANUP
                this.own(
                    this.favoriteLabel,
                    this.favoriteCode,
                    this.favoriteCategory,
                    this.favoriteIcon,
                    this.favoriteAddQab,
                    this.favoriteShowQab,
                    this._dialog
                );

                this.favoriteCode.startup();
            }.bind(this));
        },

        _generateItemList: function () {
            const alphabet = 'abcdefghijklmnopqrstuvwxyz';
            const numbers = '0123456789';
            const items = [
                {
                    label: favcommandsL10n.favoriteCommandsIconComboBoxLabel,
                    value: 'icon_favorite_command_16',
                    icon: 'icon_favorite_command_16'
                },
                {
                    label: favcommandsL10n.matlabIconComboBoxLabel,
                    value: 'icon_matlab_favorite_16',
                    icon: 'icon_matlab_favorite_16'
                },
                {
                    label: favcommandsL10n.simulinkIconComboBoxLabel,
                    value: 'icon_simulink_favorite_16',
                    icon: 'icon_simulink_favorite_16'
                },
                {
                    label: favcommandsL10n.helpIconComboBoxLabel,
                    value: 'icon_help_favorite_16',
                    icon: 'icon_help_favorite_16'
                }
            ];
            for (let i = 0; i < alphabet.length; i++) {
                const temp = {
                    label: 'Upper Case ' + alphabet.charAt(i).toUpperCase(),
                    value: 'fav_command_' + alphabet.charAt(i),
                    icon: 'fav_command_' + alphabet.charAt(i)
                };
                items.push(temp);
            }
            for (let t = 0; t < alphabet.length; t++) {
                const tempLower = {
                    label: 'Lower Case ' + alphabet.charAt(t),
                    value: 'fav_command_lower_case_' + alphabet.charAt(t),
                    icon: 'fav_command_lower_case_' + alphabet.charAt(t)
                };
                items.push(tempLower);
            }
            for (let k = 0; k < numbers.length; k++) {
                const tempNumber = {
                    label: 'Number ' + numbers.charAt(k),
                    value: 'fav_command_' + numbers.charAt(k),
                    icon: 'fav_command_' + numbers.charAt(k)
                };
                items.push(tempNumber);
            }
            return items;
        },

        _saveDialogContents: async function () {
            const itemData = {};

            itemData.label = this.favoriteLabel.get('value');
            itemData.code = this.favoriteCode.getDocument().getText();
            itemData.parentTag = this.favoriteCategory.get('value');
            itemData.parentId = this.uiBuilder.tagToId(itemData.parentTag);
            // TODO: may want to move this behavior outside of the dialog and back to actions file
            if (!itemData.parentId) {
                itemData.parentId = this.categoryActions.createCategory({ title: itemData.parentTag });
                itemData.parentTag = this.categoryActions.tagFromId(itemData.parentId);
            }
            itemData.icon = this.favoriteIcon.get('icon');
            itemData.quickAccessIcon = itemData.icon;
            itemData.isInQAB = this.favoriteAddQab.get('checked');
            itemData.showText = this.favoriteShowQab.get('checked');

            if (this.action.isEditing) {
                itemData.tag = this.action.tag;
                itemData.text = itemData.label || itemData.code || '';
                await this.favoriteActions.updateFavorite(this.action.favoriteId, itemData);
            } else {
                await this.favoriteActions.createFavorite(itemData);
            }
        },

        _populateForm: function (favoriteAction) {
            if (favoriteAction.label && typeof favoriteAction.label === 'string') {
                this.favoriteLabel.set('value', favoriteAction.label);
            }
            if (favoriteAction.code && typeof favoriteAction.code === 'string') {
                this.favoriteCode.getDocument().setText(favoriteAction.code);
            }
            const categoryWidget = favoriteAction.parent || registry.byId(favoriteAction.parentId);
            if (categoryWidget && categoryWidget.title && typeof categoryWidget.title === 'string') {
                this.favoriteCategory.set('value', categoryWidget.tag);
            }
            if (favoriteAction.icon && typeof favoriteAction.icon === 'string') {
                this.favoriteIcon.set('value', favoriteAction.icon);
            }
            if (favoriteAction.isInQAB && typeof favoriteAction.isInQAB === 'boolean') {
                this.favoriteAddQab.set('checked', favoriteAction.isInQAB);

                let tag = favoriteAction.tag;
                if (tag.indexOf('_qab') < 0) {
                    tag = tag + '_qab';
                }

                const correspondingQABWidget = this.uiBuilder.widgetByTag(tag);
                if (correspondingQABWidget) {
                    const showTextValue = correspondingQABWidget.get('showText');
                    if (typeof showTextValue === 'boolean') {
                        this.favoriteShowQab.set('checked', showTextValue);
                    }
                }
            } else {
                this.favoriteShowQab.set('disabled', true);
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
