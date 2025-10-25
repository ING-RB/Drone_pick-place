/*
 Copyright 2021-2024 The MathWorks, Inc.
*/
'use strict';
define([
    'dojo/_base/declare',
    'dojo/parser',
    'dojo/ready',
    'dijit/_WidgetBase',
    'dijit/_TemplatedMixin',
    'dijit/_AttachMixin',
    'mw-form/PushButton',
    'dojo/i18n!hwmgrshared-util-lib/l10n/gen/resources/hwmanagerapp/nls/hwmgrshared',
    'dojo/text!../html/PopUpTableTemplate.html',
    'mw-icons/Icon'
], function (declare, parser, ready, _WidgetBase, _TemplatedMixin, _AttachMixin, PushButton, resourceBundle, templateStr, Icon) {
    const widgetClass = declare('AddonsPopUpTable', [_WidgetBase, _TemplatedMixin, _AttachMixin], {

        templateString: templateStr,
        AccordionPane: null,
        AddonData: null,
        LinkCallback: null,
        openTable: false,

        postCreate: function () {
            this.tableHeader.innerText = resourceBundle.AddonsTableHeaderTxt; // "Try installing the following addons if you don't see your device:";
        },

        _removeAllRows: function () {
            const parent = this.addonsTable;
            while (parent.firstChild) {
                parent.removeChild(parent.firstChild);
            }
        },

        _insertRow: function (addon) {
            // Add a table tow to the addons table, and then add

            if (addon.installed) {
                return;
            }

            const newRow = document.createElement('tr');
            newRow.classList.add('mw-hwmgr-popuptable-addonrow');

            // Create the addon status table cell
            const addonStatusTableData = document.createElement('td');

            // Create the add on name table cell
            const addonNameTableData = document.createElement('td');
            addonNameTableData.classList.add('mw-hwmgr-popuptable-addontabledata');

            // Create the add on install button table cell
            const installButtonTableData = document.createElement('td');
            installButtonTableData.classList.add('mw-hwmgr-popuptable-addoninstalllink');

            // Create the icon image
            const iconImg = document.createElement('div');
            iconImg.classList.add('mw-hwmgr-popuptable-addonstatusiconnotinstalled');
            iconImg.innerHTML = `<mw-icon icon-id='warning' icon-width='16' icon-height='16'></mw-icon>`;

            // Create the add on name
            const addonName = document.createElement('p');
            addonName.innerText = addon.name;
            addonName.classList.add('mw-hwmgr-popuptable-addonNametext');

            // Create the install button
            const installButton = document.createElement('button');
            installButton.innerText = resourceBundle.InstallButtonTxt;
            installButton.classList.add('mw-hwmgr-popuptable-installbutton');

            installButtonTableData.appendChild(installButton);

            const basecode = addon.basecode;
            installButton.onclick = (e) => {
                const installAddonEvent = { Action: 'clientInstallAddon', Data: basecode };
                this.LinkCallback(installAddonEvent);
                e.preventDefault();
                e.stopPropagation();
                return false;
            };

            installButton.setAttribute('data-tag', 'installbutton-' + basecode);

            // Add the icon, name and install buttons to the table cells
            addonStatusTableData.appendChild(iconImg);
            addonNameTableData.appendChild(addonName);

            // Add the cells to the rows
            newRow.appendChild(addonStatusTableData);
            newRow.appendChild(addonNameTableData);
            newRow.appendChild(installButtonTableData);

            // Add the row to the table
            this.addonsTable.appendChild(newRow);
        },

        applyAddonsData: function (pageData) {
            this._removeAllRows();
            this.AddonData = pageData.RequiredAddons;
            this.AddonData.forEach(addon => {
                this._insertRow(addon);
            });
        },

        setLinkCallback: function (cb) {
            this.LinkCallback = cb;
        }
    });

    ready(function () {
        // Call the parser manually so it runs after our widget is defined, and page has finished loading
        parser.parse();
    });
    return widgetClass;
});
