/* Copyright 2023-2024 The MathWorks, Inc. */
define('preprocessing/toolstrip/Toolstrip', [
    'preprocessing/toolstrip/ToolstripTabConfig',
    'preprocessing/toolstrip/ToolstripPopupConfig',
    'preprocessing/toolstrip/ToolstripTags',
    'mw-messageservice/MessageService',
    'MW/uiframework/uicontainer/DocumentTypeProperties',
    'dojo/i18n!preprocessing/l10n/nls/Toolstrip'
], function (ToolstripTabConfig, ToolstripPopupConfig, ToolstripTags, MessageService,
    DocumentTypeProperties, toolstripl10n) {
    'use strict';

    class Toolstrip {
        constructor (appID, container, _initializeAppCallbackFn) {
            this._appID = appID;
            this._container = container;
            this._itemsToggled = false;
            this._documentCount = 0;
            this._channel = '/DataCleaner/Toolstrip/PubSubPaging_' + this._appID;

            // beforeOpenItemFn: A callback function which executes immediately
            // after the user clicks on a gallery item, and before the item is
            // opened.
            //
            // It should be asynchronous, and it should return:
            // - "true" to indicate the task should continue being opened
            // - "false" to indicate the task should not be opened
            this.beforeOpenItemFn = null;
            this.openGalleryItemCallback = null;

            this.SERVER_MESSAGE_TYPES = {
                SRV_MSG_TOOLSTRIP_ENABLED: 1,
                SRV_GALLERY_ITEM_ADDED: 2,
                SRV_GALLERY_CATEGORY_ADDED: 3,
                SRV_GALLERY_ITEM_REMOVED: 4,
                SRV_MSG_IMPORT_OPEN_BUTTONS_ENABLED: 20
            };

            this.CLIENT_MESSAGE_TYPES = {
                IMPORT_VARIABLE: 5,
                IMPORT_FROM_FILE: 6,
                OPEN_SESSION: 7,
                SAVE_SESSION: 8,
                SAVE_AS_SESSION: 9,
                SHOW_SUMMARY_CHECKBOX_TOGGLED: 10,
                SHOW_LEGEND_CHECKBOX_TOGGLED: 11,
                EXPORT_DATA: 12,
                EXPORT_SCRIPT: 13,
                EXPORT_FUNCTION: 14,
                OPEN_HELP: 15,
                OPEN_TASK: 16
            };

            this.TASKS = {
                CLEAN_MISSING: {
                    ID: 1,
                    name: toolstripl10n.CleanMissing
                },
                CLEAN_OUTLIER: {
                    ID: 2,
                    name: toolstripl10n.CleanOutlier
                },
                NORMALIZE: {
                    ID: 3,
                    name: toolstripl10n.Normalize
                },
                SMOOTH: {
                    ID: 4,
                    name: toolstripl10n.Smooth
                },
                RETIME: {
                    ID: 5,
                    name: toolstripl10n.Retime
                },
                STACK: {
                    ID: 6,
                    name: toolstripl10n.Stack
                },
                UNSTACK: {
                    ID: 7,
                    name: toolstripl10n.Unstack
                },
                JOIN: {
                    ID: 8,
                    name: toolstripl10n.Join
                },
                SYNCHRONIZE: {
                    ID: 9,
                    name: toolstripl10n.Synchronize
                }
            };

            MessageService.subscribe(this._channel, this._handleServerMessage, this);
        }

        buildToolstrip () {
            if (!this._container) {
                throw new Error('Cannot build Toolstrip when container is:', this._container);
            }

            this._container.loadActions(this._getToolstripActionsList());
            this._container.loadActions(this._getGalleryActionsList());
            this._configureToolstrip();
            this._registerDocumentTypes();
        }

        _sendToolbarMessage (eventType, data) {
            // "data" is optional.
            const message = data != null ? { eventType, data } : { eventType };
            MessageService.publish(this._channel, message);
        }

        async _sendTaskMessage (task) {
            const doOpenTask = this.beforeOpenItemFn != null
                ? await this.beforeOpenItemFn()
                : true;

            if (!doOpenTask) return;

            const eventType = this.CLIENT_MESSAGE_TYPES.OPEN_TASK;
            const message = { eventType, taskID: task.ID };
            MessageService.publish(this._channel, message);

            // Let the Preprocessing App know that we sent a task message.
            // The app will expand the TaskController panel.
            if (this.openGalleryItemCallback) {
                this.openGalleryItemCallback(task.name);
            }
        }

        sendImportVariableMessage () {
            this._sendToolbarMessage(this.CLIENT_MESSAGE_TYPES.IMPORT_VARIABLE);
        }

        _getImportActions () {
            const importCb = () => { this.sendImportVariableMessage(); };
            const importFromFileCb = () => { this._sendToolbarMessage(this.CLIENT_MESSAGE_TYPES.IMPORT_FROM_FILE); };
            const openSessionCb = () => { this._sendToolbarMessage(this.CLIENT_MESSAGE_TYPES.OPEN_SESSION); };

            const actionsList = [
                {
                    id: 'import',
                    enabled: true,
                    text: toolstripl10n.Import,
                    icon: 'import_data',
                    callback: importCb.bind(this)
                },
                {
                    id: 'import_from_workspace',
                    enabled: true,
                    text: toolstripl10n.ImportFromWorkspace,
                    icon: 'import_data',
                    callback: importCb.bind(this)
                },
                {
                    id: 'import_from_file',
                    enabled: true,
                    text: toolstripl10n.ImportFromFile,
                    icon: 'import_dataC',
                    callback: importFromFileCb.bind(this)
                },
                {
                    id: 'open_session',
                    enabled: true,
                    text: toolstripl10n.Open,
                    icon: 'openFolder',
                    callback: openSessionCb.bind(this)
                }
            ];

            return actionsList;
        }

        _getImportExportActions () {
            const coreActions = this._getImportActions();

            const saveSessionCb = () => { this._sendToolbarMessage(this.CLIENT_MESSAGE_TYPES.SAVE_SESSION); };
            const saveAsSessionCb = () => { this._sendToolbarMessage(this.CLIENT_MESSAGE_TYPES.SAVE_AS_SESSION); };
            const exportDataCb = () => { this._sendToolbarMessage(this.CLIENT_MESSAGE_TYPES.EXPORT_DATA); };
            const exportScriptCb = () => { this._sendToolbarMessage(this.CLIENT_MESSAGE_TYPES.EXPORT_SCRIPT); };
            const exportFunctionCb = () => { this._sendToolbarMessage(this.CLIENT_MESSAGE_TYPES.EXPORT_FUNCTION); };

            const actionsList = [
                {
                    id: 'save_session',
                    enabled: false,
                    text: toolstripl10n.Save,
                    icon: 'saved',
                    callback: saveSessionCb.bind(this)
                },
                {
                    id: 'save_as_session',
                    enabled: false,
                    text: toolstripl10n.SaveAs,
                    icon: 'saveAs',
                    callback: saveAsSessionCb.bind(this)
                },
                {
                    id: 'export_data',
                    enabled: false,
                    text: toolstripl10n.ExportData,
                    icon: 'export_data',
                    callback: exportDataCb.bind(this)
                },
                {
                    id: 'export_data_to_workspace',
                    enabled: false,
                    text: toolstripl10n.ExportToWorkspace,
                    icon: 'export_data',
                    callback: exportDataCb.bind(this)
                },
                {
                    id: 'export_script',
                    enabled: false,
                    text: toolstripl10n.GenerateScript,
                    icon: 'saveAs',
                    callback: exportScriptCb.bind(this)
                },
                {
                    id: 'export_function',
                    enabled: false,
                    text: toolstripl10n.GenerateFunction,
                    icon: 'saveAs',
                    callback: exportFunctionCb.bind(this)
                }
            ];

            return coreActions.concat(actionsList);
        }

        _getToolstripActionsList () {
            const fileSectionActions = this._getImportExportActions();

            const actionsList = [
                {
                    id: 'toggle_legend',
                    enabled: false,
                    text: toolstripl10n.ShowLegend
                },
                {
                    id: 'toggle_summary',
                    enabled: false,
                    text: toolstripl10n.ShowSummary
                }
            ];

            return fileSectionActions.concat(actionsList);
        }

        _getGalleryActionsList () {
            const cleanMissingFn = () => this._sendTaskMessage(this.TASKS.CLEAN_MISSING);
            const cleanOutlierFn = () => this._sendTaskMessage(this.TASKS.CLEAN_OUTLIER);
            const normalizeFn = () => this._sendTaskMessage(this.TASKS.NORMALIZE);
            const smoothFn = () => this._sendTaskMessage(this.TASKS.SMOOTH);
            const retimeFn = () => this._sendTaskMessage(this.TASKS.RETIME);
            const stackFn = () => this._sendTaskMessage(this.TASKS.STACK);
            const unstackFn = () => this._sendTaskMessage(this.TASKS.UNSTACK);
            const joinFn = () => this._sendTaskMessage(this.TASKS.JOIN);
            const synchronizeFn = () => this._sendTaskMessage(this.TASKS.SYNCHRONIZE);

            const actionsList = [
                {
                    id: 'cleanMissing',
                    enabled: false,
                    text: toolstripl10n.CleanMissing,
                    icon: 'cleanMissingDataApp',
                    callback: cleanMissingFn.bind(this)
                },
                {
                    id: 'cleanOutlier',
                    enabled: false,
                    text: toolstripl10n.CleanOutlier,
                    icon: 'cleanOutlierDataApp',
                    callback: cleanOutlierFn.bind(this)
                },
                {
                    id: 'normalize',
                    enabled: false,
                    text: toolstripl10n.Normalize,
                    icon: 'normalizeDataApp',
                    callback: normalizeFn.bind(this)
                },
                {
                    id: 'smooth',
                    enabled: false,
                    text: toolstripl10n.Smooth,
                    icon: 'smoothDataApp',
                    callback: smoothFn.bind(this)
                },
                {
                    id: 'retime',
                    enabled: false,
                    text: toolstripl10n.Retime,
                    icon: 'retimeTimetableApp',
                    callback: retimeFn.bind(this)
                },
                {
                    id: 'stack',
                    enabled: false,
                    text: toolstripl10n.Stack,
                    icon: 'stackTableVariablesApp',
                    callback: stackFn.bind(this)
                },
                {
                    id: 'unstack',
                    enabled: false,
                    text: toolstripl10n.Unstack,
                    icon: 'unstackTableVariablesApp',
                    callback: unstackFn.bind(this)
                }/*,
                {
                    id: 'join',
                    enabled: false,
                    text: toolstripl10n.Join,
                    icon: 'joinTableApp',
                    callback: joinFn.bind(this)
                },
                {
                    id: 'synchronize',
                    enabled: false,
                    text: toolstripl10n.Synchronize,
                    icon: 'syncronizeTimetableApp',
                    callback: synchronizeFn.bind(this)
                }
                */
            ];

            return actionsList;
        }

        // Enable the toolstrip after the server indicates that a variable has successfully loaded.
        // This function goes through each toolstrip and gallery action we defined and enables them.
        setToolstripState (enabled) {
            const toolstripActions = this._getToolstripActionsList();
            const galleryActions = this._getGalleryActionsList();

            for (const key in toolstripActions) {
                const action = toolstripActions[key];
                this._container.actionService.updateAction(action.id, { enabled });
            }

            for (const key in galleryActions) {
                const action = galleryActions[key];
                this._container.actionService.updateAction(action.id, { enabled });
            }
        }

        /**
         * Disables all cleaning-related elements within the toolstrip, like the cleaning gallery,
         * checkboxes, saving, etc.
         */
        _enableImportToolstripElements (enabled) {
            const importActions = this._getImportActions();

            for (const key in importActions) {
                const action = importActions[key];
                this._container.actionService.updateAction(action.id, { enabled });
            }
        }

        enableFileAndTaskElements (enabled) {
            const importExportActions = this._getImportExportActions();
            const galleryActions = this._getGalleryActionsList();

            for (const key in importExportActions) {
                const action = importExportActions[key];
                this._container.actionService.updateAction(action.id, { enabled });
            }

            for (const key in galleryActions) {
                const action = galleryActions[key];
                this._container.actionService.updateAction(action.id, { enabled });
            }
        }

        _configureToolstrip () {
            const uiBuilder = this._container.uiBuilder;

            const setUpToolstrip = () => {
                this._container.addTabGroup([ToolstripTabConfig.getConfiguration(), ToolstripPopupConfig.getConfiguration()]);
            };

            const setUpCheckboxActions = () => {
                const checkboxCallback = (checked, messageType) => {
                    const messageData = checked;
                    this._sendToolbarMessage(messageType, messageData);
                };

                const summaryCheckbox = uiBuilder.tagToId('pa_ui.home.view.checkboxColumn.cb1');
                uiBuilder.addPropertySetCallback(summaryCheckbox, event => {
                    checkboxCallback(event.newValue, this.CLIENT_MESSAGE_TYPES.SHOW_SUMMARY_CHECKBOX_TOGGLED);
                });

                const legendCheckbox = uiBuilder.tagToId('pa_ui.home.view.checkboxColumn.cb2');
                uiBuilder.addPropertySetCallback(legendCheckbox, event => {
                    checkboxCallback(event.newValue, this.CLIENT_MESSAGE_TYPES.SHOW_LEGEND_CHECKBOX_TOGGLED);
                });
            };

            const setUpHelpButton = () => {
                // Set up the help button in the Quick Access Bar.
                // The hierarchy is: Toolstrip QAB => QAB Group => QAB Help Button
                const QABId = this._container.toolstrip.QABId;

                const QABGroupConfig = ToolstripTabConfig.getQABGroupConfig(QABId);
                const QABGroupId = uiBuilder.create(QABGroupConfig);

                const QABHelpButtonConfig = ToolstripTabConfig.getQABHelpButtonConfig(QABGroupId);
                const QABHelpButton = uiBuilder.create(QABHelpButtonConfig);

                uiBuilder.addEventCallback(QABHelpButton, data => {
                    if (data.eventType === 'buttonPushed') {
                        this._sendToolbarMessage(this.CLIENT_MESSAGE_TYPES.OPEN_HELP);
                    }
                });
            };

            setUpToolstrip();
            setUpCheckboxActions();
            setUpHelpButton();
        }

        _registerDocumentTypes () {
            const properties = new DocumentTypeProperties({
                title: toolstripl10n.DataExplorerTitle
            });
            this._container.registerDocumentType('data_explorer', properties);
        }

        /* Begin server message functions */

        _handleServerMessage (message) {
            const types = this.SERVER_MESSAGE_TYPES;
            switch (message.data.type) {
                case types.SRV_MSG_TOOLSTRIP_ENABLED:
                    this.setToolstripState(message.data.isEnabled);
                    break;
                case types.SRV_GALLERY_ITEM_ADDED:
                    this._addGalleryItem(message);
                    break;
                case types.SRV_GALLERY_CATEGORY_ADDED:
                    this._addGalleryCategory(message);
                    break;
                case types.SRV_GALLERY_ITEM_REMOVED:
                    this._removeGalleryItem(message);
                    break;
                case types.SRV_MSG_IMPORT_OPEN_BUTTONS_ENABLED:
                    this._enableImportToolstripElements(message.data.isEnabled);
                    break;
                default:
                    throw new Error(`Toolstrip received message type value of ${message.data.type}; no function exists to handle it`);
            }
        }

        _addGalleryItem (_message) {
            const uiBuilder = this._container.uiBuilder;

            if (this._itemsToggled) {
                // Rebuild the categories and tasks. We cannot recursively build the items from the
                // categories alone, so each item must be built individually.
                const gid = uiBuilder.tagToId(ToolstripTags.GALLERY_POPUP); // gid: Gallery ID

                const syncCatId = uiBuilder.create(ToolstripPopupConfig.getSyncCategoryConfig(gid));
                uiBuilder.create(ToolstripPopupConfig.getSyncItemConfig(syncCatId));

                const reshapeCatId = uiBuilder.create(ToolstripPopupConfig.getReshapeCategoryConfig(gid));
                uiBuilder.create(ToolstripPopupConfig.getStackItemConfig(reshapeCatId));
                uiBuilder.create(ToolstripPopupConfig.getUnstackItemConfig(reshapeCatId));

                this._itemsToggled = false;
            }
        }

        _addGalleryCategory (_message) {
            const uiBuilder = this._container.uiBuilder;
            const gid = uiBuilder.tagToId(ToolstripTags.GALLERY_POPUP); // gid: Gallery ID

            const debugCatId = uiBuilder.create(ToolstripPopupConfig.getDebugCategoryConfig(gid));
            uiBuilder.create(ToolstripPopupConfig.getDebugItemConfig(debugCatId));
        }

        _removeGalleryItem (_message) {
            const uiBuilder = this._container.uiBuilder;

            if (!this._itemsToggled) {
                const syncCategoryId = uiBuilder.tagToId(ToolstripTags.SYNC_CATEGORY);
                uiBuilder.destroy(syncCategoryId);

                const reshapeCategoryId = uiBuilder.tagToId(ToolstripTags.RESHAPE_CATEGORY);
                uiBuilder.destroy(reshapeCategoryId);

                this._itemsToggled = true;
            }
        }

        /* End server message functions */

        destroy () {
            MessageService.unsubscribe(this._channel, this._handleServerMessage, this);
        }
    }

    return Toolstrip;
});
