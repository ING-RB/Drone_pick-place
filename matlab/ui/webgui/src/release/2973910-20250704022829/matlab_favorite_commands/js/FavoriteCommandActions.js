/* Copyright 2021-2025 The MathWorks, Inc. */

/* '*
 * This object defines the actions associated with favorite commands.
 */

define([
    'dijit/registry',
    'mw-utils/Utils',
    'MW/toolstrip/constants/TypeConstants',
    'mw-mvm/UserMvm',
    'mw-mvm/RunOptions',
    'mw-log/Log',
    'rtc/RichTextComponentFactory',
    'rtc/RichTextComponentFeatureEnum',
    './FavoriteCommandPopoutRenderer'
], function (registry, Utils, TypeConstants, UserMVM, RunOptions, Log,
    RichTextComponentFactory, RichTextComponentFeatureEnum, FavoriteCommandPopoutRenderer) {
    const favoriteActionsModule = {};
    const executeInMatlab = function (favoriteAction) {
        const mvm = UserMVM.getMVM();
        const evalPromise = mvm.eval(favoriteAction.code, new RunOptions());

        evalPromise.then(function (successMessage) {
            // do nothing
        }, function (error) {
            Log.warn(
                'Eval request in FavoriteCommandActions failed for action: ' +
                    favoriteAction.text + ' with the error: ' + error);
        });
    };
    const createFavoriteAction = function (favorite, actionService) {
        const callbackFcn = function () {
            executeInMatlab(actionService.getAction(favorite.tag));
        };

        const action = {
            id: favorite.tag,
            enabled: true,
            label: favorite.label,
            text: favorite.text,
            icon: favorite.icon,
            quickAccessIcon: favorite.icon,
            parentId: favorite.parentId,
            isInQAB: favorite.isInQAB,
            showText: favorite.showText,
            code: favorite.code,
            popoutRenderer: favorite.popoutRenderer,
            groupId: 'FavoriteCommands',
            groupIdForLazyLoadingQABItems: 'FavoriteCommands',
            callback: callbackFcn
        };

        actionService.addAction(action);

        return action.id;
    };
    let uiBuilder;
    let actionService;
    let dataService;
    let settingsService;
    let favoriteCommandPopoutRenderer;
    let rtcInstance = null;

    favoriteActionsModule.initialize = async function (options) {
        uiBuilder = options.uiBuilder;
        actionService = options.actionService;
        dataService = options.dataService;
        settingsService = options.settingsService;
        rtcInstance = await favoriteActionsModule.createRTCInstance();
        favoriteCommandPopoutRenderer = new FavoriteCommandPopoutRenderer({ syntaxHighlighter: rtcInstance });
    };

    favoriteActionsModule.createRTCInstance = async function () {
        const rtcArguments = {
            features: [
                RichTextComponentFeatureEnum.SYNTAX_HIGHLIGHTING
            ],
            dependencies: {
                'rtc.settings.backingservice': settingsService
            },
            enabled: [
                'rtc.backgroundforegroundcolor'
            ],
            containerElement: document.createElement('div')
        };

        const rtc = await RichTextComponentFactory.createRTC(rtcArguments);

        return rtc;
    };

    favoriteActionsModule.destroyRTCInstance = function () {
        if (rtcInstance !== null) {
            rtcInstance.destroy();

            // reset the instance variable
            rtcInstance = null;
        }
    };

    favoriteActionsModule._getRTCInstance = function () {
        return rtcInstance;
    };

    favoriteActionsModule.createFavorite = async function (options, skipSerialization, isMigration) {
        // Options: { text | icon | code | editable |
        //            parentId | isFavorite }
        // Enhancements: { bkgColor }
        return new Promise((resolve, reject) => {
            try {
                if (options.icon === 'Favorite Command Icon') {
                    options.icon = 'icon_favorite_command_16';
                }

                options.label = options.label || '';
                options.icon = options.icon || 'icon_favorite_command_16';
                options.code = options.code || '';
                options.text = options.label || options.code;
                options.editable = options.editable || true;
                // empty string here will likely error out,
                // but default value is complex due to Dojo widget id logic
                options.parentId = options.category || options.categoryId || options.parentId || '';
                options.type = TypeConstants.GALLERY_ITEM;
                options.tag = options.tag || ('FAV_' + Utils.generateUuid());

                // uiBuilder.lazyLoadQABItems('FavoriteCommands') call in FavoriteCommandManager.js will handle setting the
                // isInQAB and showText properties correctly along with the order of QAB widgets from the previous session. Skip
                // setting these properties when restoring favorite commands on open lifecycle of MO/JSD.
                if (!isMigration) {
                    options.isInQAB = skipSerialization ? false : (options.isInQAB || false);
                    options.showText = skipSerialization ? false : (options.showText || false);
                }

                options.popoutRenderer = options.popoutRenderer || favoriteCommandPopoutRenderer;
                options.actionId = createFavoriteAction(options, actionService);
                delete options.popoutRenderer; // uiBuilder appears to clone objects passed in via options
                // to maintain and reuse one copy of the RTC, only provide it on the action

                const itemId = uiBuilder.create(options);

                favoriteActionsModule.setPopoutContent(options);

                options.index = uiBuilder.indexOf(itemId);

                const qabFavPropSetCBs = {};

                const synchronizeProperties = async function (propertyName, newValue, oldValue) {
                    if (propertyName === 'isInQAB') {
                        const tag = uiBuilder.get(itemId, 'tag');
                        const widget = uiBuilder.widgetByTag(tag);
                        const qabFavId = uiBuilder.tagToId(tag + '_qab');

                        if (newValue && !oldValue) {
                            qabFavPropSetCBs[qabFavId] = uiBuilder.addPropertySetCallback(qabFavId, async function (evtData) {
                                if (evtData.property === 'showText') {
                                    dataService.favorite.set(tag, { showText: evtData.newValue });
                                    await favoriteActionsModule.updateFavorite(itemId, {
                                        isInQAB: newValue,
                                        showText: evtData.newValue,
                                        tag,
                                        widget
                                    });
                                }
                            });
                        } else if (!newValue && oldValue && Object.prototype.hasOwnProperty.call(qabFavPropSetCBs, qabFavId) && qabFavPropSetCBs[qabFavId].remove) {
                            qabFavPropSetCBs[qabFavId].remove();
                            delete qabFavPropSetCBs[qabFavId];
                        }

                        // Trigger the action update after adding/removing the 'showText' listener
                        dataService.favorite.set(tag, { isInQAB: newValue });
                        await favoriteActionsModule.updateFavorite(itemId, {
                            isInQAB: newValue,
                            showText: newValue ? !!uiBuilder.get(qabFavId, 'showText') : false,
                            tag,
                            widget
                        });
                    }
                };

                if (options.isInQAB) {
                    const tag = uiBuilder.get(itemId, 'tag');
                    const widget = uiBuilder.widgetByTag(tag);
                    const qabFavId = uiBuilder.tagToId(tag + '_qab');
                    qabFavPropSetCBs[qabFavId] = uiBuilder.addPropertySetCallback(qabFavId, async function (evtData) {
                        if (evtData.property === 'showText') {
                            dataService.favorite.set(tag, { showText: evtData.newValue });
                            await favoriteActionsModule.updateFavorite(itemId, {
                                isInQAB: uiBuilder.get(itemId, 'isInQAB'),
                                showText: evtData.newValue,
                                tag,
                                widget
                            });
                        }
                    });
                }

                actionService._actionById(options.actionId).addEventListener('propertySet', async function (eventData) {
                    if ((eventData.originator === 'QABManager_Restore') || (eventData.data.key === 'isInQAB')) {
                        synchronizeProperties(eventData.data.key, eventData.data.newValue, eventData.data.oldValue);
                    }
                });

                if (options.showText) {
                    const correspondingQABWidget = uiBuilder.widgetByTag(options.tag + '_qab');
                    if (correspondingQABWidget) {
                        // Show the label of the corresponding QAB widget
                        uiBuilder.set(correspondingQABWidget.get('id'), 'showText', true);
                    }
                }

                if (!skipSerialization) {
                    dataService.favorite.create(options);
                }

                resolve(itemId);
            } catch (error) {
                Log.error(error);
                reject(error);
            }
        });
    };

    favoriteActionsModule.updateFavorite = async function (itemId, options) {
        let correspondingQABWidget;
        if (itemId) {
            correspondingQABWidget = uiBuilder.widgetByTag(options.tag + '_qab');
            if (correspondingQABWidget) {
                if (correspondingQABWidget.get('id') === itemId) {
                    // itemId is the id of the corresponding QAB Widget.
                    // Get the id of the GalleryItem within the Favorite Commands GalleryPopup.
                    const item = uiBuilder.widgetByTag(options.tag);
                    if (item && item.get('id')) {
                        itemId = item.get('id');
                    }
                }
            }

            const tag = options.tag;

            // Corresponding QAB widget's tag has a suffix "_qab". Not deleting the tag from options causes an event
            // to get fired from the peermodel code when the action gets updated which has a consequence where
            // the tag of the corresponding QAB widget gets changed (_qab suffix gets removed and it gets the same
            // tag as the GalleryItem).
            delete options.tag;

            actionService.updateAction(tag, options);

            // Adding the tag back to the options
            options.tag = tag;
            if (options.label || options.code) {
                await favoriteActionsModule.setPopoutContent(options);
            }

            if (correspondingQABWidget === undefined) {
                correspondingQABWidget = uiBuilder.widgetByTag(options.tag + '_qab');
            }

            if (correspondingQABWidget) {
                if (options.isInQAB) {
                    // Show/hide corresponding QAB widget's label depending on showText checkbox value
                    uiBuilder.set(correspondingQABWidget.get('id'), 'showText', options.showText);
                }
            }

            // g3162554 - Remove and add the item only when the category of the favorite command is being changed
            if (options.parentId && options.parentId !== uiBuilder.getParentId(itemId)) {
                uiBuilder.remove(itemId);
                uiBuilder.add(itemId, options.parentId);
            }

            options.index = uiBuilder.indexOf(itemId);
            dataService.favorite.set(options.tag, options);
        } else {
            await favoriteActionsModule.createFavorite(options);
        }
    };

    favoriteActionsModule.setPopoutContent = async function (options) {
        const itemId = uiBuilder.tagToId(options.tag);

        const actionId = uiBuilder.get(itemId, 'actionId');
        const renderer = actionService._actionById(actionId).getProperty('popoutRenderer');
        const contents = await renderer.createPopoutContents(options);

        uiBuilder.set(itemId, 'popoutContents', { contents });
    };

    favoriteActionsModule.deleteFavorite = function (options) {
        let tag = options.favorite.tag;
        tag = tag.replace('_qab', '');

        actionService.removeAction(tag);

        uiBuilder.remove(uiBuilder.tagToId(tag));
        uiBuilder.destroy(uiBuilder.tagToId(tag));

        if (options.favorite.isInQAB) {
            // Remove and destroy the corresponding QAB widget
            uiBuilder.remove(uiBuilder.tagToId(tag + '_qab'));
            uiBuilder.destroy(uiBuilder.tagToId(tag + '_qab'));
        }

        dataService.favorite.delete(tag);
    };

    return favoriteActionsModule;
});
