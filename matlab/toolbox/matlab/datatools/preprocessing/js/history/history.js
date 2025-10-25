/* Copyright 2020-2024 The MathWorks, Inc. */
define('preprocessing/history/history', [
    'dojo/_base/declare',
    'dijit/_WidgetBase',
    'dojo/Evented',
    'dojo/dom-class',
    'mw-tree/Tree',
    'mw-data-model/DataStore',
    'mw-form/MenuItem',
    'mw-form/ContextMenu',
    'mw-form/Menu',
    'mw-form/MenuSeparator',
    'mw-form/PopupMenuItem',
    'mw-messageservice/MessageService',
    'mw-overlay-utils/BusyOverlay',
    'dojo/i18n!preprocessing/l10n/nls/history',
    'mw-data-model/enums/dataStoreTypes'
], function (
    declare,
    _WidgetBase,
    Evented,
    domClass,
    Tree,
    DataStore,
    MenuItem,
    ContextMenu,
    Menu,
    MenuSeparator,
    PopupMenuItem,
    MessageService,
    BusyOverlay,
    historyl10n,
    dataStoreTypes
) {
    return declare('preprocessing/history/history', [_WidgetBase], {

        _channel: '/DataCleaner/History/PubSubPaging_',
        treeData: [],
        tree: null,
        _parentNode: null,
        _busyIndicator: null,
        selectedIndex: null,

        // beforeOpenModeFn: A callback function which executes immediately
        // after the user double clicks on an item, and before the item is
        // opened for edit.
        //
        // It should be asynchronous, and it should return:
        // - "true" to indicate the edit task procedure should continue
        // - "false" to indicate the editing should not start for the task
        beforeOpenModeFn: null,
        openModeCallback: null,

        SERVER_MESSAGE_TYPES: {
            ADD_STEP: 1,
            REMOVE_STEP: 2,
            SET_HISTORY: 3,
            SET_SELECTION: 4,
            SET_TASKS: 5,
            SET_BUSY: 6,
            SET_FREE: 7
        },

        CLIENT_MESSAGE_TYPES: {
            REQ_GET_HISTORY: 8, //
            HISTORY_CHANGED: 9, //
            OPEN_MODE: 10, //
            DELETE_STEP: 11, //
            INSERT_STEP_ABOVE: 12, //
            INSERT_STEP_BELOW: 13, //
            SET_READY: 14
        },

        /*
         * Gets the unique channel name from the URL.
         * @param {domNode} ParentNode The domNode to which the history panel is added as a child.
         * @returns {*}
         */
        constructor: function (appID, domNode) {
            this._parentNode = domNode;
            this._channel = this._channel + appID;
        },

        postCreate: function () {
            this.addDataListeners();
            const message = { eventType: this.CLIENT_MESSAGE_TYPES.REQ_GET_HISTORY };
            MessageService.publish(this._channel, message);
            window.paHistory = this;
        },

        /*
         * Sets up the MessageService listeners for client-server communication.
         * @param {*}
         * @returns {*}
         */
        addDataListeners: function () {
            // MessageService.start();
            MessageService.subscribe(this._channel, this._handleServerMessage, this);
        },

        _handleServerMessage: function (message) {
            const types = this.SERVER_MESSAGE_TYPES;
            switch (message.data.type) {
                case types.ADD_STEP:
                    this._addPreprocessingStep(message);
                    break;
                case types.REMOVE_STEP:
                    this._removePreprocessingStep(message);
                    break;
                case types.SET_HISTORY:
                    this._setHistory(message);
                    break;
                case types.SET_SELECTION:
                    // this._setSelection(message);
                    break;
                case types.SET_TASKS:
                    this._setPreprocessingTasks(message);
                    break;
                case types.SET_BUSY:
                    this.addBusyOverlay(message);
                    break;
                case types.SET_FREE:
                    this.removeBusyOverlay(message);
                    break;
                default:
                    throw new Error(`History panel received message type value of ${message.data.type}; no function exists to handle it`);
            }
        },

        /*
         * Adds a preprocessing step to the history panel.
         * This method destroys the existing widget initially and then creates a
         * new widget with the additional steps.
         * @param {Object} event
         * @param {String} eventData.Data.id The unique ID of the preprocessing step to be added
         * @returns {*}
         */
        _addPreprocessingStep: function (eventData) {
            if (!(eventData && eventData.data && eventData.data.id)) {
                return;
            }

            if (this.tree) {
                this.tree.destroy();
            }

            this.treeData.push(eventData.data);
            this.createTree(this.treeData);
            // if (this.selectedIndex == null)
            this.selectedIndex = this.treeData.length - 1;
            // this.createGutterRules(this.tree._dataStore, "blue");
        },

        /*
         * Remotes a preprocessing step from the history panel.
         * This method destroys the existing widget initially and then creates a
         * new widget without the removed step.
         * @param {Object} event
         * @param {String} eventData.data.id The index of the preprocessing step to be removed.
         * @returns {*}
         */
        _removePreprocessingStep: function (eventData) {
            if (!(this.tree && eventData && eventData.data && eventData.data.index)) {
                return;
            }

            this.tree.destroy();
            const idx = eventData.data.index;
            this.treeData.splice(idx, 1);
            this.createTree(this.treeData);
            // if (this.selectedIndex == null)
            this.selectedIndex = this.treeData.length - 1;
            // this.createGutterRules(this.tree._dataStore, "blue");
        },

        /*
         * Sets the preprocessing history in the tree widget.
         * This method destroys the existing widget and replaces it with the new
         * history data.
         * @param {Object} event
         * @param {Array} eventData.data The new history to be set
         * @returns {*}
         */
        _setHistory: function (eventData) {
            if (!(eventData && eventData.data)) {
                return;
            }

            if (this.tree) {
                this.tree.destroy();
            }

            const steps = eventData.data.Steps;

            this.treeData = Array.isArray(steps) ? steps : [steps];
            this.createTree(this.treeData);

            const treeIsPopulated = this.tree.domNode != null && this.treeData.length > 0;
            if (treeIsPopulated) {
                this.selectedIndex = this.treeData.length - 1;
                const treeNodes = this.tree.domNode.getElementsByClassName('treeNode');
                const nodeID = treeNodes[this.selectedIndex].getAttribute('data-test-id');
                this.tree.setSelection([{ id: nodeID }]);
            }
        },

        /*
         * Sets the selection in the history tree
         */
        _setSelection: function (eventData) {
            if (!(eventData && eventData.data)) {
                return;
            }

            // TODO: current use case is only clearing selection from server
            // if server needs to set selection and that should be captured, find the index based on the node id
            this.selectedIndex = null;
            this.tree.setSelection(eventData.data.nodeIds);
        },

        /*
         * Creates a tree widget with the different preprocessing steps as tree nodes.
         * @param {Array} treeData A array of the various preprocessing steps to
         * show inside the tree widget.
         * TreeData Entry:
         *     {
         *        id: {String} Unique Step id
         *        label: {String} Text to display in the tree.
         *        checked: {Boolean} Flag to enable/disable a step.
         *        parent: {Object} Null TODO: Support adding the associated code as a child.
         *        index: {Number} Position on the preprocessing step in the tree.
         *     }
         * @returns {*}
         */
        createTree: function (treeData) {
            const ds = this._getTreeDataStore(JSON.parse(JSON.stringify(treeData)));
            const opts = this._getTreePlugins();

            const treeWidget = new Tree(ds, opts);
            this._addDblClickListeners(treeWidget);
            this._addSelectionChangedListeners(treeWidget);
            this._addDnDListeners(treeWidget);
            this._addContextMenuListeners(treeWidget);
            this._parentNode.appendChild(treeWidget.domNode);
            treeWidget.startup();
            const selectionChangedFn = evt => { this._treeWidgetSelectionChanged(evt); };
            treeWidget.on('selectionChanged', selectionChangedFn.bind(this));
            this.tree = treeWidget;
            // this.createGutterRules(ds, "blue");
        },

        _treeWidgetSelectionChanged: function (evt) {
            const selectedIndex = this.treeData.findIndex(function (step) {
                return step.id === evt.nodeIds[0];
            });

            this.selectedIndex = selectedIndex;
        },

        createGutterRules: function (dataStore, color) {
            this.addForAllNodes(dataStore, color);
        },

        addForAllNodes: function (dataStore, color) {
            const treeNodes = this.tree.domNode.getElementsByClassName('treeNode');
            /* var topStepIndex = -1;
            for (var i = this.treeData.length-1; i >= 0; i--) {
                // TODO: Refactor to make this consistent (all string or all logical)
                if (this.treeData[i].checked == 'true' || this.treeData[i].checked == true) {
                    topStepIndex = i;
                    break;
                }
            } */

            if (this.selectedIndex != null) {
                const nodeList = [];
                for (let i = 0; i <= this.selectedIndex; i++) {
                    nodeList[i] = treeNodes[i].getAttribute('data-test-id');
                }

                dataStore.addMetaDataRule(
                    'hierarchyRule',
                    dataStore.createMetaDataRule(
                        {
                            node: {
                                gutterColors: ['#3297FD'],
                                fontSize: '60px'
                            }
                        }, {
                            type: 'hierarchy',
                            value: nodeList
                        }
                    )
                );
            } else {
                dataStore.addMetaDataRule(
                    'hierarchyRule',
                    dataStore.createMetaDataRule(
                        {
                            node: {
                                gutterColors: ['#3297FD'],
                                fontSize: '60px'
                            }
                        }, {
                            type: 'hierarchy',
                            value: []
                        }
                    )
                );
            }
        },

        /*
         * Adds the tree plugins needed to enable the required user-interactions.
         * @param {*}
         * @returns {*}
         */
        _getTreePlugins: function () {
            const options = {
                dataTestId: 'historyPanel',
                numberOfGutters: 1,
                plugins: [
                    Tree.PLUGINS.SingleNodeSelection,
                    Tree.PLUGINS.DragAndDrop,
                    Tree.PLUGINS.ContextMenu
                ]
            };
            return options;
        },

        /*
         * Creates a DataStore from the treeData
         * @param {Array} treeData The data to be displayed in the tree widget
         * TreeData Entry:
         *     {
         *        id: {String} Unique Step id
         *        label: {String} Text to display in the tree.
         *        checked: {Boolean} Flag to enable/disable a step.
         *        parent: {Object} Null TODO: Support adding the associated code as a child.
         *        index: {Number} Position on the preprocessing step in the tree.
         *     }
         * @returns {DataStore} a DataStore constructed using the treeData.
         */
        _getTreeDataStore: function (treeData) {
            const dataStore = DataStore.create(treeData, Object.assign({
                isCheckboxTree: true,
                getCheck: function (dataNode) { return dataNode.checked; },
                setCheck: function (dataNode, status) { dataNode.checked = status; }
            }, {
                type: dataStoreTypes.TREE
            }));
            return dataStore;
        },

        /*
         * This method defined the custom behavior we want after when a treeNode
         * is enabled or disabled.
         * @param {Object} mw-tree The tree widget with the preprocessing steps
         * @returns {*}
         */
        _addSelectionChangedListeners: function (widget) {
            widget.on('checkChanged', function (event) {
                const checkedNode = widget.domNode.querySelectorAll('[data-test-id="' + event.nodeId + '"]')[0];
                if (!event.newValue) {
                    checkedNode.style.color = '#bbbb';
                } else {
                    checkedNode.style.color = 'inherit';
                }
                const idx = this.treeData.findIndex(function (step) {
                    return (step.id === event.nodeId);
                });
                this.treeData[idx].checked = event.newValue;
                // this.createGutterRules(this.tree._dataStore, "blue");
                this._dispatchHistoryChanged();
            }.bind(this));
        },

        /*
         * This method defined the custom behavior we want after when a treeNode
         * is enabled or disabled.
         * @param {Object} mw-tree The tree widget with the preprocessing steps
         * @returns {*}
         */
        _addDblClickListeners: function (widget) {
            widget._treeView._handleNodeDoubleClick = function (evt) {
                const childNodes = Array.from(this.tree.domNode.getElementsByClassName('treeNodeText'));

                // To find the node the user double clicked, we cannot simply check if the event's
                // target node matches the childNode. For example, the user could double click on
                // the listing's whitespace, which would not match the childNode element.
                // We want this case to count as a valid double click.
                //
                // Thus, we must check if the target element and given child node element's "treeNode"
                // ancestor matches.
                const evtTreeNodeParent = evt.target.closest('#historyAttachDiv .treeNode');
                const idx = childNodes.findIndex(node => evtTreeNodeParent === node.closest('#historyAttachDiv .treeNode'));

                const clickedChild = this.treeData[idx];
                if (clickedChild.checked) {
                    const disableProceedingSteps = true;
                    this._onOpenMode(clickedChild, 'selectionChanged', disableProceedingSteps);
                }
            }.bind(this);
        },

        /*
         * This method defined the custom behavior we want after when a treeNode
         * is reordered using drag and drop.
         * @param {Object} mw-tree The tree widget with the preprocessing steps
         * @returns {*}
         * TODO: Remove this method when the mw-tree supports DnD reordering.
         */
        _addDnDListeners: function (widget) {
            widget.on('dropCompleted', function (event) {
                let newPosition = this.treeData.findIndex(function (node) {
                    return (node.id === event.target.nodeId);
                });
                const oldPosition = this.treeData.findIndex(function (node) {
                    return (node.id === event.source.nodeIds[0]);
                });

                // TreNode Dropped below the bottom node
                if (newPosition < 0) {
                    newPosition = this.treeData.length - 1;
                }

                // Moving upwards
                if (oldPosition > newPosition) {
                    newPosition = newPosition + 1;
                }

                // No change to the order of steps
                if (oldPosition === newPosition) {
                    widget.destroy();
                    this.createTree(this.treeData);
                    return;
                }

                const elementToMove = this.treeData.splice(oldPosition, 1)[0];
                this.treeData.splice(newPosition, 0, elementToMove);
                widget.destroy();
                this.createTree(this.treeData);
                this._dispatchHistoryChanged();
            }.bind(this));
        },

        _addContextMenuListeners: function (widget) {
            const that = this;
            widget.on('contextMenu', function (evt) {
                const xPos = evt.left;
                const yPos = evt.top;
                const selectedIndex = that.treeData.findIndex(function (step) {
                    return step.id === evt.target.nodeId;
                });
                const selectedStep = that.treeData[selectedIndex];
                const hasBelow = selectedIndex < that.treeData.length - 1;
                const hasAbove = selectedIndex > 0;
                if (selectedStep) {
                    that.setupCtxMenu(xPos, yPos, selectedStep, hasBelow, hasAbove);
                }
            });
        },

        _setEnableStateBelow: function (state, topStep) {
            this._updateStepsStateBelow(state, topStep);
            this._dispatchHistoryChanged();
        },

        _updateStepsStateBelow: function (state, topStep) {
            const selectedIndex = this.treeData.findIndex(function (step) {
                return step.id === topStep.id;
            });

            if (selectedIndex >= this.treeData.length) { return; }

            for (let i = selectedIndex + 1; i < this.treeData.length; i = i + 1) {
                this.treeData[i].checked = state;
            }

            this.tree.destroy();
            this.createTree(this.treeData);
        },

        /**
         * Adds a context menu item to the passed in context menu
         * @param {*} menu Menu to add to
         * @param {*} menuText Text for menu item
         * @param {*} action Action name to dispatch to the server when item clicked
         * @param {*} step Node data to package with action
         */
        _addContextMenuItem: function (menu, menuText, callbackFcn, step, action) {
            const openModeBtn = new MenuItem({
                text: menuText,
                closeMenuOnClick: false
            });
            const clickHandler = openModeBtn.on('click', function (evt) {
                this[callbackFcn](action, step);
                menu.destroy();
            }.bind(this));

            menu.addChild(openModeBtn);
            menu.own(clickHandler);
        },

        setupCtxMenu: function (xPos, yPos, step, hasBelow, hasAbove) {
            const menu = new ContextMenu();

            // if (step.checked == true)
            // this._addContextMenuItem(menu, historyl10n.EditStepLabel, '_onOpenMode', step, 'openMode');

            this._addContextMenuItem(menu, historyl10n.DeleteStepLabel, '_onDeleteStep', step, 'deleteStep');

            if (this._preprocessingTasks) {
                menu.addChild(new MenuSeparator());
                const insertAboveSubMenu = new Menu();
                const insertBelowSubMenu = new Menu();

                for (let i = 0; i < this._preprocessingTasks.length; i = i + 1) {
                    this._addContextMenuItem(insertAboveSubMenu, this._preprocessingTasks[i], '_dispatchContextMenuAction', {
                        step,
                        task: this._preprocessingTasks[i]
                    }, this.CLIENT_MESSAGE_TYPES.INSERT_STEP_ABOVE);

                    this._addContextMenuItem(insertBelowSubMenu, this._preprocessingTasks[i], '_dispatchContextMenuAction', {
                        step,
                        task: this._preprocessingTasks[i]
                    }, this.CLIENT_MESSAGE_TYPES.INSERT_STEP_BELOW);
                }

                /*
                const insertAboveMenuItem = new PopupMenuItem({
                    text: historyl10n.InsertStepAboveLabel,
                    menu: insertAboveSubMenu
                });

                const insertBelowMenuItem = new PopupMenuItem({
                    text: historyl10n.InsertStepBelowLabel,
                    menu: insertBelowSubMenu
                });

                menu.addChild(insertAboveMenuItem);
                menu.addChild(insertBelowMenuItem);
                */
            }

            if (hasBelow) {
                menu.addChild(new MenuSeparator());
                this._addContextMenuItem(menu, historyl10n.DisableStepsBelowLabel, '_setEnableStateBelow', step, false);
                this._addContextMenuItem(menu, historyl10n.EnableStepsBelowLabel, '_setEnableStateBelow', step, true);
            }

            menu.openMenu({
                x: xPos,
                y: yPos
            });
            menu.on('close', function () {
                menu.destroy();
            });
        },

        /*
         * Opens the given step, with the option of disabling all steps that proceed the given step.
         */
        _onOpenMode: async function (openStep, actionType, disableProceedingSteps) {
            const doEditTask = this.beforeOpenModeFn != null
                ? await this.beforeOpenModeFn()
                : true;

            if (!doEditTask) return;

            // We do not allow users to edit sort, rename, and delete cleaning steps.
            if (openStep.OperationType != null) {
                const stepIsNotEditable = ['Sort', 'NonEditable'].some(type => openStep.OperationType === type);
                if (stepIsNotEditable) return;
            }

            // Set default values
            if (actionType == null || actionType === '') actionType = 'openMode';
            if (disableProceedingSteps == null) disableProceedingSteps = false;

            // Disable proceeding checkboxes if needed
            if (disableProceedingSteps) this._updateStepsStateBelow(false, openStep);

            // Create a new tab for this editable cleaning step
            if (this.openModeCallback != null) {
                const taskName = openStep.label; // Example name: "Normalize Data: t.Age"
                this.openModeCallback(taskName);
            }

            // Let the server know to launch this task so the user can edit it
            const nodeData = {
                currentStep: openStep,
                steps: this.treeData,
                type: actionType
            };
            this._dispatchAction(this.CLIENT_MESSAGE_TYPES.OPEN_MODE, nodeData);
        },

        /*
         * Delete step menu item is clicked. Update the tree steps first and then fire the action to server that history changed
         */
        _onDeleteStep: function (action, deleteStep) {
            const selectedIndex = this.treeData.findIndex(function (step) {
                return step.id === deleteStep.id;
            });

            if (selectedIndex >= this.treeData.length) return;
            // -----------------------------------------------

            this.treeData.splice(selectedIndex, 1);

            this.tree.destroy();
            this.createTree(this.treeData);

            const nodeData = {
                currentStep: deleteStep,
                steps: this.treeData
            };
            this._dispatchContextMenuAction(this.CLIENT_MESSAGE_TYPES.DELETE_STEP, nodeData);
        },

        /**
         * Publishes the passed in context menu action
         * @param {*} eventType
         * @param {*} nodeData
         */
        _dispatchContextMenuAction: function (eventType, nodeData) {
            try {
                MessageService.publish(this._channel, {
                    eventType,
                    data: nodeData
                });
            } catch (e) {
                console.log(e);
            }
        },

        /**
         * Publishes the passed in action name
         * @param {*} eventType
         * @param {*} nodeData
         */
        _dispatchAction: function (eventType, nodeData) {
            try {
                MessageService.publish(this._channel, {
                    eventType,
                    data: nodeData
                });
            } catch (e) {
                console.log(e);
            }
        },

        /*
         * Publishes the changes to the history data via the user's actions.
         * This method is called as part of the selectionChanged and DnD listener callbacks.
         * @param {*}
         * @returns {*}
         */
        _dispatchHistoryChanged: function () {
            try {
                MessageService.publish(this._channel, {
                    eventType: this.CLIENT_MESSAGE_TYPES.HISTORY_CHANGED,
                    data: this.treeData
                });
            } catch (e) {
                console.log(e);
            }
        },

        /*
         * Disables interactions on the history widget by adding a busy overlay.
         * @param {*}
         * @returns {*}
         */
        addBusyOverlay: function () {
            this._busyIndicator = new BusyOverlay();
            this._busyIndicator.set('target', this._parentNode);
            this._busyIndicator.show();
        },

        /*
         * Enables interactions on the history widget by removing the busy overlay.
         * @param {*}
         * @returns {*}
         */
        removeBusyOverlay: function () {
            if (this._busyIndicator && this._busyIndicator.isVisible()) {
                this._busyIndicator.hide();
            }
        },

        _setPreprocessingTasks: function (message) {
            if (message && message.data) {
                this._preprocessingTasks = message.data;
            }
        },

        _destroy: function () {
            this.destroy();
        },

        destroy: function () {
            MessageService.unsubscribe(this._channel, this._handleServerMessage, this);

            if (this.tree) {
                this.tree.destroy();
            }
            this.inherited(arguments);
        }

    });
});
