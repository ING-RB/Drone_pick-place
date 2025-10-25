/* JS code for the view of Descriptor card (Add Non-enumerable device card).
Copyright 2021-2024 The MathWorks, Inc. */
'use strict';
define(['mw-widget-api/WidgetBase',
    'mw-widget-api/defineWidget',
    'mw-widget-api/facade/html',
    'mw-tooltip/Tooltips',
    'mw-icons/Icon'
], function (WidgetBase, defineWidget, html, Tooltips, Icon) {
    class DescriptorCard extends WidgetBase {
        constructor (props) {
            super();
            this.selected = false;
        }

        // Example input config parameters
        // const descriptorConfig = {
        //     DeviceTypeIconID: 'modbusWide',
        //     TitleText: "Configure Modbus TCP/IP",
        //     Enabled: "true",
        //     TooltipText: "Configure a Modbus TCP/IP connection"
        // };

        render () {
            return html`<div class="mw-hwmgr-descriptorcard mw-hwmgr-descriptorcard--unselected" @click=${this._handleCardClick}>
                            <div class="mw-hwmgr-descriptorcard__iconSection">
                                <div class="mw-hwmgr-descriptorcard__hwIcon">
                                    <mw-icon icon-id='${this.DeviceTypeIconID}' icon-width='50' icon-height='40'></mw-icon>
                                </div>
                                <div class="mw-hwmgr-descriptorcard__addIcon">
                                    <mw-icon icon-id='new' icon-width='24' icon-height='24'></mw-icon>
                                </div>
                            </div>
                            <div class="mw-hwmgr-descriptorcard__titleSection">
                                <p class="mw-hwmgr-descriptorcard__titleText">${this.TitleText}</p>
                            </div>
                        </div>`;
        }

        firstUpdated () {
            // Add tooltip to the descriptor card
            const cardNode = this.querySelector('.mw-hwmgr-descriptorcard');
            this.TooltipText && this._addTooltip(this.TooltipText, cardNode);
            // If not enabled, grey out the element
            if (!this.Enabled) {
                this.firstElementChild.classList.remove('mw-hwmgr-descriptorcard--unselected');
                this.firstElementChild.classList.add('mw-hwmgr-descriptorcard--disabled');
            }
        }

        _handleCardClick () {
            // emit the cardClick only if the element is Enabled
            if (this.Enabled) {
                this.emit('descriptorCardClick', {}, { bubbles: true });
            }
        }

        _addTooltip (tooltipText, node) {
            if (tooltipText.length === 0) {
                return;
            }

            Tooltips.createTooltip({ referenceNode: node, content: { text: tooltipText } });
        }

        async setSelected (isSelected) {
            // Change the background of the widget to show it as selected or unselected

            // Await for this promise to resolve after rendering is complete.
            await this.updateComplete;

            this.selected = isSelected;
            if (isSelected) {
                this.firstElementChild.classList.remove('mw-hwmgr-descriptorcard--unselected');
                this.firstElementChild.classList.add('mw-hwmgr-descriptorcard--selected');
            } else {
                this.firstElementChild.classList.remove('mw-hwmgr-descriptorcard--selected');
                this.firstElementChild.classList.add('mw-hwmgr-descriptorcard--unselected');
            }
        }
    }

    return defineWidget({
        name: 'mw-hwmgr-descriptor-card',
        widgetClass: DescriptorCard
    });
});
