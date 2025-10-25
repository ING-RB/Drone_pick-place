/* Copyright 2021-2024 The MathWorks, Inc. */
'use strict';
define(['mw-widget-api/WidgetBase',
    'mw-widget-api/defineWidget',
    'mw-widget-api/facade/html',
    'dojo/i18n!hwmgrshared-util-lib/l10n/gen/resources/hwmanagerapp/nls/hwmgrshared',
    'mw-icons/Icon'
], function (WidgetBase, defineWidget, html, hwmgrSharedResourceBundle, Icon) {
    class AddDeviceCard extends WidgetBase {
        constructor () {
            super();
            this.selected = false;
        }

        render () {
            return html`
            <div class="mw-hwmgr-addDevice mw-hwmgr-addDevice-unselected"
            @click=${this._handleCardClick}>
                <div class="mw-hwmgr-addDevice-icon">
                    <mw-icon icon-id='newWide' icon-width='50' icon-height='40'></mw-icon>
                </div>
                <div class="mw-hwmgr-addDevice-text">${hwmgrSharedResourceBundle.AddHardware}</div>
            </div>  
            `;
        }

        _handleCardClick () {
            this.emit('addCardClick', {}, { bubbles: true });
            this.setSelected(true);
        }

        async setSelected (isSelected) {
            // Change the background of the widget to show it as selected or unselected

            // Await for this promise to resolve after rendering is complete.
            await this.updateComplete;

            this.selected = isSelected;
            if (isSelected) {
                this.firstElementChild.classList.remove('mw-hwmgr-addDevice-unselected');
                this.firstElementChild.classList.add('mw-hwmgr-addDevice-selected');
            } else {
                this.firstElementChild.classList.remove('mw-hwmgr-addDevice-selected');
                this.firstElementChild.classList.add('mw-hwmgr-addDevice-unselected');
            }
        }
    }

    return defineWidget({
        name: 'mw-hwmgr-add-device-card',
        widgetClass: AddDeviceCard
    });
});
