/* Copyright 2021-2024 The MathWorks, Inc. */
'use strict';
define(['mw-widget-api/WidgetBase',
    'mw-widget-api/defineWidget',
    'mw-widget-api/facade/html',
    'mw-tooltip/Tooltips',
    'dojo/i18n!hwmgrshared-util-lib/l10n/gen/resources/hwmanagerapp/nls/hwmgrshared',
    'mw-form/ContextMenu',
    'mw-form/MenuItem',
    'mw-icons/Icon'
], function (WidgetBase, defineWidget, html, Tooltips, hwmgrSharedResourceBundle, ContextMenu, MenuItem, Icon) {
    class DeviceCard extends WidgetBase {
        static get properties () {
            return {
                FriendlyName: { type: String },
                VisibleProperties: { type: Array },
                Uuid: { type: Number },
                IsNonEnumerable: { type: Number },
                IconID: { type: String },
                DeviceHardwareSetupData: { type: Array },
                ShowConfigWarning: { type: Number },
                ShowConfigOption: { type: Number },
                ShowHardwareSetupWarning: { type: Array }
            };
        }

        constructor (props) {
            super();
            this.selected = false;
            this._contextMenu = null;
        }

        // Example input config parameters
        // const config = {
        //     FriendlyName: 'Arduino',
        //     VisibleProperties: [
        //         {
        //             PropLabel: 'Vendor',
        //             PropValue: 'NI'
        //         }, {
        //             PropLabel: 'Version',
        //             PropValue: '1.2.1'
        //         }
        //     ],
        //     Uuid: 1,
        //     IsNonEnumerable: 1,
        //     IconID: ''
        // };

        closeButtonTemplate () {
            return !this.IsNonEnumerable
                ? ''
                : html`
                <div class='mw-hwmgr-devicecard-headerButtons'>
                    <button type='button' class='mw-hwmgr-devicecard-deleteDeviceBtn' 
                        @click=${(e) => this._handleCloseClick(e)}>
                        <mw-icon icon-id='deleteBorderlessUI' icon-width='16' icon-height='16'</mw-icon></button>
                </div>
            `;
        }

        headerTemplate () {
            return html`
                <div class='mw-hwmgr-devicecard-name mw-hwmgr-devicecard-textEllipsis'>
                    ${this.FriendlyName}
                </div>
              `;
        }

        contentTemplate () {
            return html`
                <div class='mw-hwmgr-devicecard-content'>
                    <div class='mw-hwmgr-devicecard-iconDiv'>
                        <div class='mw-hwmgr-devicecard-deviceIcon'>
                            <mw-icon icon-id='${this.IconID}' icon-width='50' icon-height='40'></mw-icon>
                        </div>
                    </div>
                    <div class='mw-hwmgr-devicecard-propFlexParent'>
                        <div class='mw-hwmgr-devicecard-propFlexChild'>
                            ${this.VisibleProperties.map((prop) => html`
                            <p>${prop.PropLabel}: ${prop.PropValue}</p>
                            `)}
                        </div>
                    </div>
                </div>
              `;
        }

        warningTemplate () {
            let showWarning = false;
            let warningText = '';

            // ShowHardwareSetupWarning is an array of values (0's and 1's) indexed
            // identical to DeviceHardwareSetupData.
            // if a ShowHardwareSetupWarning item is 1 (matlab true), the DeviceCard should
            // warn the user that Hardware Setup is needed
            if (this.ShowHardwareSetupWarning.includes(1)) {
                warningText = hwmgrSharedResourceBundle.HardwareSetupNeededWarning;
                showWarning = true;
            }

            if (this.ShowConfigWarning) {
                warningText = hwmgrSharedResourceBundle.ConfigurationNeeded;
                showWarning = true;
            }

            return !showWarning
                ? ''
                : html`
                <div class='mw-hwmgr-devicecard-warning'>
                    <mw-icon icon-id='warningUI' icon-width='16' icon-height='16'></mw-icon>
                    <p>&nbsp;${warningText}</p>
                </div>
            `;
        }

        meatballMenuTemplate () {
            let addMeatballMenu = false;

            if (this.ShowHardwareSetupWarning.includes(1) || this.ShowConfigOption) {
                addMeatballMenu = true;
            }

            return !addMeatballMenu
                ? ''
                : html`
                <div class='mw-hwmgr-devicecard-meatballMenu'>
                    <mw-icon icon-id='meatballMenuUI' icon-width='16' icon-height='16'></mw-icon>
                </div>
            `;
        }

        render () {
            return html`
                <div class='mw-hwmgr-devicecard-hwmDevice mw-hwmgr-devicecard-unselected'
                @click=${this._handleCardClick}>
                    ${this.closeButtonTemplate()}
                    ${this.headerTemplate()}
                    ${this.contentTemplate()}
                    ${this.warningTemplate()}
                    ${this.meatballMenuTemplate()}
                </div>
                `;
        }

        updated () {
            const menuItems = [];
            this.DeviceHardwareSetupData.forEach((item, index) => {
                if (this.ShowHardwareSetupWarning[index]) {
                    const menuItem = new MenuItem({
                        text: item.DisplayName
                    });
                    menuItem.on('click', this._handleSetupHardwareClick.bind(this, item));
                    menuItems.push(menuItem);
                }
            });

            // Add Configuration Option to the meatball menu
            if (this.ShowConfigOption) {
                const menuItem = new MenuItem({
                    text: hwmgrSharedResourceBundle.ConfigureDevice
                });
                menuItem.on('click', this._handleConfigureClick.bind(this));
                menuItems.push(menuItem);
            }

            if (menuItems.length > 0) {
                this._addContextMenu(menuItems);
            }
        }

        firstUpdated () {
            // Add tooltip to Device card name
            const nameNode = this.querySelector('.mw-hwmgr-devicecard-name');
            this._addContentTooltip(nameNode);

            // Find all property nodes and add tooltip
            const propNodes = this.querySelectorAll('.mw-hwmgr-devicecard-propFlexChild>p');
            propNodes.forEach(node => this._addContentTooltip(node));
        }

        _handleSetupHardwareClick (deviceHardwareSetupData) {
            const identifier = deviceHardwareSetupData.IdentifierReference;
            this.emit('launchFeature', { uuid: this.Uuid, identifier }, { bubbles: true });
        }

        _handleCardClick () {
            if (this.ShowConfigWarning) {
                this._handleConfigureClick();
                return;
            }
            this.emit('cardClick', { uuid: this.Uuid }, { bubbles: true });
        }

        _handleCloseClick (e) {
            e.stopPropagation();
            this.emit('requestCardRemoval', { uuid: this.Uuid }, { bubbles: true });
        }

        _handleConfigureClick () {
            this.emit('cardClickConfigure', { uuid: this.Uuid }, { bubbles: true });
        }

        _addContextMenu (menuItems) {
            const meatballNode = this.querySelector('.mw-hwmgr-devicecard-meatballMenu');

            if (this._contextMenu) {
                // Since Hardware Manager start page could be refreshed, cleanup previous instances.
                this._contextMenu.destroyRecursive();
            }

            // Create ContextMenu at target location
            const contextMenu = new ContextMenu({
                targetNodes: ['.mw-hwmgr-devicecard-meatballMenu']
            });

            menuItems.forEach(item => {
                contextMenu.addChild(item);
            });

            // Open the contextMenu on meatball click
            meatballNode.addEventListener('click', function (e) {
                contextMenu.open({
                    target: meatballNode
                });
                e.stopPropagation();
            });

            this._contextMenu = contextMenu;
        }

        _addContentTooltip (node) {
            // Add a tooltip to the node if content does not fit in the visual portion of the node.
            if (node.clientWidth < node.scrollWidth) {
                Tooltips.createTooltip({ referenceNode: node, content: { text: node.innerText } });
            }
        }

        async setSelected (isSelected) {
            // Change the background of the widget to show it as selected or unselected

            // Await for this promise to resolve after rendering is complete.
            await this.updateComplete;

            this.selected = isSelected;
            if (isSelected) {
                this.firstElementChild.classList.remove('mw-hwmgr-devicecard-unselected');
                this.firstElementChild.classList.add('mw-hwmgr-devicecard-selected');
            } else {
                this.firstElementChild.classList.remove('mw-hwmgr-devicecard-selected');
                this.firstElementChild.classList.add('mw-hwmgr-devicecard-unselected');
            }
        }

        setRemoveButtonSelected (isSelected) {
            const removeButton = this.querySelector('button.mw-hwmgr-devicecard-deleteDeviceBtn');
            if (removeButton == null) {
                return;
            }
            if (isSelected) {
                removeButton.classList.add('mw-hwmgr-devicecard-deleteDeviceBtn-selected');
            } else {
                removeButton.classList.remove('mw-hwmgr-devicecard-deleteDeviceBtn-selected');
            }
        }
    }

    return defineWidget({
        name: 'mw-hwmgr-device-card',
        widgetClass: DeviceCard
    });
});
