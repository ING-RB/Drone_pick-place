define([
    'MW/toolstrip/constants/TypeConstants',
    'preprocessing/toolstrip/ToolstripTags',
    'dojo/i18n!preprocessing/l10n/nls/Toolstrip'
], function (TypeConstants, ToolstripTags, toolstripl10n) {
    const config = {
        tag: 'pa_ui.global_tab_group',
        type: TypeConstants.TAB_GROUP,
        children: [{
            tag: 'pa_ui.home',
            type: TypeConstants.TAB,
            title: toolstripl10n.TabGroupTitle,
            mnemonic: 'H',
            children: [
                { // === File Section ===
                    tag: 'pa_ui.home.file',
                    type: TypeConstants.SECTION,
                    title: toolstripl10n.FileSection,
                    children: [
                        {
                            tag: 'pa_ui.home.file.importColumn',
                            type: TypeConstants.COLUMN,
                            children: [{
                                tag: 'pa_ui.home.file.import',
                                type: TypeConstants.SPLIT_BUTTON,
                                popupTag: 'pa_ui.home.import.popup',
                                actionId: 'import',
                                mnemonic: 'I'
                            }]
                        },
                        {
                            tag: 'pa_ui.home.file.openColumn',
                            type: TypeConstants.COLUMN,
                            children: [{
                                tag: 'pa_ui.home.file.open',
                                type: TypeConstants.PUSH_BUTTON,
                                text: toolstripl10n.Open,
                                icon: 'openFolder',
                                mnemonic: 'O',
                                actionId: 'open_session'
                            }]
                        },
                        {
                            tag: 'pa_ui.home.file.saveColumn',
                            type: TypeConstants.COLUMN,
                            children: [{
                                tag: 'pa_ui.home.file.save',
                                type: TypeConstants.SPLIT_BUTTON,
                                popupTag: 'pa_ui.home.save.popup',
                                text: toolstripl10n.Save,
                                icon: 'saved',
                                mnemonic: 'S',
                                actionId: 'save_session'
                            }]
                        }
                    ]
                },
                { // === Gallery Section ===
                    tag: 'pa_ui.home.gallery',
                    type: TypeConstants.SECTION,
                    title: toolstripl10n.CleaningSection,
                    children: [{
                        tag: 'pa_ui.home.gallery.galleryColumn',
                        type: TypeConstants.COLUMN,
                        children: [{
                            tag: 'pa_ui.home.gallery.galleryColumn.gallery',
                            type: TypeConstants.GALLERY,
                            galleryPopupTag: 'pa_ui.home.gallery.galleryColumn.gallery.popup',
                            mnemonic: 'G'
                        }]
                    }]
                },
                { // === View Section ===
                    tag: 'pa_ui.home.view',
                    type: TypeConstants.SECTION,
                    title: toolstripl10n.ViewSection,
                    children: [{
                        tag: 'pa_ui.home.view.checkboxColumn',
                        type: TypeConstants.COLUMN,
                        children: [
                            {
                                tag: ToolstripTags.LEGEND_CHECKBOX,
                                type: TypeConstants.CHECK_BOX,
                                text: toolstripl10n.ShowLegend,
                                selected: true,
                                actionId: 'toggle_legend',
                                mnemonic: 'L'
                            },
                            {
                                tag: ToolstripTags.SUMMARY_CHECKBOX,
                                type: TypeConstants.CHECK_BOX,
                                text: toolstripl10n.ShowSummary,
                                selected: true,
                                actionId: 'toggle_summary',
                                mnemonic: 'T'
                            }
                        ]
                    }]
                },
                { // === Export Section ===
                    tag: 'pa_ui.home.export',
                    type: TypeConstants.SECTION,
                    title: toolstripl10n.ExportSection,
                    children: [{
                        tag: 'pa_ui.home.export.col',
                        type: TypeConstants.COLUMN,
                        children: [{
                            tag: 'pa_ui.home.export.col.exportButton',
                            type: TypeConstants.SPLIT_BUTTON,
                            popupTag: 'pa_ui.home.export.popup',
                            icon: 'export_data',
                            text: toolstripl10n.ExportData,
                            actionId: 'export_data',
                            mnemonic: 'E'
                        }]
                    }]
                }
            ]
        }]
    };

    const getConfiguration = () => JSON.parse(JSON.stringify(config));

    const getQABGroupConfig = parentId => {
        return {
            type: TypeConstants.QA_GROUP,
            tag: 'qab_group',
            parentId
        };
    };

    const getQABHelpButtonConfig = parentId => {
        return {
            type: TypeConstants.QAB_PUSH_BUTTON,
            tag: 'qab_group.help',
            text: toolstripl10n.Help,
            quickAccessIcon: 'help',
            parentId
        };
    };

    return {
        getConfiguration,
        getQABGroupConfig,
        getQABHelpButtonConfig
    };
});
