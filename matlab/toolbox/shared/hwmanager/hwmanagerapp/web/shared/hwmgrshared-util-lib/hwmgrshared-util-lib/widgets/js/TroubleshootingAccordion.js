// Copyright 2021-2024 The MathWorks, Inc.
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
    'dojo/text!../html/TroubleshootingAccordionTemplate.html'
], function (declare, parser, ready, _WidgetBase, _TemplatedMixin, _AttachMixin, Button, resourceBundle, templateStr) {
    let widgetClass = declare('TroubleshootingAccordion', [_WidgetBase, _TemplatedMixin, _AttachMixin], {

        templateString: templateStr,
        openHwmgrMsg: resourceBundle.OpenHwmgrMsg, // 'Your device might not work with this app. Open Hardware Manager to see other devices',
        troubleshootingLinksHeader: resourceBundle.TsLinksHeaderTxt, // 'The following troubleshooting links may be helpful:',
        TsLinkCallback: null,
        hwmgrButton: null,

        setHhwmgrButtonCallback: function (cb) {
            this.hwmgrButton.on('click', cb);
        },

        setTsLinkCallback: function (cb) {
            this.TsLinkCallback = cb;
        },

        addLink: function (linkData) {
            this.linksHeaderNode.innerText = this.troubleshootingLinksHeader;
            let linkNode = document.createElement('a');
            linkNode.href = '';
            linkNode.onclick = (e) => {
                const tsLinkEvent = { Action: 'clientOpenTsLink', Data: linkData };
                this.TsLinkCallback(tsLinkEvent);
                e.preventDefault();
                e.stopPropagation();
                return false;
            };
            linkNode.target = '_blank';
            linkNode.innerHTML = linkData.Title;
            linkNode.setAttribute('data-tag', 'tslink-' + linkData.Title);
            this.linksDiv.appendChild(linkNode);
            let br = document.createElement('br');
            this.linksDiv.appendChild(br);
        }

    });

    ready(function () {
        // Call the parser manually so it runs after our widget is defined, and page has finished loading
        parser.parse();
    });
    return widgetClass;
});
