/*
    Copyright 2020-2024 The MathWorks, Inc.
*/

define('preprocessing/variableBrowser/variableBrowser', [
    'mw-messageservice/MessageService',
    'mw-form/ContextMenu',
    'mw-log/Log',
    'variableeditor_peer/UIVariableEditor'
], function (MessageService, ContextMenu, Log, UIVariableEditor) {
    'use strict';

    class VariableBrowser {
        constructor (appID) {
            this._appID = appID;
            this._channel = '/DataCleaner/VariableBrowser/PubSubPaging_' + this._appID;
            this._ID_NAME = 'preprocessingVariableBrowser';
            this._CLASS_NAME = 'variableBrowser';
            this._DISABLED_CLASS_NAME = 'dc-variablebrowser-disabled';
            this._UIVE_ATTACH_POINT_CLASS = 'dc-variablebrowser-attach-point';
            this._UIVETableClassName = '.mw-table';

            this._UIVE = null;
            this._contextMenu = null;
            this._deleteRowItem = null;
            this._renameRowItem = null;

            this.SERVER_MESSAGE_TYPES = {
                SRV_MSG_SET_BUSY: 1,
                SRV_MSG_SET_FREE: 2,
                SRV_MSG_CREATE_UIVE: 3,
                SRV_MSG_SET_SELECTION: 6
            };

            this.CLIENT_MESSAGE_TYPES = {
                CLIENT_MSG_USER_INTERACTION: 4
            };

            this.CONTEXT_MENU_ACTIONS = {
                DELETE: 'DeleteAction',
                RENAME: 'RenameAction'
            };
        }

        startup () {
            this.parentElement = null;
            MessageService.subscribe(this._channel, this._handleServerMessage, this);
        }

        // Separated for unit testing.
        _createContextMenuInstance () {
            return new ContextMenu();
        }

        _createContextMenuFn () {
            // TODO: Don't show context menu for row representing table
            // TODO: Disable delete option if only one table column remains
            // ---------------------

            const contextMenu = this._createContextMenuInstance();

            // Grab the UIVariableEditor context menu items for scalar structs, take the "delete" and
            // "rename" actions, and embed them into our context menu.
            // Uncomment this code block post-IDR.
            const structContextMenuItems = this._UIVE.getContextMenuItems('ScalarStructContext');
            for (const item of structContextMenuItems) {
                if (item.tag === this.CONTEXT_MENU_ACTIONS.DELETE) {
                    contextMenu.addChild(item);
                    this._deleteRowItem = item;
                }
                if (item.tag === this.CONTEXT_MENU_ACTIONS.RENAME) {
                    contextMenu.addChild(item);
                    this._renameRowItem = item;
                }
            }

            // We assume that the delete item and the rename item will always be found.

            // We tell the delete and rename items that they should not have their enabled/disabled
            // state synced up with the MATLAB server. We do this because, in some circumstances,
            // the rename item will be re-enabled even though we want it disabled.
            //
            // We disable syncing for the delete item too just in case.
            this._deleteRowItem.shouldSyncEnabledStateWithServer = () => false;
            this._renameRowItem.shouldSyncEnabledStateWithServer = () => false;

            return contextMenu;
        }

        // Separated for unit test mocking.
        _instantiateUIVariableEditor (UUID, WidgetContainerId) {
            const UIVEArguments = {
                UUID,
                WidgetContainerId,
                ResizeBehaviour: 'container'
            };

            return new UIVariableEditor(UIVEArguments);
        }

        /**
         * Set up the UIVariableEditor's context menu to display the options "delete" and "rename".
         *
         * Although the Variable Editor has a built-in context menu, the Data Cleaner only needs
         * to show a subset of the options offered for scalar structs (just delete and rename).
         * Because the Variable Editor doesn't offer easy context menu customizability for its
         * consumers, we manually change some of its behavior.
         *
         * @param {Object} UIVE The UIVariableEditor to attach our custom context menu creation to
         * @param {String} attachPointClass The class name for the element we attach our context menu to
         */
        _setUpUIVEContextMenu (UIVE, attachPointClass) {
            // Part 1: Have the Variable Editor create our own custom context menu.
            UIVE.setContextMenuCreationCallbackFn(() => {
                this._contextMenu = this._createContextMenuFn();

                // g3294377: We disable deleting/renaming imported tables, since we currently
                // only support those actions for table variables.
                //
                // We dynamically enable/disable the delete/rename context menu items by taking
                // advantage of the UIVariableEditor's "ContextMenusPrepopulation" event.
                UIVE.setContextMenuPrepopulationListener(_contextMenuProvider => {
                    // Get the right clicked row's hierarchical level. We must manually grab
                    // it from the UIVariableEditor; it is not passed in with the event data.
                    const rowLevel = this.getHighlightedRowProperty(UIVE, 'level');
                    // If the row is a table, we disable the context menu items; otherwise,
                    // if the row is a column/nested table/etc., we enable the items.
                    this._deleteRowItem._setDisabledAttr(rowLevel === 0);
                    this._renameRowItem._setDisabledAttr(rowLevel === 0);
                });
            });

            // Part 2: Set up context menu open listener.
            const popoutNode = document.getElementsByClassName(attachPointClass)[0];
            popoutNode.addEventListener('contextmenu', e => {
                // Because we implement our own custom context menu and add it to the _entire_
                // Variable Editor panel, we must ensure the context menu only appears if the
                // user is right clicking on the table.
                // Otherwise, if they click on the whitespace below the table, we do nothing.
                const tableElement = e.target.closest(this._UIVETableClassName);
                if (tableElement == null) return;

                this._contextMenu?.openMenu({
                    x: e.clientX,
                    y: e.clientY
                });
            });
        }

        attachUIVEToDom (UUID) {
            const parentNotNullishAssertion = this.parentElement != null;
            let assertMsg = 'Cannot attach UIVariableEditor to nonexistent parent';
            Log.assert(parentNotNullishAssertion, assertMsg);
            if (!parentNotNullishAssertion) return;

            const parentInDOMAssertion = document.body.contains(this.parentElement);
            assertMsg = 'Cannot attach Variable Browser to DOM since the parent element is not in the DOM';
            Log.assert(parentInDOMAssertion, assertMsg);
            if (!parentInDOMAssertion) return;

            const UIVENotNullishAssertion = this._UIVE == null;
            assertMsg = 'A UIVariableEditor should not already exist; "attachUIVEToDom" should be called only once';
            Log.assert(UIVENotNullishAssertion, assertMsg);
            if (!UIVENotNullishAssertion) return;
            // End assertions -------------------

            const UIVEAttachPoint = document.createElement('div');
            UIVEAttachPoint.id = `VariableBrowser_${this._appID}`;
            UIVEAttachPoint.classList.add(this._UIVE_ATTACH_POINT_CLASS);
            this.parentElement.appendChild(UIVEAttachPoint);

            this._UIVE = this._instantiateUIVariableEditor(UUID, UIVEAttachPoint.id);
            this._setUpUIVEContextMenu(this._UIVE, this._UIVE_ATTACH_POINT_CLASS);
        }

        /**
         * Get the currently highlighted row's property from the given UIVariableEditor.
         *
         * @param {Object} UIVE The UIVariableEditor to get the row property from
         * @param {String} rowProperty The name of the property to get from the row
         * @returns The highlighted row's property
         */
        getHighlightedRowProperty (UIVE, rowProperty) {
            const w = UIVE.widget;

            const selectedRowID = w.getSelection()[0].id;
            const rowNum = w._activeView.getDataStore()._getIndexFromRowID(selectedRowID);
            const rowLevel = w._activeView.getMetaDataStore().getRowModelProperty(rowProperty, rowNum);

            return rowLevel;
        }

        setSelectionOnUIVE (message) {
            this._UIVE.widget._activeView._table.setSelection([{ id: message }]);
        }

        async _handleServerMessage (message) {
            const types = this.SERVER_MESSAGE_TYPES;
            switch (message.data.type) {
                case types.SRV_MSG_SET_BUSY:
                    // TODO: As the Variable Browser loads, make it busy.
                    break;
                case types.SRV_MSG_SET_FREE:
                    // TODO: Used after the Variable Browser finishes loading.
                    // this._setFree();
                    break;
                case types.SRV_MSG_CREATE_UIVE:
                    this.attachUIVEToDom(message.data.uuid);
                    break;
                case types.SRV_MSG_SET_SELECTION:
                    this.setSelectionOnUIVE(message.data.rowId);
                    break;
                default:
                    throw new Error(`Variable Browser panel received message type value of ${message.data.type}; no function exists to handle it`);
            }
        }

        _setBusy () {
            // TODO
        }

        _setDisabled () {
            // TODO
        }

        destroy () {
            MessageService.unsubscribe(this._channel, this._handleServerMessage, this);

            this._contextMenu?.destroy();
            this._UIVE?.destroy();
            this._UIVE = null;
        }
    }

    return VariableBrowser;
});
