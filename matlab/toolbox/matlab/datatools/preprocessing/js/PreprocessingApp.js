/* Copyright 2023-2024 The MathWorks, Inc. */
define('preprocessing/PreprocessingApp', [
    'dijit/layout/ContentPane',
    'MW/uiframework/UIContainer',
    'MW/uiframework/uicontainer/ChildProperties',
    'MW/uiframework/uicontainer/DocumentTypeProperties',
    'mw-messageservice/MessageService',
    'mw-html-utils/HtmlUtils',
    // TODO: Find out why we must manually import VEFactory to make the Variable Editor
    // work in the app.
    //
    // g3266158: After a snap job in R2024b, the Variable Editor would fail to initialize
    // until after the user loaded up any DivFigure. This BP captures several tests
    // that failed as a result.
    //
    // The cause of the BP was that, when the VariableEditorPopoutHandlerWidget
    // tried dynamically requiring the VEFactory, the browser could not find its path.
    // The loading of a DivFigure properly allowed the browser to find the VEFactory
    // file, and afterward, any Variable Editor would properly initialize.
    //
    // We should try and find how to have the browser recognize the VEFactory file
    // without us manually importing VEFactory here.
    'variableeditor_peer/VEFactory',
    'preprocessing/history/history',
    'preprocessing/variableBrowser/variableBrowser',
    'preprocessing/toolstrip/Toolstrip',
    'preprocessing/dataExplorer/LayoutWidget',
    'preprocessing/dataExplorer/DataExplorer',
    'preprocessing/taskController/TaskController',
    'preprocessing/dataExplorer/FigureFactory',
    'preprocessing/dataExplorer/FigureViewCoordinator',
    'variableeditor_peer/UIVariableEditor',
    'mw-notifications/Notifications',
    'mw-overlay-utils/BusyOverlay',
    'dojo/i18n!preprocessing/l10n/nls/Toolstrip',
    'dojo/i18n!preprocessing/l10n/nls/PreprocessingApp',
    'mw-log/Log'
], function (ContentPane, UIContainer, ChildProperties, DocumentTypeProperties,
    MessageService, HtmlUtils, VEFactory, HistoryWidget, VariableBrowser, Toolstrip, LayoutWidget,
    DataExplorer, TaskController, FigureFactory, FigureViewCoordinator, UIVariableEditor,
    Notifications, BusyOverlay, toolstripl10n, appl10n, Log) {
    'use strict';

    const ENABLE_MULTIPLE_TABLE_SUPPORT = false;

    const BASE_CHANNEL = '/DataCleaner/PubSubPaging_';
    const SPLASH_SCREEN_PARENT_ID = 'dataCleaner_uiMain';

    const USER_DATA_TAB_GROUP = 'user_data_tab_group';
    const TASK_TAB_GROUP = 'task_tab_group';

    const SERVER_MESSAGE_TYPES = {
        SRV_MSG_SET_BUSY: 1,
        SRV_MSG_SET_FREE: 2,
        SRV_MSG_INIT_DATAEXPLORER: 3,
        SRV_MSG_INIT_TASK_VIEW_PLOT: 4,
        SRV_MSG_INIT_TASK_VIEW_DATA: 5,
        SRV_MSG_CLOSE_CLEANING_TAB: 6,
        SRV_MSG_CLOSE_DATAEXPLORER: 7,
        SRV_MSG_SET_CLEANING_TAB_TITLE: 8,
        SRV_MSG_RENAME_VE_TASK_TITLE: 9,
        SRV_MSG_SELECTION_CHANGED: 15,
        // Any time the MATLAB server updates the "UnsavedChanges" property to "true" or "false",
        // it will send a message to us so we're constantly in sync.
        SRV_MSG_SET_UNSAVED_CHANGE_VALUE: 16
    };

    const CLIENT_MESSAGE_TYPES = {
        CLIENT_MSG_SELECTION_CHANGED: 12
    };

    const PANEL_TYPES = {
        CONTAINER: 10,
        PLOT_VIEW: 11
    };

    class PreprocessingApp {
        constructor () {
            const uriParams = HtmlUtils.parseQueryString();
            this.appID = uriParams.appid;

            const container = this._createContainer();

            const toolstrip = new Toolstrip(this.appID, container);
            toolstrip.buildToolstrip();
            toolstrip.beforeOpenItemFn = this._displayCancelTaskDialogIfTaskOpen.bind(this);
            toolstrip.openGalleryItemCallback = this._toolstripGalleryItemOpened.bind(this);

            // We must access the figure factory to load necessary figure CSS.
            this._figureFactory = new FigureFactory();

            // TODO: Set these variables to their respective widgets while the panels
            // are added, and properly delete them in "disconnectedCallback()".
            this._variableBrowser = null;
            this._historyPanel = null;
            this._taskPanel = null;
            this._inspectorContentPanelProps = null;
            this._taskController = null;
            this._historyWidget = null;

            this.dataExplorerBusyIndicator = null;
            this._dataExplorers = [];
            this._containerTabs = [];

            this._addPanels(container);
            this.container = container;
            this._toolstrip = toolstrip;

            this.taskInputViewContainer = null;
            this.taskOutputViewContainer = null;
            this._taskVisualizations = [];

            this._unsavedChanges = false;

            const that = this;
            this.shutdownCallback = () => {
                that.disconnectedCallback();
            };

            MessageService.subscribe(this._getFullChannelName(), this._martialServerMessage, this);
        }

        /**
         * Create the UIContainer for the app. This is what gives the app the toolstrip,
         * panels, etc.
         * @returns The UIContainer
         */
        _createContainer () {
            const container = new UIContainer('dataCleaner_ui', {
                title: appl10n.AppTitle,
                hasMnemonics: true,
                reserveDocumentSpace: true,
                showSingleDocumentTab: true,
                hasToolstrip: true,
                userDocumentTilingEnabled: false,
                enableTheming: true,
                product: 'MATLAB',
                scope: 'Data Cleaner'
            });
            // Add a "close approver" to the app, meaning that when the user attempts to close the app,
            // the passed in function will be executed. It will then accept or veto the close attempt.
            container.addCloseApprover(this._displayAppCloseDialog.bind(this));

            // Register "tab groups". When we create tabs (whenever the user imports a table or launches
            // a cleaning task), it will be put into one of these two groups.
            const userDataGroupProperties = new DocumentTypeProperties({
                title: appl10n.VariableTabGroupName
            });
            const taskGroupProperties = new DocumentTypeProperties({
                title: appl10n.CleaningTaskTabGroupName
            });
            container.registerDocumentType(USER_DATA_TAB_GROUP, userDataGroupProperties);
            container.registerDocumentType(TASK_TAB_GROUP, taskGroupProperties);

            return container;
        }

        _getFullChannelName () {
            return `${BASE_CHANNEL}${this.appID}`;
        }

        _cleanUpDestroyedDataExplorers () {
            this._dataExplorers = this._dataExplorers.filter(de => !de.isDestroyed());
        }

        /**
         * If a cleaning task is open, show a confirmation dialog to the user to ask if they're sure
         * they wish to cancel the current cleaning task.
         *
         * @returns Whether the user has accepted cancelling the current task (e.g., clicked "Yes")
         */
        _displayCancelTaskDialogIfTaskOpen () {
            return new Promise(resolve => {
                if (!this.cleaningTaskIsOpen()) {
                    resolve(true);
                    return;
                }

                Notifications.displayConfirmDialog(appl10n.AppTitle, appl10n.TaskCancelConfirmText, {
                    buttonText: [appl10n.YesButtonText, appl10n.CancelButtonText],
                    closeCallback: event => {
                        const userSelectedYes = event.response === 1;
                        resolve(userSelectedYes);
                    }
                });
            });
        }

        // Display the confirmation dialog asking if users are sure they want to close the app.
        // This dialog will only be displayed when there are any unsaved changes.
        // Due to UIContainer quirks, we must reject the promise if we want to veto closing the app,
        // rather than doing a "resolve(false)".
        _displayAppCloseDialog () {
            return new Promise((resolve, reject) => {
                if (!this._unsavedChanges) {
                    resolve(true);
                    return;
                }

                Notifications.displayConfirmDialog(appl10n.AppTitle, appl10n.AppCancelConfirmText, {
                    buttonText: [appl10n.YesButtonText, appl10n.CancelButtonText],
                    closeCallback: event => {
                        const userSelectedYes = event.response === 1;
                        if (userSelectedYes) resolve(true);
                        else reject(new Error('User chose not to close app'));
                    }
                });
            });
        }

        /**
         * Define and return the callback function for when the document is resized,
         * like when the user resizes the app window.
         * @returns The pane resize callback function
         */
        _paneResizeCallbackFn (_dynamicPropertyName, oldValue, newValue) {
            // When a Data Explorer is resized, it will trigger this callback again.
            // To avoid recursion, we check if the new size value matches the old
            // size value. If it does, we don't return and don't notify children.
            const oldNewTruthy = oldValue && newValue;
            const oldNewEqual = oldNewTruthy && JSON.stringify(oldValue) === JSON.stringify(newValue);
            if (oldNewEqual) return;
            // ---------------------

            // TODO: Find a better area to stop keeping track of destroyed Data Explorers.
            // It doesn't make sense to do it here.
            this._cleanUpDestroyedDataExplorers();

            // Resize any existing Data Explorers...
            this._dataExplorers.forEach(de => {
                de.updateComplete.then(() => {
                    de.notifyPaneResize();
                });
            });

            // ...and resize any existing task views.
            const resizeVisFn = vis => {
                const visParentNode = vis.getFigureParentNode();
                if (visParentNode == null) { // No longer in the DOM
                    return;
                }
                const contentWidget = visParentNode.parentNode;
                if (contentWidget == null) return;
                // Our task view is within a content widget. Due to mw-widget quirks, we must
                // first wait for the content widget to finish its DOM resizing, _then_
                // we can carry on resizing our view.
                // If we don't wait for content widget resizing, our task view will end up
                // too large or too small.
                contentWidget.updateComplete.then(() => { vis.handleResize(); });
            };
            this._taskVisualizations.forEach(vis => resizeVisFn(vis));
        }

        _handleFocusedTabChange (_dynamicPropertyName, _oldValue, newValue) {
            // Execute this callback when the tab is clicked on by the user.
            // We need an "isShowing" callback since not-shown tabs do not get their
            // innerBounds updated when the central pane is resized.
            if (!newValue) {
                // This assumes that tabs that are shown are set first. Hence, when the newValue is set to false, the tab that was showing earlier is hidden and only 1 tab will have isShowing = true.
                this._paneResizeCallbackFn();
                const docs = this.container.getDocuments();
                if (docs.length === 0) return;

                const selectedTableName = docs.filter(doc => doc.properties.isShowing)[0].properties.title;
                MessageService.publish(this._getFullChannelName(), { eventType: CLIENT_MESSAGE_TYPES.CLIENT_MSG_SELECTION_CHANGED, selectedTableName });
            }
        }

        /**
         * Set up a UIContainer document (the central panel of the app). In simpler terms,
         * this creates a tab. The tab/document houses DataExplorers and allows the user to
         * view plots, tabular data, and summary information.
         * @returns The Layout Widget to attach DataExplorers to.
         */
        _createCentralPanelTab (tabName, isCleaningTab) {
            const tab = new ContentPane({ content: '' });

            // Allow the user to cancel cleaning tasks by closing the cleaning tab
            // (enable all toolstrip elements).
            //
            // THIS CLEANUP FUNCTION IS OVERWRITTEN IF THE USER COMPLETES THE TASK BY
            // EITHER ACCEPTING OR CANCELLING THE TAB.
            //
            // It is not optimal, but since we cannot determine if a tab is closed
            // interactively or programmatically, we have no other choice but to
            // overwrite the cleanup function before programmatically closing the tab.
            const cleanupFn = isCleaningTab
                ? () => { this._handleTaskCompleted('cancel'); }
                : () => {};

            // There are two "tab groups", and we must determine which group this
            // new tab will belong to.
            const documentType = isCleaningTab
                ? TASK_TAB_GROUP
                : USER_DATA_TAB_GROUP;

            // For a cleaning tab, the updated title text will be received from the server
            // (see message type "SRV_MSG_SET_TAB_TITLE").
            // Otherwise, if it's a normal tab, give it its table name.
            const title = isCleaningTab && ENABLE_MULTIPLE_TABLE_SUPPORT === true
                ? appl10n.CleaningStepTabLoadingText
                : `${tabName}`;

            const tabProps = new ChildProperties({
                documentType,
                documentId: title,
                title,
                closable: isCleaningTab,
                cleanup: cleanupFn
            });

            // Execute a callback when the content pane resizes. This is used to
            // resize the DivFigure (if it exists) by sending a message to the server.
            tabProps.watch('innerBounds', this._paneResizeCallbackFn.bind(this));

            // Execute a callback when the central document  tab switches
            tabProps.watch('isShowing', this._handleFocusedTabChange.bind(this));

            // Add a Layout Widget so we can customize what the user sees on a task-to-task basis.
            const layoutWidget = this._createLayoutWidget();

            // Add the document (tab) to the app...
            tab.domNode.appendChild(layoutWidget);
            this.container.addDocument(tab, tabProps);

            // ...and add a busy overlay over it.
            this.dataExplorerBusyIndicator = new BusyOverlay(BusyOverlay.SIZE.MEDIUM);
            this.dataExplorerBusyIndicator.set('target', tab.domNode);

            return [tab, layoutWidget];
        }

        _renameCleaningTab (newTabTitle) {
            const cleaningTabs = this._containerTabs.filter(tab => {
                const props = this.container.getChildProperties(tab);
                return props?.closable || false;
            });

            Log.assert(cleaningTabs.length <= 1, 'There should only be 1 cleaning task open');

            if (cleaningTabs.length > 0) {
                const tabProps = this.container.getChildProperties(cleaningTabs[0]);
                tabProps.set('title', `${newTabTitle} *`);
            }
        }

        _setDataExplorerBusyIndicatorVisible (isBusy) {
            if (this.dataExplorerBusyIndicator) {
                if (isBusy) this.dataExplorerBusyIndicator.show();
                else this.dataExplorerBusyIndicator.hide();
            }
        }

        _handleBusyServerMessage (msg) {
            const types = SERVER_MESSAGE_TYPES;
            const isBusy = msg.data.type === types.SRV_MSG_SET_BUSY;

            const setContainerBusy = isBusy => {
                Log.assert(this.container != null, 'PreprocessingApp container should exist');
                this.container.set('isBusy', isBusy);
            };

            switch (msg.data.panel) {
                case PANEL_TYPES.CONTAINER:
                    setContainerBusy(isBusy);
                    break;
                case PANEL_TYPES.PLOT_VIEW:
                    this._setDataExplorerBusyIndicatorVisible(isBusy);
                    break;
                default: // Set everything the value of isBusy
                    setContainerBusy(isBusy);
                    this._setDataExplorerBusyIndicatorVisible(isBusy);
                    break;
            }
        }

        _getVariableEditorLayoutWidgetID (UUID) {
            return `ve_task_view_${UUID}`;
        }

        async _martialServerMessage (msg) {
            const types = SERVER_MESSAGE_TYPES;

            // If the message has no data or does not specify a type value, default the
            // behavior to setting everything free.
            if (msg?.data?.type == null) {
                msg.data = {
                    type: types.SRV_MSG_SET_FREE,
                    panel: 'all'
                };
            }

            // Anonymous function to get the "input" or "output" layout widget, depending
            // on whether "msg.type" is "input" or "output".
            const getViewLayoutWidget = type => {
                const layoutWidget = type === 'output'
                    ? this.taskOutputViewContainer
                    : this.taskInputViewContainer;

                if (layoutWidget == null) {
                    Log.assert(false, `Layout widget (type "${type}") does not exist; cannot add task view`);
                    return null;
                }

                return layoutWidget;
            };

            switch (msg.data.type) {
                case types.SRV_MSG_SET_BUSY:
                case types.SRV_MSG_SET_FREE: {
                    this._handleBusyServerMessage(msg);
                    break;
                }
                case types.SRV_MSG_INIT_DATAEXPLORER: {
                    this._hideSplashScreen();

                    // If we only support one table open at a time, close all existing documents
                    // before creating a new Data Explorer.
                    if (!ENABLE_MULTIPLE_TABLE_SUPPORT) {
                        const containerDocs = this.container.getDocuments();
                        containerDocs.forEach(doc => this.container.closeDocument(doc.widget));
                    }

                    const varID = msg.data.uuid;
                    const importedTableName = msg.data.varName;
                    this._createDataExplorer(varID, importedTableName);
                    break;
                }
                case types.SRV_MSG_INIT_TASK_VIEW_PLOT: {
                    // Create and get a reference to the element the plot will attach to...
                    const layoutWidget = getViewLayoutWidget(msg.data.ViewType);
                    if (layoutWidget == null) return;

                    let title = msg.data.Title;
                    if (title === '') title = null;
                    const testClass = 'PlotTaskView'; // Used for GUI testing
                    const attachPoint = await layoutWidget.addEmptyWidget({ title, contentBodyClass: testClass });

                    attachPoint.style.margin = '0px';
                    attachPoint.style.padding = '0px';
                    attachPoint.style.border = 'none';

                    // ...then create & attach the plot to the element.
                    const taskVizualization = this._createFigureViewCoordinator();
                    // After the DivFigure is created, we must resize it to its parent element's size.
                    const postFigureCreationFn = () => { taskVizualization.handleResize(); };
                    taskVizualization.createFigureView(attachPoint, msg.data.FigureInfo, postFigureCreationFn);

                    this._taskVisualizations.push(taskVizualization);
                    break;
                }
                case types.SRV_MSG_INIT_TASK_VIEW_DATA: {
                    // Create and get a reference to the element the UIVariableEditor will attach to...
                    const layoutWidget = getViewLayoutWidget(msg.data.ViewType);
                    if (layoutWidget == null) return;

                    let title = msg.data.Title;
                    let contentBodyStyle = 'width:100%;height:100%;';

                    if (title === '') title = null;
                    // If we're going to be showing a UIVariableEditor (UIVE) with a title, we must
                    // make the UIVE's parent's height a little shorter. Otherwise, the UIVE will
                    // extend past its widget.
                    if (title != null) contentBodyStyle = 'width:100%;height:calc(100% - 13px);';

                    const VEWidgetId = this._getVariableEditorLayoutWidgetID(msg.data.tableID);
                    const attachPoint = await layoutWidget.addEmptyWidget({ title, id: VEWidgetId, contentBodyStyle });

                    // ...then instantiate the UIVariableEditor.
                    const UIVEArguments = {
                        UUID: msg.data.tableID,
                        WidgetContainerId: attachPoint.bodyId,
                        ResizeBehaviour: 'container'
                    };
                    // eslint-disable-next-line no-unused-vars
                    const taskData = this._createUIVE(UIVEArguments);
                    break;
                }
                // If the user opens a task, but the server stops the task short, the server
                // must let us know so we can close the cleaning task we just opened.
                case types.SRV_MSG_CLOSE_CLEANING_TAB: {
                    this._handleTaskCompleted('cancel');
                    break;
                }
                case types.SRV_MSG_CLOSE_DATAEXPLORER: {
                    this._closeDataExplorer(msg.data.tableName);
                    break;
                }
                case types.SRV_MSG_SET_CLEANING_TAB_TITLE: {
                    this._renameCleaningTab(msg.data.title);
                    break;
                }
                case types.SRV_MSG_SELECTION_CHANGED: {
                    // Focus the correct document tab
                    this.container.getDocuments().filter(doc => doc.properties.title === msg.data.selection)[0].properties.set('isShowing', true);
                    break;
                }
                case types.SRV_MSG_RENAME_VE_TASK_TITLE: {
                    this._renameVariableEditorTaskView(msg.data.UUID, msg.data.title);
                    break;
                }
                case types.SRV_MSG_SET_UNSAVED_CHANGE_VALUE: {
                    // Take note whether there are any unsaved changes so that we can display a
                    // confirmation dialog to the user if they try closing the app.
                    this._unsavedChanges = msg.data.UnsavedChanges;
                    break;
                }
                default: {
                    throw new Error(`Data Cleaner received message type value of ${msg.data.type}; no function exists to handle it`);
                }
            }
        }

        _createDataExplorer (varID, importedTableName) {
            const isCleaningTab = false;
            const [tab, layoutWidget] = this._createCentralPanelTab(importedTableName, isCleaningTab);
            const varUUID = this.appID + varID;
            const dataExplorer = DataExplorer({ appID: varUUID, tableName: importedTableName });
            layoutWidget.addWidget({ content: dataExplorer });

            // Attach the table name to the tab we create. This will help when we need to
            // specifically close this tab, e.g. when disabling a cleaning step results in
            // a table being removed.
            tab.tableName = importedTableName;

            this._containerTabs.push(tab);
            this._dataExplorers.push(dataExplorer);
        }

        _createFigureViewCoordinator () {
            return new FigureViewCoordinator();
        }

        _createUIVE (UIVEArguments) {
            return new UIVariableEditor(UIVEArguments);
        }

        /**
         * Renames a Variable Editor task view that matches the given UUID.
         * @param {String} UUID The Variable Editor's UUID
         * @param {String} newTitle The new title for the task view
         */
        _renameVariableEditorTaskView (UUID, newTitle) {
            const VELayoutWidget = document.getElementById(this._getVariableEditorLayoutWidgetID(UUID));
            if (VELayoutWidget == null) return;

            const titleElement = VELayoutWidget.getElementsByClassName('dc-grid-widget-label');
            if (titleElement.length === 0) return;

            titleElement[0].innerText = newTitle;
        }

        async startup () {
            // Create the DivFigure factory and load necessary CSS files.
            await this._figureFactory.createFactory();

            this.container.startup();
            window.addEventListener('beforeunload', this.shutdownCallback);

            // Create a splash "panel".
            // There's a problem with UIContainers: there really is no support for splash screens.
            // Panels cannot be centered, and documents have tabs associated with them. Neither option works.
            // Instead, we must manually insert an element of our own.
            this._splashPanel = document.createElement('div');
            this._splashPanel.id = 'pa_splash';

            const splashText = document.createElement('a');
            splashText.id = 'pa_splash_link';
            splashText.innerText = appl10n.SplashText;
            splashText.href = '#';
            splashText.onclick = () => { this._toolstrip?.sendImportVariableMessage(); };
            this._splashPanel.appendChild(splashText);

            const tabContainer = document.getElementById(SPLASH_SCREEN_PARENT_ID);
            tabContainer.appendChild(this._splashPanel);
        }

        async _toolstripGalleryItemOpened (taskName) {
            this._closeExistingCleaningTaskTabs();

            const tabName = `${taskName} *`;
            const isCleaningTab = true;
            const [tab, layoutWidget] = this._createCentralPanelTab(tabName, isCleaningTab);

            // eslint-disable-next-line no-unused-vars
            const [nInput, nOutput] = this._getLayoutForTask(taskName);
            if (nInput > 0) {
                // Since we have inputs view, create a row to house them.
                layoutWidget.setLayoutType('rows');

                const inputLayoutWidget = this._createLayoutWidget();
                layoutWidget.appendChild(inputLayoutWidget);
                this.taskInputViewContainer = inputLayoutWidget;

                const outputLayoutWidget = this._createLayoutWidget();
                layoutWidget.appendChild(outputLayoutWidget);
                this.taskOutputViewContainer = outputLayoutWidget;
            } else {
                this.taskInputViewContainer = [];
                this.taskOutputViewContainer = layoutWidget;
            }

            // If you noticed, we `await` adding empty widgets to the layout widgets we create.
            // By waiting for the empty widgets to render before continuing, we simplify the
            // process of adding plots and UIVariableEditors to the task views.

            this._containerTabs.push(tab);
            this._inspectorContentPanelProps.set('isCollapsed', false);
        }

        _getLayoutForTask (taskName) {
            if (taskName.toLowerCase().includes(toolstripl10n.Join)) {
                return [2, 1];
            } else if (taskName.toLowerCase().includes(toolstripl10n.Synchronize)) {
                return [1, 1];
            } else {
                return [0, 1];
            }
        }

        _taskControllerVisibilityChanged (isVisible) {
            const collapsed = !isVisible; // Visible? Not collapsed. Hidden? Collapsed.
            this._inspectorContentPanelProps.set('isCollapsed', collapsed);
        }

        /**
         * Determines whether a cleaning task is open. This is done by checking if any of
         * the open tabs are closable, since currently (as of R2024b), only cleaning tasks
         * are closable.
         * If in the future tabs for the tables users import are closable, this function
         * must be updated.
         * @returns Whether a cleaning task is open
         */
        cleaningTaskIsOpen () {
            const cleaningTabs = this._containerTabs.filter(tab => {
                const props = this.container.getChildProperties(tab);
                return props?.closable || false;
            });

            return cleaningTabs.length >= 1;
        }

        // Close any cleaning task tabs.
        //
        // This function works even if more than one cleaning task tab is open,
        // but will fail an assertion checking that, at most, only one cleaning
        // task tab is open.
        // This is by design. In the odd case an error results in the Data Cleaner
        // displaying more than one cleaning task tab, we want a graceful way of closing
        // all tabs.
        _closeExistingCleaningTaskTabs () {
            const cleaningTabs = this._containerTabs.filter(tab => {
                const props = this.container.getChildProperties(tab);
                return props?.closable || false;
            });

            Log.assert(cleaningTabs.length <= 1, 'There should be, at most, one cleaning task tab being closed');

            // Close any cleaning tabs and remove them from "_containerTabs".
            for (const cleaningTab of cleaningTabs) {
                // Remove
                const index = this._containerTabs.indexOf(cleaningTab);
                if (index > -1) this._containerTabs.splice(index, 1);
                // Close
                const tabProps = this.container.getChildProperties(cleaningTab);
                tabProps.cleanup = () => {};
                this.container.closeDocument(cleaningTab);
            }

            // Reset references to task views.
            this._taskVisualizations = [];
        }

        _closeDataExplorer (tableName) {
            const matchingDataExplorer = this._containerTabs.filter(tab => tab.tableName === tableName);
            Log.assert(matchingDataExplorer.length === 1, 'There should be just 1 Data Explorer tab with a matching table name');

            // Remove
            const index = this._containerTabs.indexOf(matchingDataExplorer[0]);
            if (index > -1) this._containerTabs.splice(index, 1);
            // Close
            const tabProps = this.container.getChildProperties(matchingDataExplorer[0]);
            tabProps.closable = true;
            this.container.closeDocument(matchingDataExplorer[0]);
        }

        _handleTaskCompleted (buttonType) {
            this._closeExistingCleaningTaskTabs();
            this._toolstrip?.setToolstripState(true);
            this._setDataExplorerBusyIndicatorVisible(false);

            // Depending on how the task was completed, we send the appropriate
            // message to the server.
            //
            // We handle this logic here, rather than within the Task Controller itself,
            // because the user can also cancel the task by closing the task tab.
            switch (buttonType) {
                case 'accept':
                    this._taskController.sendAcceptButtonMessage();
                    break;
                case 'cancel':
                default:
                    this._taskController.sendCancelButtonMessage();
            }
        }

        _hideSplashScreen () {
            const assertion = this._splashPanel != null;
            const msg = 'Data Cleaner should have a splash screen at all times';
            Log.assert(assertion, msg);
            if (!assertion) return;

            this._splashPanel.style.display = 'none';
        }

        /**
         * Called when the Data Explorer receives an initialization message from the server.
         * @param {Object} container The Data Cleaner's UIContainer.
         */
        _addPanels (container) {
            this._addVariableBrowser(container);
            this._addTaskController(container);
            this._addHistoryPanel(container);
            this._taskController.visibilityChangedCallback = this._taskControllerVisibilityChanged.bind(this);
            this._taskController.taskCompletedCallback = this._handleTaskCompleted.bind(this);
            // Setting the "isCollapsed" property while setting up the Property Inspector
            // panel does nothing.
            // We must instead set the property to true _after_ starting the container.
            this._inspectorContentPanelProps.set('isCollapsed', true);
        }

        _addVariableBrowser (container) {
            // Instantiate and start up the Variable Browser.
            this._variableBrowser = new VariableBrowser(this.appID);
            this._variableBrowser.startup();

            // Create a content pane using the Variable Browser's Tree's DOM node.
            const variableBrowserPanel = new ContentPane({ content: '' });
            const variableBrowserPanelproperties = new ChildProperties({
                region: 'left',
                panelId: 'panel_var',
                title: appl10n.VariablesPanelTitle,
                description: ''
            });

            container.addPanel(variableBrowserPanel, variableBrowserPanelproperties);

            // Set the parent element to the Variable Browser so it can attach a
            // UIVariableEditor to the parent later on.
            const parentElement = variableBrowserPanel.domNode;
            this._variableBrowser.parentElement = parentElement;
        }

        _addHistoryPanel (container) {
            // Create the History Widget and a "base div" for it to later attach to.
            // We unfortunately cannot use a Content Pane as the div to attach to;
            // an error gets thrown.
            const baseHistoryDiv = document.createElement('div');
            baseHistoryDiv.id = 'historyAttachDiv';

            this._historyWidget = new HistoryWidget(this.appID, baseHistoryDiv);
            this._historyWidget.beforeOpenModeFn = this._displayCancelTaskDialogIfTaskOpen.bind(this);
            const openModeCallbackFn = taskName => { this._toolstripGalleryItemOpened(taskName); };
            this._historyWidget.openModeCallback = openModeCallbackFn.bind(this);

            const historyPanel = new ContentPane({ content: baseHistoryDiv });
            const historyPanelProperties = new ChildProperties({
                region: 'right',
                panelId: 'panel_history',
                title: appl10n.HistoryPanelTitle,
                description: '',
                preferredHeight: 0.25 // %

            });

            container.addPanel(historyPanel, historyPanelProperties);
            this._historyWidget.startup();
        }

        // Separated for unit testing.
        _createLayoutWidget () {
            const layoutWidget = LayoutWidget();
            layoutWidget.style.width = '100%';
            layoutWidget.style.height = '100%';
            layoutWidget.setLayoutType('cols');
            return layoutWidget;
        }

        _addTaskController (container) {
            this._taskPanel = new ContentPane({ content: '' });
            this._inspectorContentPanelProps = new ChildProperties({
                region: 'right',
                panelId: 'panel_inspector',
                title: appl10n.TaskPanelTitle,
                description: '',
                preferredHeight: 0.75 // %

            });

            // Since the TaskController's Property Inspector starts off without any task
            // information, nothing will appear, so we are safe to immediately start it up.
            const taskControllerChannel = '/DataCleaner/TaskController/PubSubPaging_' + this.appID;
            const propertyInspectorChannel = '/DataCleaner/PropertyInspector/PubSubPaging_' + this.appID;
            this._taskController = new TaskController(taskControllerChannel, propertyInspectorChannel);

            const panelContent = this._taskController.getPanelContent();
            this._taskPanel.domNode.appendChild(panelContent);

            container.addPanel(this._taskPanel, this._inspectorContentPanelProps);
        }

        destroy () {
            this._figureFactory?.destroy();

            this._taskController?.destroy();
            this._historyWidget?.destroy();
            this._toolstrip?.destroy();
            this._dataExplorers?.forEach(dataExplorer => dataExplorer?.destroy());
            this._dataExplorers = [];
            this.container?.shutdown?.();

            this._taskController = null;
            this._historyWidget = null;
            this._toolstrip = null;
            this.container = null;

            window.removeEventListener('beforeunload', this.shutdownCallback);

            MessageService.unsubscribe(this._getFullChannelName(), this._martialServerMessage, this);
        }
    }

    return PreprocessingApp;
});
