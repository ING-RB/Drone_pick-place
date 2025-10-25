define([
    'MW/toolstrip/constants/TypeConstants',
    'preprocessing/toolstrip/ToolstripTags',
    'dojo/i18n!preprocessing/l10n/nls/Toolstrip'
], function (TypeConstants, ToolstripTags, toolstripl10n) {
    const config = {
        popups: [
            {
                tag: ToolstripTags.GALLERY_POPUP,
                type: TypeConstants.GALLERY_POPUP,
                galleryItemWidth: 80,
                children: [
                    {
                        tag: ToolstripTags.CLEAN_CATEGORY,
                        type: TypeConstants.GALLERY_CATEGORY,
                        title: toolstripl10n.CleaningTaskSection,
                        children: [
                            {
                                type: TypeConstants.GALLERY_ITEM,
                                tag: ToolstripTags.CLEAN_MISSING,
                                icon: 'cleanMissingDataApp',
                                text: toolstripl10n.CleanMissing,
                                actionId: 'cleanMissing'
                            },
                            {
                                type: TypeConstants.GALLERY_ITEM,
                                tag: ToolstripTags.CLEAN_OUTLIER,
                                icon: 'cleanOutlierDataApp',
                                text: toolstripl10n.CleanOutlier,
                                actionId: 'cleanOutlier'
                            },
                            {
                                type: TypeConstants.GALLERY_ITEM,
                                tag: ToolstripTags.NORMALIZE,
                                icon: 'normalizeDataApp',
                                text: toolstripl10n.Normalize,
                                actionId: 'normalize'
                            },
                            {
                                type: TypeConstants.GALLERY_ITEM,
                                tag: ToolstripTags.SMOOTH,
                                icon: 'smoothDataApp',
                                text: toolstripl10n.Smooth,
                                actionId: 'smooth'
                            }
                        ]
                    },
                    {
                        tag: ToolstripTags.SYNC_CATEGORY,
                        type: TypeConstants.GALLERY_CATEGORY,
                        title: toolstripl10n.SyncTaskSection,
                        children: [
                            {
                                type: TypeConstants.GALLERY_ITEM,
                                tag: ToolstripTags.RETIME,
                                icon: 'retimeTimetableApp',
                                text: toolstripl10n.Retime,
                                actionId: 'retime'
                            }/*,
                            {
                                type: TypeConstants.GALLERY_ITEM,
                                tag: ToolstripTags.SYNCHRONIZE,
                                icon: 'syncronizeTimetableApp',
                                text: toolstripl10n.Synchronize,
                                actionId: 'synchronize'
                            }
                            */
                        ]
                    },
                    {
                        tag: ToolstripTags.RESHAPE_CATEGORY,
                        type: TypeConstants.GALLERY_CATEGORY,
                        title: toolstripl10n.ReshapeTaskSection,
                        children: [
                            {
                                type: TypeConstants.GALLERY_ITEM,
                                tag: ToolstripTags.STACK,
                                icon: 'stackTableVariablesApp',
                                text: toolstripl10n.Stack,
                                actionId: 'stack'
                            },
                            {
                                type: TypeConstants.GALLERY_ITEM,
                                tag: ToolstripTags.UNSTACK,
                                icon: 'unstackTableVariablesApp',
                                text: toolstripl10n.Unstack,
                                actionId: 'unstack'
                            }/*,
                            {
                                type: TypeConstants.GALLERY_ITEM,
                                tag: ToolstripTags.JOIN,
                                icon: 'joinTableApp',
                                text: toolstripl10n.Join,
                                actionId: 'join'
                            }
                            */
                        ]
                    }
                ]
            },
            {
                tag: 'pa_ui.home.export.popup',
                type: TypeConstants.POPUP_LIST,
                maxHeight: 300,
                iconSize: 16,
                children: [
                    {
                        tag: 'pa_ui.home.export.toWorkspace',
                        type: TypeConstants.LIST_ITEM,
                        text: toolstripl10n.ExportToWorkspace,
                        icon: 'export_data',
                        actionId: 'export_data_to_workspace'
                    },
                    {
                        tag: 'pa_ui.home.export.generateScript',
                        type: TypeConstants.LIST_ITEM,
                        text: toolstripl10n.GenerateScript,
                        icon: 'saveAs',
                        actionId: 'export_script'
                    },
                    {
                        tag: 'pa_ui.home.export.generateFunction',
                        type: TypeConstants.LIST_ITEM,
                        text: toolstripl10n.GenerateFunction,
                        icon: 'saveAs',
                        actionId: 'export_function'
                    }
                ]
            },
            {
                tag: 'pa_ui.home.import.popup',
                type: TypeConstants.POPUP_LIST,
                maxHeight: 300,
                iconSize: 16,
                children: [
                    {
                        tag: 'pa_ui.home.import.fromWorkspace',
                        type: TypeConstants.LIST_ITEM,
                        text: toolstripl10n.ImportFromWorkspace,
                        icon: 'import_data',
                        actionId: 'import_from_workspace'
                    },
                    {
                        tag: 'pa_ui.home.import.fromFile',
                        type: TypeConstants.LIST_ITEM,
                        text: toolstripl10n.ImportFromFile,
                        icon: 'downloadFolder',
                        actionId: 'import_from_file'
                    }
                ]
            },
            {
                tag: 'pa_ui.home.save.popup',
                type: TypeConstants.POPUP_LIST,
                maxHeight: 300,
                iconSize: 16,
                children: [
                    {
                        tag: 'pa_ui.home.save.save',
                        type: TypeConstants.LIST_ITEM,
                        text: toolstripl10n.Save,
                        icon: 'saved',
                        actionId: 'save_session'
                    },
                    {
                        tag: 'pa_ui.home.import.saveAs',
                        type: TypeConstants.LIST_ITEM,
                        text: toolstripl10n.SaveAs,
                        icon: 'saved',
                        actionId: 'save_as_session'
                    }
                ]
            }
        ]
    };

    // "getConfiguration" returns a deep copy of this configuration.
    //
    // Let's assume that file A imports this popup config and modifies it in function B.
    // When function C accesses the config, any changes done in function B are still present,
    // but function C may be expecting the config to remain unchanged.
    //
    // This function prevents this situation from occurring.
    const getConfiguration = () => JSON.parse(JSON.stringify(config));

    // Functions to get specific category configurations. These are used by the
    // UIContainer's UIBuilder.
    //
    // Note that the UIBuilder doesn't recursively build components from configurations, i.e.,
    // it ignores the "children" field in category configurations; we must be able to retrieve
    // individual item configurations.
    const attachParentId = (config, parentId) => {
        if (parentId) config.parentId = parentId;
        return config;
    };

    const getSyncCategoryConfig = parentId => {
        const config = getConfiguration().popups[0].children[1];
        return attachParentId(config, parentId);
    };
    const getSyncItemConfig = parentId => {
        const config = getSyncCategoryConfig().children[0];
        return attachParentId(config, parentId);
    };

    const getReshapeCategoryConfig = parentId => {
        const config = getConfiguration().popups[0].children[2];
        return attachParentId(config, parentId);
    };
    const getStackItemConfig = parentId => {
        const config = getReshapeCategoryConfig().children[0];
        return attachParentId(config, parentId);
    };
    const getUnstackItemConfig = parentId => {
        const config = getReshapeCategoryConfig().children[1];
        return attachParentId(config, parentId);
    };

    const getDebugCategoryConfig = parentId => {
        const config = {
            tag: ToolstripTags.DEBUG_CATEGORY,
            type: TypeConstants.GALLERY_CATEGORY,
            title: 'DEBUG'
        };
        return attachParentId(config, parentId);
    };

    const getDebugItemConfig = parentId => {
        const config = {
            type: TypeConstants.GALLERY_ITEM,
            tag: ToolstripTags.CLEAN_MISSING,
            icon: 'cleanMissingDataApp',
            text: 'Debug'
        };
        return attachParentId(config, parentId);
    };

    return {
        getConfiguration,
        getSyncCategoryConfig,
        getSyncItemConfig,
        getReshapeCategoryConfig,
        getStackItemConfig,
        getUnstackItemConfig,
        getDebugCategoryConfig,
        getDebugItemConfig
    };
});
