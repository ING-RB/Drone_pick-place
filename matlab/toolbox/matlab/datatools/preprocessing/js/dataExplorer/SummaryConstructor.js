/*
    Copyright 2020-2023 The MathWorks, Inc.
*/

define('preprocessing/dataExplorer/SummaryConstructor', [
    'MW/layout/TabContainer',
    'dijit/layout/ContentPane',
    'preprocessing/dataExplorer/FigureViewCoordinator',
    'mw-messageservice/MessageService',
    'variableeditor_peer/UIVariableEditor',
    'mw-data-model/On',
    'dojo/i18n!preprocessing/l10n/nls/DataExplorer'
], function (TabContainer, ContentPane, FigureViewCoordinator, MessageService, UIVariableEditor, On,
    dataExplorerl10n) {
    'use strict';

    class SummaryConstructor {
        constructor () {
            this.GENERAL_SUMMARY_TABLE_CLASS = 'pa_summary_general';
            this.COLUMN_TABLE_CLASS = 'pa_summary_column';
            this.UIVE_WRAPPER_CLASS = 'pa_summaryUIVE';
        }

        constructHighLevelTable (data) {
            // Construct the table...
            const table = document.createElement('table');
            table.classList.add(this.GENERAL_SUMMARY_TABLE_CLASS);

            const header = table.createTHead();
            header.innerHTML = `<b>${dataExplorerl10n.SummaryTableName}</b>`;

            // ...and populate it with a row per label/value pair.
            for (const label in data.tableStats) {
                const row = table.insertRow();

                const labelCell = row.insertCell();
                labelCell.innerHTML = label;

                const valueCell = row.insertCell();
                valueCell.innerHTML = data.tableStats[label];
            }

            return table;
        }

        // Separated for unit testing.
        _createUIVariableEditor (UIVEArgs) {
            return new UIVariableEditor(UIVEArgs);
        }

        constructUIVariableEditorTable (tableID, wrapperDivParent, wrapperDivID) {
            const wrapperDiv = document.createElement('div');
            wrapperDiv.id = wrapperDivID;
            wrapperDiv.classList.add(this.UIVE_WRAPPER_CLASS);
            wrapperDivParent.appendChild(wrapperDiv);

            const UIVEArguments = {
                UUID: tableID,
                WidgetContainerId: wrapperDivID,
                ResizeBehaviour: 'container'
            };

            return this._createUIVariableEditor(UIVEArguments);
        }
    }

    return SummaryConstructor;
});
