/* Copyright 2018-2022 The MathWorks, Inc. */

/**
 * This object defines the actions associated with categories.
 */
define([
    'dijit/registry',
    'mw-utils/Utils',
    'mw-notifications/Notifications',
    'mw-html-utils/HtmlUtils',
    'MW/toolstrip/constants/TypeConstants'
], function (registry, Utils, Notifications, HtmlUtils, TypeConstants) {
    const categoryActions = {};
    let uiBuilder;
    let actionService;
    let dataService;

    const createCategoryAction = function (category, actionService) {
        const actionObj = {
            id: category.tag,
            enabled: true,
            label: category.label,
            icon: category.icon,
            quickAccessIcon: category.icon,
            parentId: category.parentId,
            isInQAB: category.isInQAB,
            showText: category.showText,
            groupId: 'FavoriteCommandsCategory',
            groupIdForLazyLoadingQABItems: 'FavoriteCommands'
        };

        actionService.addAction(actionObj);

        return actionObj.id;
    };

    categoryActions.initialize = function (options) {
        uiBuilder = options.uiBuilder;
        actionService = options.actionService;
        dataService = options.dataService;
    };

    categoryActions.createCategory = function (categoryOptions, skipSerialization, isMigration) {
        if (['Help Browser Favorites'].indexOf(categoryOptions.title) > -1) {
            return;
        }
        if (categoryOptions.icon === 'Category Icon') {
            categoryOptions.icon = 'icon_favorite_category_16';
        }
        categoryOptions.title = categoryOptions.title ||
                                categoryOptions.label ||
                                ''; // TODO: Figure out a default name
        categoryOptions.icon = categoryOptions.icon || 'icon_favorite_category_16';
        categoryOptions.type = TypeConstants.GALLERY_CATEGORY;
        categoryOptions.hideWhenEmpty = false;
        categoryOptions.dndEnabled = true;
        categoryOptions.editable = categoryOptions.editable || true;

        categoryOptions.tag = categoryOptions.tag || ('CAT_' + Utils.generateUuid());

        // uiBuilder.lazyLoadQABItems('FavoriteCommands') call in FavoriteCommandManager.js will handle setting the
        // isInQAB and showText properties correctly along with the order of QAB widgets from the previous session. Skip
        // setting these properties when restoring favorite commands on open lifecycle of MO/JSD.
        categoryOptions.isInQAB = skipSerialization && !isMigration ? false : (categoryOptions.isInQAB || false);
        categoryOptions.showText = skipSerialization && !isMigration ? false : (categoryOptions.showText || false);

        categoryOptions.parentId = categoryOptions.galleryPopupId;

        categoryOptions.actionId = createCategoryAction(categoryOptions, actionService);

        const categoryId = uiBuilder.create(categoryOptions);

        uiBuilder.addEventCallback(categoryId, function (eventData) {
            const tag = uiBuilder.get(eventData.itemId, 'tag');
            if (eventData.eventType === 'categoryMoved') {
                dataService.category.set(tag, { index: eventData.newIndex });
            } else if (eventData.eventType === 'itemMoved') {
                const parentTag = uiBuilder.get(eventData.parentId, 'tag');

                actionService.updateAction(tag, { parentId: eventData.parentId });
                dataService.favorite.set(tag, {
                    parentTag,
                    parentId: eventData.parentId,
                    index: eventData.newIndex
                });
            }
        });

        const qabCatPropSetCBs = {};

        const synchronizeProperties = (propertyName, newValue, oldValue) => {
            if (propertyName === 'isInQAB') {
                const tag = uiBuilder.get(categoryId, 'tag');
                const widget = uiBuilder.widgetByTag(tag);
                const qabCatId = uiBuilder.tagToId(tag + '_qab');

                dataService.category.set(tag, { isInQAB: newValue });
                categoryActions.updateCategory({
                    isInQAB: newValue,
                    showText: newValue ? !!uiBuilder.get(qabCatId, 'showText') : false,
                    tag,
                    widget
                });

                if (newValue && !oldValue) {
                    qabCatPropSetCBs[qabCatId] = uiBuilder.addPropertySetCallback(qabCatId, function (evtData) {
                        if (evtData.property === 'showText') {
                            dataService.category.set(tag, { showText: evtData.newValue });
                            categoryActions.updateCategory({
                                isInQAB: newValue,
                                showText: evtData.newValue,
                                tag,
                                widget
                            });
                        }
                    });
                } else if (!newValue && oldValue && Object.prototype.hasOwnProperty.call(qabCatPropSetCBs, qabCatId) && qabCatPropSetCBs[qabCatId].remove) {
                    qabCatPropSetCBs[qabCatId].remove();
                    delete qabCatPropSetCBs[qabCatId];
                }
            }
        };

        if (categoryOptions.isInQAB) {
            const tag = uiBuilder.get(categoryId, 'tag');
            const widget = uiBuilder.widgetByTag(tag);
            const qabCatId = uiBuilder.tagToId(tag + '_qab');
            qabCatPropSetCBs[qabCatId] = uiBuilder.addPropertySetCallback(qabCatId, function (evtData) {
                if (evtData.property === 'showText') {
                    dataService.category.set(tag, { showText: evtData.newValue });
                    categoryActions.updateCategory({
                        isInQAB: uiBuilder.get(categoryId, 'isInQAB'),
                        showText: evtData.newValue,
                        tag,
                        widget
                    });
                }
            });
        }

        actionService._actionById(categoryOptions.actionId).addEventListener('propertySet', (eventData) => {
            if ((eventData.originator === 'QABManager_Restore') || (eventData.data.key === 'isInQAB')) {
                synchronizeProperties(eventData.data.key, eventData.data.newValue, eventData.data.oldValue);
            }
        });

        // When a category is created from the FC Editor, we do not have access to the galleryPopupId
        if (!categoryOptions.galleryPopupId) {
            categoryOptions.galleryPopupId = uiBuilder.tagToId('motwToolstrip.matlabTab.code.favCommands.popup');
            uiBuilder.set(categoryId, 'galleryPopupId', categoryOptions.galleryPopupId);
            uiBuilder.add(categoryId, categoryOptions.galleryPopupId);
        }

        /* currently commenting this out because new category popup closes the favorite
           commands gallery popup. */
        // TODO: once MO matches the desktop behavior then do scroll into view in a cleaner way.
        // Make the new category visible
        // categoryWidget.domNode.scrollIntoView(true);

        // Create an object that contains all needed category properties
        const categoryObject = JSON.parse(JSON.stringify(categoryOptions));
        categoryObject.id = categoryId;

        if (categoryOptions.showText) {
            const correspondingQABWidget = uiBuilder.widgetByTag(categoryOptions.tag + '_qab');
            if (correspondingQABWidget) {
                // Show the label of the corresponding QAB widget
                uiBuilder.set(correspondingQABWidget.get('id'), 'showText', true);
            }
        }

        if (!skipSerialization) {
            dataService.category.create(categoryOptions);
        }

        return categoryId;
    };

    categoryActions.updateCategory = function (categoryObject) {
        const properties = ['title', 'icon', 'isInQAB', 'showText'];
        const categoryTag = categoryObject.tag || (categoryObject.widget ? categoryObject.widget.tag : '');
        let categoryId = uiBuilder.tagToId(categoryTag);

        if (!categoryId) {
            categoryActions.createCategory(categoryObject);
        } else if (dataService.category.get(categoryTag).editable === true) {
            properties.forEach(function (prop) {
                if (Object.prototype.hasOwnProperty.call(categoryObject, prop)) {
                    uiBuilder.set(categoryId, prop, categoryObject[prop]);
                }
            });

            let correspondingQABWidget = uiBuilder.widgetByTag(categoryTag + '_qab');
            if (correspondingQABWidget) {
                if (correspondingQABWidget.get('id') === categoryId) {
                    // categoryId is the id of the corresponding QAB Widget.
                    // Get the id of the GalleryCategory within the Favorite Commands GalleryPopup.
                    const category = uiBuilder.widgetByTag(categoryTag);
                    if (category && category.get('id')) {
                        categoryId = category.get('id');
                    }
                }
            }

            const tag = categoryObject.tag;

            // Corresponding QAB widget's tag has a suffix "_qab". Not deleting the tag from options causes an event
            // to get fired from the peermodel code when the action gets updated which has a consequence where
            // the tag of the corresponding QAB widget gets changed (_qab suffix gets removed and it gets the same
            // tag as the GalleryCategory).
            delete categoryObject.tag;
            actionService.updateAction(tag, categoryObject);

            // Adding the tag back to the categoryObject
            categoryObject.tag = tag;

            if (correspondingQABWidget === undefined) {
                correspondingQABWidget = uiBuilder.widgetByTag(categoryTag + '_qab');
            }

            if (correspondingQABWidget) {
                if (categoryObject.isInQAB) {
                    // Show/hide corresponding QAB widget's label depending on showText checkbox value
                    uiBuilder.set(correspondingQABWidget.get('id'), 'showText', categoryObject.showText);
                }
            }

            categoryObject.index = uiBuilder.indexOf(categoryId);

            dataService.category.set(categoryTag, categoryObject);
        }
    };

    categoryActions.deleteCategory = function (args) {
        let tag = args.category.tag;
        tag = tag.replace('_qab', '');
        const id = uiBuilder.tagToId(tag);

        if (dataService.category.get(tag).editable === true) {
            const title = 'Delete Category';
            const message = HtmlUtils.escapeHtml('Are you sure you want to delete category: "' + args.category.title + '", and all of the favorite commands it contains?');
            const options = {
                closeCallback: function (e) {
                    if (e.response === 1) {
                        const childIds = uiBuilder.getChildrenIds(id);

                        if (childIds && (childIds.length > 0)) {
                            childIds.forEach(function (childId) {
                                uiBuilder.destroy(childId);
                            }, this);
                        }

                        uiBuilder.remove(id);
                        if (args.category._removeConfigurationLayoutListeners) {
                            args.category._removeConfigurationLayoutListeners();
                        }
                        uiBuilder.destroy(id);

                        if (args.category.isInQAB) {
                            // Remove and destroy the corresponding QAB widget
                            uiBuilder.remove(uiBuilder.tagToId(tag + '_qab'));
                            uiBuilder.destroy(uiBuilder.tagToId(tag + '_qab'));
                        }

                        actionService.removeAction(tag);

                        dataService.category.delete(tag);
                    }
                }
            };

            const dialog = Notifications.displayConfirmDialog(title, message, options);
            dialog.domNode.classList.add('mwDeleteFavoritesCategoryConfirmation');
        }
    };

    categoryActions.tagFromId = function (id) {
        let tag = null;
        const target = document.getElementById(id) || registry.byId(id);

        if (target) {
            // eslint-disable-next-line no-undef
            if (target instanceof Element && target.hasAttribute('data-tag')) {
                tag = target.getAttribute('data-tag');
            } else if (target.domNode) {
                tag = target.get('tag');
            }
        }
        return tag;
    };

    categoryActions.getCategoriesArrayForComboBox = function () {
        const allCats = dataService.model.get().layout.categories; // model v1.0.0
        const catsArr = [];

        allCats.forEach(function (tag) {
            catsArr.push({ label: dataService.category.get(tag).label, value: tag });
        });

        return catsArr;
    };

    return categoryActions;
});
