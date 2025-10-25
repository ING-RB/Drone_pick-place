/*
    Copyright 2020-2023 The MathWorks, Inc.
*/

define('preprocessing/dataExplorer/DataExplorer', [
    'mw-widget-api/WidgetBase',
    'mw-widget-api/defineWidget',
    'mw-widget-api/facade/html',
    'MW/layout/TabContainer',
    'dijit/layout/ContentPane',
    'preprocessing/dataExplorer/FigureViewCoordinator',
    'mw-messageservice/MessageService',
    'variableeditor_peer/UIVariableEditor',
    'preprocessing/dataExplorer/SummaryConstructor',
    'mw-data-model/On',
    'datatoolsservices/Data/DataToolsRangeUtils',
    'dojo/i18n!preprocessing/l10n/nls/DataExplorer',
    'mw-log/Log'
], function (WidgetBase, defineWidget, html, TabContainer, ContentPane, FigureViewCoordinator,
    MessageService, UIVariableEditor, SummaryConstructor, On, DataToolsRangeUtils, dataExplorerl10n, Log) {
    'use strict';

    const BASE_CHANNEL = '/DataCleaner/DataExplorer/PubSubPaging_';

    const FOCUS_VIEWS = {
        PLOT: 'PLOTS',
        SUMMARY: 'SUMMARY',
        DATA: 'DATA'
    };

    const CLIENT_MESSAGE_TYPES = {
        CLIENT_MSG_SET_FOCUSED_VIEW: 1,
        CLIENT_MSG_CLIENT_READY: 4,
        CLIENT_MSG_DESTROY: 10
    };

    const SERVER_MESSAGE_TYPES = {
        SRV_MSG_SETUP_DATA_VIEW: 2,
        SRV_MSG_SETUP_PLOT_VIEW: 3,
        SRV_MSG_SETUP_SUMMARY_VIEW: 5,
        SRV_MSG_UPDATE_SUMMARY_TABLE: 9,
        SRV_MSG_REMOVE_DIV_FIGURE: 6,
        SRV_MSG_REMOVE_DATA_UIVE: 7,
        SRV_MSG_REMOVE_SUMMARY: 8,
        SRV_MSG_SET_FOCUSED_VIEW: 12,
        SRV_MSG_SET_SELECTION: 13
    };

    const TAB_CONTAINER_BASE_ID = 'dataExplorerTabContainer_';
    const PLOT_TAB_BASE_ID = 'dataExplorerPlotTab_';
    const DATA_TAB_BASE_ID = 'dataExplorerDataTab_';
    const SUMMARY_TAB_BASE_ID = 'dataExplorerSummaryTab_';
    const SUMMARY_UIVE_ID_BASE = 'pa_summaryUIVE_';

    const TAB_CONTAINER_CSS_CLASS = 'pa_dataExplorer';
    const SUMMARY_FLEX_CLASS = 'pa_summaryFlex';

    class DataExplorer extends WidgetBase {
        static get properties () {
            return {
                channelID: {
                    reflect: false,
                    type: String
                },
                tableName: {
                    reflect: false,
                    type: String
                }
            };
        }

        set appID (uuid) {
            this._appID = uuid;
            this._channel = '/DataCleaner/DataExplorer/PubSubPaging_' + this._appID;
            MessageService.subscribe(this._channel, this._martialServerMessage, this);
            const eventType = CLIENT_MESSAGE_TYPES.CLIENT_MSG_CLIENT_READY;
            const message = { eventType };
            MessageService.publish(this._channel, message);
        }

        get appID () {
            return this._appID;
        }

        constructor () {
            super();

            this._channel = '';

            this._tabContainer = null;
            this._figureCoordinator = null;

            this._summaryContentPane = null;
            // Create a flex wrapper that we will parent to the summary content pane
            // when the pane gets created.
            // This is important for properly sizing the UIVariableEditor we create.
            this._summaryPaneFlexWrapper = document.createElement('div');
            this._summaryPaneFlexWrapper.classList.add(SUMMARY_FLEX_CLASS);

            this._dataTabContentPane = null;
            this._visualizationContentPane = null;
            this._dataUIVE = null;
            this._on = new On();

            this._summaryTable = null; // High-level overview summary table
            this._columnSummaryUIVE = null; // Per-column summary table

            this._summaryConstructor = new SummaryConstructor();

            // There's a chance this widget may be destroyed twice at the same time:
            // 1. "destroy()" gets called from PreprocessingApp
            // 2. This widget gets removed from the DOM immediately after, resulting in
            //    "destroy()" being called again.
            // To prevent any issues from occurring, we track whether this widget has
            // been destroyed already.
            this._hasBeenDestroyed = false;

            return this;
        }

        render () {
            this.style.display = 'block';

            // We have to set the DataExplorer's position to "absolute".
            // This is necessary due to how "TabContainer" resizes. In summary, Dojo expects a
            // "top" and "left" padding to determine how far from the upper-left corner the
            // tab container should be placed.
            //
            // ...which means that it completely ignores all the parent flex layouts. As such, we force
            // the Data Explorer to be "absolute", so TabContainer's reference for sizing is
            // the Data Explorer and not any Dojo widgets in the parent hierarchy.
            this.style.position = 'absolute';

            return html``;
        }

        firstUpdated () {
            const assertion = this.appID != null;
            const assertMsg = 'DataExplorer is missing "dataExporerUuid" and is not subscribed to backend';
            Log.assert(assertion, assertMsg);

            this.startup();
            // Resize everything after startup to adjust to the DOM structure.
            this.notifyPaneResize();
        }

        _resizeAllTabs () {
            // g2999492, g3069326: Force content panes' heights and widths to 100%.
            // Without this, the content panes will expand to match the size of their
            // UIVariableEditors, which will in turn cause double scrollbars to appear.
            //
            // The "100%"s will be overwritten when the user makes one of the tabs show, but
            // that is OK, because then the TabContainer will make the ContentPane resize correctly.
            this._visualizationContentPane.domNode.style.height = '100%';
            this._visualizationContentPane.domNode.style.width = '100%';
            this._dataTabContentPane.domNode.style.height = '100%';
            this._dataTabContentPane.domNode.style.width = '100%';
            this._summaryContentPane.domNode.style.height = '100%';
            this._summaryContentPane.domNode.style.width = '100%';
        }

        _resizeTabContainer () {
            if (this.parentNode == null) return;
            if (!this._tabContainer?.domNode) return;

            // Because we have set the Data Explorer's position to "absolute" (and thus it resizes
            // to the tab container), we use the parent node's dimensions for the new TabContainer size.
            // We assume that the parent node size does fit its children's contents.
            const thisSize = this.parentNode.getBoundingClientRect();
            const newTabContainerSize = {
                w: thisSize.width,
                h: thisSize.height,
                l: thisSize.left,
                t: thisSize.top
            };

            this._tabContainer.resize(newTabContainerSize);
            this._resizeAllTabs(); // Need to resize its tabs too
        }

        _sendFocusMessage (focusedView) {
            const eventType = CLIENT_MESSAGE_TYPES.CLIENT_MSG_SET_FOCUSED_VIEW;
            const data = { focusedView };
            const message = { eventType, data };
            MessageService.publish(this._channel, message);
        }

        async _martialServerMessage (msg) {
            const types = SERVER_MESSAGE_TYPES;

            await this.updateComplete;
            switch (msg.data.type) {
                case types.SRV_MSG_SETUP_DATA_VIEW:
                    this._setupDataView(msg);
                    break;
                case types.SRV_MSG_SETUP_PLOT_VIEW:
                    this._setupPlotView(msg);
                    break;
                case types.SRV_MSG_SETUP_SUMMARY_VIEW:
                    this._setupSummaryView(msg);
                    break;
                case types.SRV_MSG_UPDATE_SUMMARY_TABLE:
                    this._updateSummaryTable(msg);
                    break;
                case types.SRV_MSG_REMOVE_DIV_FIGURE:
                    this._removeDivFigure(msg.data.uuid);
                    break;
                case types.SRV_MSG_REMOVE_DATA_UIVE:
                    this._removeDataUIVE();
                    break;
                case types.SRV_MSG_REMOVE_SUMMARY:
                    this._removeSummary();
                    break;
                case types.SRV_MSG_SET_FOCUSED_VIEW:
                    this._setFocusedView(msg);
                    break;
                case types.SRV_MSG_SET_SELECTION:
                    this._setSelectionOnDataView(msg);
                    break;
                default:
                    throw new Error(`History panel received message type value of ${msg.data.type}; no function exists to handle it`);
            }
        }

        _destroyUIVE (UIVE) {
            // Prevent the UIVariableEditor from being destroyed more than once at
            // the same time, otherwise it will throw an error.
            if (UIVE.pa_hasBeenDestroyed) return;

            const popout = document.getElementById(UIVE.widget.popoutId);

            try {
                UIVE.destroy();
            } catch (_e) {
                // Nothing to do here. There are some cases where the UIVariableEditor
                // tries to delete an event listener that doesn't exist---this should not happen,
                // considering that part of the initialization process sets up the event listener.
            }

            // There's a chance the popout still remains. If it does, we remove it.
            if (popout) popout.remove();

            UIVE.pa_hasBeenDestroyed = true;
        }

        _setupDataView (msg) {
            const UIVEArguments = {
                UUID: msg.data.tableID,
                WidgetContainerId: this._dataTabContentPane.domNode.id,
                ResizeBehaviour: 'container',
                SelectionType: 'SingleColumnSelection'
            };
            this._dataUIVE = this._createUIVariableEditor(UIVEArguments);
            /*
            // Set the default selection to be the 1st column
            if (UIVE.widget && UIVE.widget.onViewReady) {
                UIVE.widget.onViewReady().then((view) => {
                    const selectionRange = {
                        selectedRows: [{
                            start: 0,
                            end: view.rows - 1,
                            count: view.rows
                        }],
                        selectedColumns: [{
                            start: 0,
                            end: 0,
                            count: 1
                        }]
                    };
                    view._table.setSelection(selectionRange, 'server', true);
                });
            }
            */
        }

        // Creates the UIVariableEditor with the given arguments.
        // Separated for unit testing.
        _createUIVariableEditor (UIVEArgs) {
            const UIVE = new UIVariableEditor(UIVEArgs);
            UIVE.pa_hasBeenDestroyed = false;
            /*
            // Set the default selection to be the 1st column
            if (UIVE.widget && UIVE.widget.onViewReady) {
                UIVE.widget.onViewReady().then((view) => {
                    const selectionRange = {
                        selectedRows: [{
                            start: 0,
                            end: view.rows - 1,
                            count: view.rows
                        }],
                        selectedColumns: [{
                            start: 0,
                            end: 0,
                            count: 1
                        }]
                    };
                    view._table.setSelection(selectionRange, 'server', true);
                });
            }
            */
            return UIVE;
        }

        _setupPlotView (msg) {
            if (this._figureCoordinator) this._figureCoordinator.destroy();
            this._figureCoordinator = new FigureViewCoordinator();

            // After the DivFigure is created, we must resize it to its parent element's size.
            const postFigureCreationFn = () => { this._figureCoordinator.handleResize(); };
            this._figureCoordinator.createFigureView(this._visualizationContentPane.domNode, msg.data.FigureInfo, postFigureCreationFn);
        }

        _callSummaryConstructorConstructUIVE (tableID, wrapperDivParent, wrapperDivID) {
            return this._summaryConstructor.constructUIVariableEditorTable(tableID, wrapperDivParent, wrapperDivID);
        }

        _setupSummaryView (msg) {
            // Set up the column-level summary table for individual statistics on each column.
            const tableID = msg.data.tableID;
            const wrapperDivParent = this._summaryPaneFlexWrapper;
            const wrapperDivID = `${SUMMARY_UIVE_ID_BASE}${this.appID}`;
            this._columnSummaryUIVE = this._callSummaryConstructorConstructUIVE(tableID, wrapperDivParent, wrapperDivID);
        }

        _updateSummaryTable (msg) {
            // Set up the summary table for the general summary statistics.
            if (this._summaryTable) this._summaryTable.remove();
            this._summaryTable = this._summaryConstructor.constructHighLevelTable(msg.data);
            this._summaryPaneFlexWrapper.prepend(this._summaryTable);
        }

        _removeDivFigure (uuid) {
            const divFigureElements = document.getElementsByClassName(uuid);
            if (divFigureElements.length > 0) divFigureElements[0].remove();

            // TODO: Stop doing the above and simply have the figure coordinator
            // remove the div figure. This way, we don't need to know the div figure's ID.
            // this._figureCoordinator.removeDivFigureFromDOM();
        }

        _removeDataUIVE () {
            if (this._dataUIVE) this._destroyUIVE(this._dataUIVE);
            this._dataUIVE = null;
        }

        _removeSummary () {
            if (this._summaryTable) this._summaryTable.remove();
            if (this._columnSummaryUIVE) this._destroyUIVE(this._columnSummaryUIVE);

            this._summaryTable = null;
            this._columnSummaryUIVE = null;
        }

        _setFocusedView (msg) {
            if (msg.data.view === 'PLOTS') {
                this._tabContainer.showChild(this._visualizationContentPane);
            } else {
                this._tabContainer.showChild(this._dataTabContentPane);
            }
        }

        _setSelectionOnDataView (msg) {
            const startRow = 0;
            const endRow = msg.data.selectionRange.endRow - 1;
            const startColumn = msg.data.selectionRange.startColumn - 1;
            const endColumn = startColumn;
            const selectionRange = {
                selectedRows: [{
                    start: startRow,
                    end: endRow,
                    count: endRow + 1
                }],
                selectedColumns: [{
                    start: startColumn,
                    end: endColumn,
                    count: 1
                }]
            };
            this._dataUIVE.widget._activeView._table.setSelection(selectionRange, 'server', true);
        }

        // Creates the Tab Container with the given div ID.
        // Separated for unit testing.
        _createTabContainer () {
            const tabContainerID = `${TAB_CONTAINER_BASE_ID}${this.appID}`;
            const style = 'height: 100%; width: 100%;';

            const tabContainer = new TabContainer({
                id: tabContainerID,
                displayToolTipsOnTruncatedTabs: true,
                tabReorderingEnabled: false,
                tabsRepositioningEnabled: false,
                tabWidthAdjustmentEnabled: false,
                shrinkTabsToFit: false,
                style
            }, tabContainerID);
            tabContainer.domNode.classList.add(TAB_CONTAINER_CSS_CLASS);

            return tabContainer;
        }

        // Creates a Content Pane. Separated for unit testing.
        _createContentPane (title, content) {
            return new ContentPane({ title, content });
        }

        // Call startup after providing a parent node and the parent node's ID.
        startup () {
            // Setup
            this._tabContainer = this._createTabContainer();

            // Function definitions
            const setUpVisualizationTab = () => {
                // Create the content pane, and provide it to the FigureViewCoordinator.
                // The Coordinator will create new DivFigures and make them children to
                // the content pane.
                this._visualizationContentPane = this._createContentPane(dataExplorerl10n.VisualizationTabTitle, '');
                this._visualizationContentPane.domNode.id = `${PLOT_TAB_BASE_ID}${this.appID}`;
                this._tabContainer.addChild(this._visualizationContentPane);
            };

            const setUpDataTab = () => {
                this._dataTabContentPane = this._createContentPane(dataExplorerl10n.DataTabTitle, '');
                this._dataTabContentPane.domNode.id = `${DATA_TAB_BASE_ID}${this.appID}`;
                this._tabContainer.addChild(this._dataTabContentPane);
                // The content pane will have its content filled when a data message arrives.
            };

            const setUpSummaryTab = () => {
                this._summaryContentPane = this._createContentPane(dataExplorerl10n.SummaryTabTitle, '');
                this._summaryContentPane.domNode.id = `${SUMMARY_TAB_BASE_ID}${this.appID}`;
                this._tabContainer.addChild(this._summaryContentPane);

                this._summaryContentPane.domNode.appendChild(this._summaryPaneFlexWrapper);
                // The content pane will have its content filled when a summary message arrives.
            };

            // Create components & start the tab container up.
            setUpDataTab();
            setUpVisualizationTab();
            setUpSummaryTab();

            this.appendChild(this._tabContainer.domNode);
            this._tabContainer.startup();
            this.showDefaultTab();

            // Add onShow events (user opens a tab)
            this._dataTabContentPane.onShow = () => this._sendFocusMessage(FOCUS_VIEWS.DATA);
            this._visualizationContentPane.onShow = () => this._sendFocusMessage(FOCUS_VIEWS.PLOT);
            this._summaryContentPane.onShow = () => this._sendFocusMessage(FOCUS_VIEWS.SUMMARY);
        }

        reset () {
            this.showDefaultTab();
        }

        showDefaultTab () {
            if (!this._dataTabContentPane) {
                throw new Error('DataExplorer cannot show default tab because it does not exist.');
            } // ---------------------------

            this._tabContainer.showChild(this._dataTabContentPane);
        }

        notifyPaneResize () {
            if (this._hasBeenDestroyed) return;

            // Resize every tab first, _then_ resize our DivFigure (through the figure coordinator).
            // If we reverse this order, we risk the DivFigure being too large/small for the central panel.
            this._resizeTabContainer();
            if (this._figureCoordinator) this._figureCoordinator.handleResize();
        }

        on (eventName, callback) {
            return this._on.on(eventName, callback);
        }

        isDestroyed () {
            return this._hasBeenDestroyed;
        }

        destroy () {
            if (this._hasBeenDestroyed) return;

            // Remove content panes from the tab container _without destroying them_.
            // TODO: This needs fixing.
            // This circumvents current errors destroying the DivFigure, but this is a major memory leak source.
            const destroyFlag = false;
            this._tabContainer?.removeAll(destroyFlag);

            this._figureCoordinator?.destroy();
            // if (this._dataUIVE) this._destroyUIVE(this._dataUIVE);
            // if (this._columnSummaryUIVE) this._destroyUIVE(this._columnSummaryUIVE);
            this._tabContainer?.destroyRecursive();

            // We need to let the server know it should destroy this DataExplorer.
            const eventType = CLIENT_MESSAGE_TYPES.CLIENT_MSG_DESTROY;
            const data = {};
            const message = { eventType, data };
            MessageService.publish(this._channel, message);

            MessageService.unsubscribe(this._channel, this._martialServerMessage, this);

            this._hasBeenDestroyed = true;
        }

        disconnectedCallback () {
            this.destroy();
        }
    }

    const dataExplorer = defineWidget({
        name: 'mw-datatools-datacleaner-dataexplorer',
        widgetClass: DataExplorer
    });
    return dataExplorer;
});
