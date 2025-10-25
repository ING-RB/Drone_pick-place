/* Copyright 2017-2025 The MathWorks, Inc. */
'use strict';
/**
 * The favorites Manager is responsible for building and updating the favorites gallery. It
 * communicates with the server and receives information about the different types of favorites etc.
 */

define([
    'dojo/_base/declare',
    'dijit/registry',
    'MW/toolstrip/constants/TypeConstants',
    'MW/toolstrip/constants/gallery/GalleryViewConstants',
    'MW/toolstrip/constants/gallery/ListViewDisplayDensityConstants',
    './FavoriteCommandsDataService',
    './FavoriteCommandsEditorManager',
    './FavoriteCommandActions',
    './CategoryEditorManager',
    './CategoryActions',
    './ActionIdConstants',
    'mw-log/Log',
    'dojo/i18n!../l10n/nls/favcommands'
], function (declare, registry, TypeConstants, GalleryViewConstants, ListViewDisplayDensityConstants,
    FavoriteCommandsDataService, FavoriteCommandsEditorManager, FavoriteCommandActions,
    CategoryEditorManager, CategoryActions, ActionIdConstants, Log, favcommandsL10n) {
    const matchesSelector = function (/* Element */ element, /* String */ selector) { // TODO: use domUtils.matchesSelector instead
        let matchesMethod;

        if (!element || !selector) {
            return false;
        }

        if (element.msMatchesSelector) {
            matchesMethod = 'msMatchesSelector';
        } else {
            matchesMethod = 'matches';
        }

        return element[matchesMethod](selector);
    };
    const assign = (typeof Object.assign === 'function')
        ? Object.assign
        : function assign (target, varArgs) { // .length of function is 2
        // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/assign
            if (target == null) { // TypeError if undefined or null
                throw new TypeError('Cannot convert undefined or null to object');
            }

            const to = Object(target);

            for (let index = 1; index < arguments.length; index++) {
                const nextSource = arguments[index];

                if (nextSource != null) { // Skip over if undefined or null
                    for (const nextKey in nextSource) {
                    // Avoid bugs when hasOwnProperty is shadowed
                        if (Object.prototype.hasOwnProperty.call(nextSource, nextKey)) {
                            to[nextKey] = nextSource[nextKey];
                        }
                    }
                }
            }
            return to;
        };
    const parseEventData = function (eventData) {
        let widget; const data = {}; let parent;

        if (eventData.target) {
            parent = registry.byNode(eventData.target).getParent();
            if (matchesSelector(eventData.target, '.mwToolstripPopupContextMenu *')) {
                data.target = parent._lastKnownInvokingNode
                    ? registry.getEnclosingWidget(parent._lastKnownInvokingNode)
                    : null;
                data.source = 'toolstrip_context_menu';
            } else if (eventData.target.getAttribute('data-tag') === 'contextMenuCreateFavorite') {
                data.source = 'commandHistoryContextMenu';
                data.command = eventData.selectedCommands;
            } else {
                throw new Error('Cannot determine either target or source of event.');
            }
        } else if (eventData.id || eventData.detail.widget) {
            widget = registry.byId(eventData.id) || eventData.detail.widget;
            if (matchesSelector(widget.domNode, '.mwToolstripPopupContextMenu *')) {
                parent = widget.getParent();
                data.target = parent._lastKnownInvokingNode
                    ? registry.getEnclosingWidget(parent._lastKnownInvokingNode)
                    : null;
                data.source = 'toolstrip_context_menu';
            } else if (matchesSelector(document.querySelector('[widgetid="' + eventData.id + '"]'), '[data-tag="' + _private._galleryPopupTag + '"] *')) {
                data.target = widget || null;
                data.source = 'favorites_gallery';
            } else {
                throw new Error('Cannot determine either target or source of event.');
            }
        } else {
            throw new Error('Cannot determine either target or source of event.');
        }

        return data;
    };
    const _private = { // _private is essentially a singleton
        // The channel used for communication with the server
        favorites_CHANNEL: '/favoritesChannel',
        _contextMenuManager: null,
        _dataService: null,
        _destroyed: null,

        /* ===== Private Methods ===== */

        _setContextMenuManagerAttr: function (cmManager) {
            // TODO: Come up with a better check when ContextMenuManager.js is created
            if (!(cmManager instanceof Object) || !cmManager.addContextMenuCallback) {
                throw new Error('The provided Context Menu Manager does not implement the addContextMenuCallback method');
            }
            _private._contextMenuManager = cmManager;
        },

        _getContextMenuManagerAttr: function () {
            return _private._contextMenuManager;
        },

        _setDataServiceAttr: function (dataService) {
            if (!(dataService instanceof Object) || !(dataService.model && dataService.category && dataService.favorite)) {
                throw new Error('The provided Data Service does not implement the correct interface');
            }
            _private._dataService = dataService;
        },

        _getDataServiceAttr: function () {
            return _private._dataService;
        },

        _setupFavoriteCommands: async function () {
            _private._initializeEditorDialogs();
            _private._loadFavoriteCommandActions();
            _private._loadCategoryActions();
            _private._renderFavoriteCommandsPopup();
            await _private._initializeActionsManagers();
            _private._populateGallery();
        },

        _initializeEditorDialogs: function () {
            _private._favoriteCommandsEditorManager =
                    new FavoriteCommandsEditorManager({
                        favoriteActionsModule: FavoriteCommandActions,
                        categoryActionsModule: CategoryActions,
                        uiBuilder: _private._uiBuilder
                    });

            _private._categoryEditorManager =
                    new CategoryEditorManager({
                        categoryActionsModule: CategoryActions,
                        uiBuilder: _private._uiBuilder
                    });
        },

        _loadFavoriteCommandActions: function () {
            _private._actionService.loadActions([
                {
                    id: ActionIdConstants.NEW_FAVORITE,
                    enabled: true,
                    text: favcommandsL10n.newFavoriteLabel,
                    callback: function (eventData) {
                        const data = parseEventData(eventData);
                        if (data.target && (data.target.type === 'GalleryItem')) {
                            _private._favoritesDropDownWidget.closeMenu();
                            _private._favoriteCommandsEditorManager.open({ parent: data.target.getParent() });
                            return;
                        }
                        if (data.target && (data.target.type === 'GalleryCategory')) {
                            _private._favoritesDropDownWidget.closeMenu();
                            _private._favoriteCommandsEditorManager.open({ parent: data.target });
                            return;
                        }
                        if (data.target && (data.target.type === 'QABGalleryCategoryButton')) {
                            _private._favoritesDropDownWidget.closeMenu();
                            _private._favoriteCommandsEditorManager.open({ parent: _private._uiBuilder.widgetByTag(data.target.tag.replace('_qab', '')) });
                            return;
                        }
                        if (data.source === 'commandHistoryContextMenu') {
                            _private._favoritesDropDownWidget.closeMenu();
                            if (data.command) {
                                _private._favoriteCommandsEditorManager.open({ code: data.command });
                            } else {
                                _private._favoriteCommandsEditorManager.open();
                            }
                            return;
                        }
                        // g3192063 - Check if the menu is already open before executing the action to ensure a second
                        // click through dijit/a11yclick.js doesn't open another modal dialog.
                        // g3374974 - Check if the menu is already open including the QAB item
                        const qabFavCommandsId = _private._uiBuilder.tagToId('motwToolstrip.matlabTab.code.favCommands_qab');
                        const qabFavCommandsWidget = registry.byId(qabFavCommandsId);

                        if (!_private._favoritesDropDownWidget.isMenuOpen || _private._favoritesDropDownWidget.isMenuOpen() || qabFavCommandsWidget.isMenuOpen()) {
                            _private._favoritesDropDownWidget.closeMenu();
                            _private._favoriteCommandsEditorManager.open();
                        }
                    }
                },
                {
                    id: ActionIdConstants.EDIT_FAVORITE,
                    enabled: true,
                    text: favcommandsL10n.editFavoriteLabel,
                    callback: function (eventData) {
                        const data = parseEventData(eventData);
                        const action = _private._actionService.getAction(data.target.actionId);

                        let tag = data.target.tag;
                        tag = tag.replace('_qab', '');
                        if (_private._getDataServiceAttr().favorite.get(tag).editable === true) {
                            // TODO: Introduce a FavoriteCommandsIconMap to set action.icon
                            // if (action.icon) {
                            // action.icon = FavoriteCommandsIconMap.getName(action.icon);
                            // }
                            action.tag = tag;
                            action.favoriteId = data.target.id;
                            delete action.id;
                            _private._favoritesDropDownWidget.closeMenu();
                            _private._favoriteCommandsEditorManager.open(action);
                        }
                    }
                },
                {
                    id: ActionIdConstants.DELETE_FAVORITE,
                    enabled: true,
                    text: favcommandsL10n.deleteFavoriteLabel,
                    callback: function (eventData) {
                        const data = parseEventData(eventData);

                        let tag = data.target.tag;
                        tag = tag.replace('_qab', '');
                        if (_private._getDataServiceAttr().favorite.get(tag).editable === true) {
                            FavoriteCommandActions.deleteFavorite({
                                source: data.source,
                                favorite: data.target
                            });
                        }
                    }
                }
            ]);
        },

        _loadCategoryActions: function () {
            _private._actionService.loadActions([
                {
                    id: ActionIdConstants.NEW_CATEGORY,
                    enabled: true,
                    text: favcommandsL10n.newCategoryLabel,
                    callback: function () {
                        // g3192063 - Check if the menu is already open before executing the action to ensure a second
                        // click through dijit/a11yclick.js doesn't open another modal dialog.
                        if (!_private._favoritesDropDownWidget.isMenuOpen || _private._favoritesDropDownWidget.isMenuOpen()) {
                            _private._favoritesDropDownWidget.closeMenu();
                            _private._categoryEditorManager.open({ galleryPopupId: _private._galleryPopupId });
                        }
                    }
                },
                {
                    id: ActionIdConstants.EDIT_CATEGORY,
                    enabled: true,
                    text: favcommandsL10n.editCategoryLabel,
                    callback: function (eventData) {
                        const data = parseEventData(eventData);
                        let tag = data.target.tag;
                        tag = tag.replace('_qab', '');
                        const categoryObject = _private._actionService.getAction(data.target.actionId);
                        const categoryData = {};

                        if (_private._getDataServiceAttr().category.get(tag).editable === true) {
                            categoryData.tag = tag;
                            categoryData.title = categoryObject.title;
                            if (categoryObject.icon) {
                                categoryData.icon = categoryObject.icon;
                            }
                            categoryData.isInQAB = !!categoryObject.isInQAB;
                            categoryData.showText = !!categoryObject.showText;
                            categoryData.widget = categoryObject;
                            categoryData.galleryPopupId = _private._galleryPopupId;
                            _private._favoritesDropDownWidget.closeMenu();
                            _private._categoryEditorManager.open(categoryData);
                        }
                    }
                },
                {
                    id: ActionIdConstants.DELETE_CATEGORY,
                    enabled: true,
                    text: favcommandsL10n.deleteCategoryLabel,
                    callback: function (eventData) {
                        const data = parseEventData(eventData);

                        let tag = data.target.tag;
                        tag = tag.replace('_qab', '');
                        if (_private._getDataServiceAttr().category.get(tag).editable === true) {
                            _private._favoritesDropDownWidget.closeMenu();
                            CategoryActions.deleteCategory({
                                category: data.target
                            });
                        }
                    }
                }
            ]);
        },

        _initializeActionsManagers: async function () {
            await FavoriteCommandActions.initialize({
                uiBuilder: _private._uiBuilder,
                actionService: _private._actionService,
                dataService: _private._dataService,
                settingsService: _private._settingsService
            });

            CategoryActions.initialize({
                uiBuilder: _private._uiBuilder,
                actionService: _private._actionService,
                dataService: _private._dataService
            });
        },

        _buildFavoritesButton: function () {
            // TODO: Make it possible for multiple entry points to open the GalleryPopup
            if (!_private._favoritesDropDownId) {
                // TODO: Enable the ability to add Favorite Commands Buttons to more than 1 location
                if (_private._dataService._qe.isTestMode() === true) {
                    _private._favoritesColumnId = _private._uiBuilder.create({
                        type: TypeConstants.COLUMN
                    });

                    _private._favoritesDropDownId = _private._uiBuilder.create({
                        type: TypeConstants.DROP_DOWN_BUTTON,
                        parentId: _private._favoritesColumnId,
                        tag: 'motwToolstrip.matlabTab.code.favCommands',
                        icon: 'favorite_commandWindow',
                        quickAccessIcon: 'favorite_commandWindow',
                        text: favcommandsL10n.favoriteCommandsFavoritesButtonLabel,
                        description: favcommandsL10n.favoriteCommandsFavoritesButtonDescription,
                        mnemonic: 'J',
                        enabled: false
                    });

                    const column = registry.byId(_private._favoritesColumnId);
                    document.getElementById('favCommandsContainer').appendChild(column.domNode);
                } else {
                    _private._favoritesColumnId = _private._uiBuilder.tagToId('motwToolstrip.matlabTab.code.column0');
                    _private._favoritesDropDownId = _private._uiBuilder.tagToId('motwToolstrip.matlabTab.code.favCommands');
                    _private._favoritesButtonParentId = _private._uiBuilder.tagToId('motwToolstrip.matlabTab.code');
                }
            }
        },

        _toggleFavoritesButton: function (show) {
            if (show && !(typeof show === 'boolean')) {
                throw new Error("Input parameter must be of type 'boolean'");
            }

            if (show || !_private._favoritesEnabled) {
                _private._enableFavoritesButton();
            } else {
                _private._disableFavoritesButton();
            }
        },

        _enableFavoritesButton: function () {
            _private._uiBuilder.set(_private._favoritesDropDownId, 'enabled', true); // TODO: Make this enable once released
            _private._favoritesEnabled = true;
        },

        _disableFavoritesButton: function () {
            _private._uiBuilder.set(_private._favoritesDropDownId, 'enabled', false); // TODO: Make this disable once released
            _private._favoritesEnabled = false;
        },

        _renderFavoriteCommandsPopup: function () {
            _private._buildGalleryPopup();
            _private._buildFooter();
        },

        // The favorites tab, section and column have already been defined in the global tab group
        // config file. We have to create the gallery popup.
        _buildGalleryPopup: function () {
            _private._galleryPopupTag = 'motwToolstrip.matlabTab.code.favCommands.popup';

            _private._galleryPopupId = _private._uiBuilder.create({
                tag: _private._galleryPopupTag,
                type: TypeConstants.GALLERY_POPUP,
                galleryItemWidth: 128,
                galleryItemRowCount: 3, // 3
                galleryItemTextLineCount: 1, // 1
                columnCount: 3, // 3
                displayState: GalleryViewConstants.LIST,
                dndEnabled: true,
                favoritesEnabled: false,
                listViewDisplayDensity: ListViewDisplayDensityConstants.COMPACT,
                qabEligible: true,
                iconSize: 16
            });

            // TODO: Make this work when multiple entry points are possible.  Right now, there is no way to add other cmManagers etc...
            _private._cmCallback = function (contextMenuBuilder, targetNode) {
                if (matchesSelector(targetNode,
                    '[data-tag="' + _private._galleryPopupTag + '"] .Item, [data-tag="' + _private._galleryPopupTag + '"] .Item *')) {
                    contextMenuBuilder.addItems(_private._createAndReturnFavoriteContextMenuItems(targetNode));
                } else if (matchesSelector(targetNode,
                    '[data-tag="' + _private._galleryPopupTag + '"] .Category, [data-tag="' + _private._galleryPopupTag + '"] .Category *')) {
                    contextMenuBuilder.addItems(_private._createAndReturnCategoryContextMenuItems(targetNode));
                } else if (_private._isTargetAFavCommandInTheQAB(targetNode)) {
                    // target node is in QAB
                    contextMenuBuilder.addItems(_private._createAndReturnFavoriteContextMenuItems(targetNode));
                } else if (_private._isTargetAFavCommandCategoryInTheQAB(targetNode)) {
                    // target node is in QAB
                    contextMenuBuilder.addItems(_private._createAndReturnCategoryContextMenuItems(targetNode));
                }
            };

            _private._getContextMenuManagerAttr().addContextMenuCallback('[data-tag="' + _private._galleryPopupTag + '"], [data-tag="' + _private._galleryPopupTag + '"] *, [data-type="QuickAccessBar"] *', _private._cmCallback);

            _private._favoritesDropDownWidget = registry.byId(_private._favoritesDropDownId);

            _private._uiBuilder.set(_private._favoritesDropDownId, 'popupId', _private._galleryPopupId);
        },

        _isTargetAFavCommandInTheQAB: function (targetNode) {
            return _private._isTargetNodeRelatedToFavCommands(targetNode, 'FavoriteCommands');
        },

        _isTargetAFavCommandCategoryInTheQAB: function (targetNode) {
            return _private._isTargetNodeRelatedToFavCommands(targetNode, 'FavoriteCommandsCategory');
        },

        _isTargetNodeRelatedToFavCommands: function (targetNode, groupId) {
            const widget = registry.getEnclosingWidget(targetNode);
            if (widget) {
                const actionId = widget.get('actionId');
                if (actionId) {
                    const action = _private._actionService.getAction(actionId);
                    if (action && action.groupId === groupId) {
                        return true;
                    }
                }
            }
            return false;
        },

        _processOptions: function (options) {
            const mergedOptions = {};
            let actionData;

            if (options && Object.keys(options).length > 0) {
                assign(mergedOptions, options);
            }

            if (mergedOptions.actionId) {
                mergedOptions.callback = function (e) {
                    _private._actionService.executeAction(mergedOptions.actionId, e);
                };

                actionData = _private._actionService.getAction(mergedOptions.actionId);
                if (actionData && Object.keys(actionData).length > 0) {
                    assign(mergedOptions, actionData);
                }
            }

            if (mergedOptions.id) {
                // We don't care about id's, and we don't want to get into a registration conflict
                // with other widgets.
                delete mergedOptions.id;
            }

            if (Object.prototype.hasOwnProperty.call(mergedOptions, 'iconOverride')) {
                mergedOptions.icon = mergedOptions.iconOverride;
            }

            if (Object.prototype.hasOwnProperty.call(mergedOptions, 'descriptionOverride')) {
                mergedOptions.description = mergedOptions.descriptionOverride;
            }

            return mergedOptions;
        },

        _createAndReturnFavoriteContextMenuItems: function (targetNode) {
            // Create context Menu Item description objects array
            const cmArray = [];
            const targetWidget = registry.getEnclosingWidget(targetNode);

            if (targetWidget.type !== 'QABPushButton') {
                cmArray.push(_private._processOptions({
                    type: TypeConstants.LIST_ITEM,
                    tag: 'motwToolstrip.favoritesGallery.favoriteContextMenu.newFavorite',
                    text: 'New Favorite Command',
                    iconOverride: '',
                    descriptionOverride: '',
                    actionId: ActionIdConstants.NEW_FAVORITE,
                    section: 'general-commands'
                }));
            }

            let tag = targetWidget.get('tag');
            tag = tag.replace('_qab', '');

            if (_private._getDataServiceAttr().favorite.get(tag).editable === true) {
                cmArray.push(_private._processOptions({
                    type: TypeConstants.LIST_ITEM,
                    tag: 'motwToolstrip.favoritesGallery.favoriteContextMenu.editFavorite',
                    text: 'Edit Favorite Command',
                    actionId: ActionIdConstants.EDIT_FAVORITE,
                    section: 'modification-commands'
                }));

                cmArray.push(_private._processOptions({
                    type: TypeConstants.LIST_ITEM,
                    tag: 'motwToolstrip.favoritesGallery.favoriteContextMenu.deleteFavorite',
                    text: 'Delete Favorite Command',
                    actionId: ActionIdConstants.DELETE_FAVORITE,
                    section: 'modification-commands'
                }));
            }

            return cmArray;
        },

        _createAndReturnCategoryContextMenuItems: function (targetNode) {
            // Create context Menu

            const cmArray = [];
            const targetWidget = registry.getEnclosingWidget(targetNode);

            if (targetWidget.type !== 'QABGalleryCategoryButton') {
                cmArray.push(_private._processOptions({
                    type: TypeConstants.LIST_ITEM,
                    tag: 'motwToolstrip.favoritesGallery.categoryContextMenu.newCategory',
                    text: 'New Category',
                    iconOverride: '',
                    descriptionOverride: '',
                    actionId: ActionIdConstants.NEW_CATEGORY,
                    section: 'general-commands'
                }));
            }

            cmArray.push(_private._processOptions({
                type: TypeConstants.LIST_ITEM,
                tag: 'motwToolstrip.favoritesGallery.categoryContextMenu.newFavorite',
                text: 'New Favorite Command',
                iconOverride: '',
                descriptionOverride: '',
                actionId: ActionIdConstants.NEW_FAVORITE,
                section: 'general-commands'
            }));

            let tag = targetWidget.get('tag');
            tag = tag.replace('_qab', '');

            if (_private._getDataServiceAttr().category.get(tag).editable === true) {
                cmArray.push(_private._processOptions({
                    type: TypeConstants.LIST_ITEM,
                    tag: 'motwToolstrip.favoritesGallery.categoryContextMenu.renameCategory',
                    text: 'Edit Category',
                    actionId: ActionIdConstants.EDIT_CATEGORY,
                    section: 'modification-commands'
                }));

                cmArray.push(_private._processOptions({
                    type: TypeConstants.LIST_ITEM,
                    tag: 'motwToolstrip.favoritesGallery.categoryContextMenu.deleteCategory',
                    text: 'Delete Category',
                    actionId: ActionIdConstants.DELETE_CATEGORY,
                    section: 'modification-commands'
                }));
            }

            return cmArray;
        },

        // The favorites gallery popup shows a footer with two push buttons to create a new favorite
        // or a new category.
        _buildFooter: function () {
            const footerId = _private._uiBuilder.create({
                type: TypeConstants.FOOTER
            });
            const footerCellId = _private._uiBuilder.create({
                type: TypeConstants.FOOTER_CELL,
                parentId: footerId
            });

            _private._uiBuilder.create({
                type: TypeConstants.PUSH_BUTTON,
                tag: 'motwToolstrip.favoritesGallery.footer.newFavorite',
                description: favcommandsL10n.newFavoriteDescription,
                icon: 'icon_new_favorite_16',
                parentId: footerCellId,
                actionId: ActionIdConstants.NEW_FAVORITE
            });

            _private._uiBuilder.create({
                type: TypeConstants.PUSH_BUTTON,
                tag: 'motwToolstrip.favoritesGallery.footer.newCategory',
                description: favcommandsL10n.newCategoryDescription,
                icon: 'icon_new_favorite_category_16',
                parentId: footerCellId,
                actionId: ActionIdConstants.NEW_CATEGORY
            });

            _private._uiBuilder.set(_private._galleryPopupId, 'footerId', footerId);
        },

        _populateGallery: function () {
            _private._getDataServiceAttr().model.load(_private._messageReceived.bind(_private));
        },

        // This is called anytime a message is received from the server
        _messageReceived: function (message) {
            const isMigration = (message && message.source === 'migration' && message.firstLoadAfterMigration === undefined);
            if (isMigration) {
                _private._getDataServiceAttr().model.updateFirstLoadAfterMigration();
            }
            const createFavoritePromises = [];
            if (message.version === _private._getDataServiceAttr().model.getVersion()) {
                // Track the ids of the favorites that have been created
                const favoriteIdsProcessed = [];
                // Create categories and item from the given data
                message.layout.categories.forEach(function (categoryId) {
                    const category = message.data.categories[categoryId];
                    category.tag = categoryId;
                    category.galleryPopupId = _private._galleryPopupId;
                    // If the source of the data received is migration, we want to serialize the data
                    const widgetId = CategoryActions.createCategory(category, true, isMigration);
                    const favoriteIds = message.layout.favorites[categoryId];
                    favoriteIds.forEach(function (favoriteId) {
                        const favorite = message.data.favorites[favoriteId];
                        // Only create the favorite if it exists in the data and has not been processed yet
                        if (favorite && !favoriteIdsProcessed.includes(favoriteId)) {
                            favoriteIdsProcessed.push(favoriteId);
                            favorite.tag = favoriteId;
                            favorite.parentId = widgetId;
                            createFavoritePromises.push(FavoriteCommandActions.createFavorite(favorite, true, isMigration));
                        }
                    });
                }, _private);
            }
            // TODO: confirm that we need to enable button regardless of event type, or do we want to be explicit
            _private._toggleFavoritesButton(true);
            Promise.allSettled(createFavoritePromises).then(() => {
                this._uiBuilder.lazyLoadQABItems('FavoriteCommands');
                this._uiContainer._favCommandsLoadedInQab = true;
                this._uiContainer.emit('favCommandsLoadedInQab');
            });
        }
    };

    return declare([], {
        /* ===== Public Methods ===== */
        constructor: function (args) {
            this.updateRequiredServices(args);

            // TODO: Replace this logic with "config file button" on toolstrip once released
            _private._buildFavoritesButton();

            _private._settingsService.getSetting(
                ['matlab', 'desktop'], 'MOFavoriteCommandsEnabled'
            ).then(function (data) {
                // _favoritesEnabled used to determine whether to enable or disable when toggleFavorites() is called
                _private._favoritesEnabled = false;

                if (data.value === true) {
                    _private._setupFavoriteCommands();
                }

                // TODO: Find a way to dynamically toggle toolstrip button based on settings api
            });

            _private._destroyed = false;
        },

        updateRequiredServices: function (args) {
            if (args.actionService) {
                this.set('actionService', args.actionService);
            } else if (!this.get('actionService')) {
                Log.assert(args.actionService,
                    'actionService is required by FavoritesManager');
            }

            if (args.uiBuilder) {
                this.set('uiBuilder', args.uiBuilder);
            } else if (!this.get('uiBuilder')) {
                Log.assert(args.uiBuilder, 'uiBuilder is required by FavoritesManager');
            }

            // TODO: Remove this dependency before final ship
            if (args.settingsService) {
                this.set('settingsService', args.settingsService);
            } else if (!this.get('settingsService')) {
                Log.assert(args.settingsService, 'settingsService is required by FavoritesManager');
            }

            if (args.contextMenuManager) {
                this.set('contextMenuManager', args.contextMenuManager);
            } else if (!this.get('contextMenuManager')) {
                // TODO: Generalize this so that FC do not rely on the Toolstrip for a ContextMenu
                if (this.get('uiBuilder').tagToId('motwToolstrip')) {
                    this.set('contextMenuManager', this.get('uiBuilder').widgetByTag('motwToolstrip'));
                } else {
                    Log.assert(args.contextMenuManager, 'contextMenuManager is required by FavoritesManager');
                }
            }

            if (args.uiContainer) {
                this.set('uiContainer', args.uiContainer);
            }

            if (args.dataService) {
                if (args.dataService === 'test') {
                    this.set('dataService', FavoriteCommandsDataService);
                    FavoriteCommandsDataService._qe.isTestMode(true);
                    return;
                }
                this.set('dataService', args.dataService);
            } else {
                this.set('dataService', FavoriteCommandsDataService);
            }
        },

        set: function (property, value) {
            switch (property) {
                case 'actionService':
                    // TODO: create a setter method in _private
                    _private._actionService = value;
                    break;
                case 'uiBuilder':
                    // TODO: create a setter method in _private
                    _private._uiBuilder = value;
                    break;
                case 'settingsService':
                    // TODO: create a setter method in _private
                    _private._settingsService = value;
                    break;
                case 'contextMenuManager':
                    _private._setContextMenuManagerAttr(value);
                    break;
                case 'dataService':
                    _private._setDataServiceAttr(value);
                    break;
                case 'uiContainer':
                    _private._uiContainer = value;
                    break;
            }
        },

        get: function (property) {
            let retVal;

            // Use "break" instead of "return" directly in order to prevent refactoring in future if more processing is needed
            switch (property) {
                case 'destroyed':
                    retVal = _private._destroyed;
                    break;
                case 'actionService':
                    // TODO: create a getter method in _private
                    retVal = _private._actionService;
                    break;
                case 'uiBuilder':
                    // TODO: create a getter method in _private
                    retVal = _private._uiBuilder;
                    break;
                case 'settingsService':
                    // TODO: create a getter method in _private
                    retVal = _private._settingsService;
                    break;
                case 'contextMenuManager':
                    retVal = _private._getContextMenuManagerAttr();
                    break;
                case 'dataService':
                    retVal = _private._getDataServiceAttr();
                    break;
                default:
                    retVal = undefined;
                    break;
            }

            return retVal;
        },

        destroy: function destroy () {
            if (this.get('dataService')._qe.isTestMode() === true) {
                document.getElementById('favCommandsContainer').innerHTML = '';
                delete _private._favoritesDropDownId;
                delete _private._favoritesColumnId;
                const gp = document.getElementById(_private._galleryPopupId);
                if (gp) {
                    gp.parentElement.removeChild(gp);
                }
            } else {
                this.get('uiBuilder').destroy(_private._favoritesDropDownId);
                this.get('uiBuilder').destroy(_private._favoritesColumnId);
                this.get('uiBuilder').destroy(_private._galleryPopupId);
            }
            FavoriteCommandActions.destroyRTCInstance();
            this.get('contextMenuManager').removeContextMenuCallback('[data-tag="' + _private._galleryPopupTag + '"], [data-tag="' + _private._galleryPopupTag + '"] *', _private._cmCallback);
            this.get('dataService').model.close();
            this.inherited(destroy, arguments);
            _private._destroyed = true;
        }
    });
});
