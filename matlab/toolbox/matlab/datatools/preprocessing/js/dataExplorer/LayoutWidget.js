define([
    'mw-widget-api/WidgetBase',
    'mw-widget-api/defineWidget',
    'mw-widget-api/facade/html',
    'mw-log/Log'
], function (WidgetBase, defineWidget, html, Log) {
    'use strict';

    const CONST_COLS = 'cols';
    const CONST_ROWS = 'rows';

    const VALID_LAYOUT_TYPES = [CONST_COLS, CONST_ROWS];
    const DEFAULT_BG_COLOR = 'var(--mw-backgroundColor-primary, var(--mw-color-gray50, #f5f5f5))';

    const COLUMN_LAYOUT_CLASS = 'dc-grid-layout-col';
    const ROW_LAYOUT_CLASS = 'dc-grid-layout-row';
    const COLUMN_WIDGET_CLASS = 'dc-grid-col';
    const ROW_WIDGET_CLASS = 'dc-grid-row';

    const WIDGET_GROUP_CLASS = 'dc-widget-group';
    const WIDGET_LABEL_CLASS = 'dc-grid-widget-label';

    class ContentWidget extends WidgetBase {
        static get properties () {
            return {
                title: {
                    reflect: false,
                    type: String
                },
                id: { // This ContentWidget's ID; this is not the body's ID.
                    reflect: false,
                    type: String
                },
                class: { // This ContentWidget's class; this is not the body's class.
                    reflect: false,
                    type: String
                },
                backgroundColor: {
                    reflect: false,
                    type: String
                },
                bodyId: {
                    reflect: false,
                    type: String
                },
                bodyClass: {
                    reflect: false,
                    type: String
                },
                _content: { // The actual content this widget houses.
                    reflect: false,
                    type: Object
                }
            };
        }

        constructor () {
            super();

            this.title = '';
            // Keep track of the ID and class given to this widget; they _do not automatically apply to
            // the instance of this element_. We do this application in firstUpdated().
            this.id = '';
            this.class = '';
            this.bodyId = null;
            this.bodyClass = '';
            this._content = html``;
            this._percentage = '100%';
        }

        /**
         * Renders this ContentWidget like so:
         * ---------
         * | Title |
         * |-------|
         * |       |
         * |  Body | <- Contains this._content
         * |       |
         * ---------
         */
        render () {
            const titleDiv = this.title !== ''
                ? html`<p class="${WIDGET_LABEL_CLASS}">${this.title}</p>`
                : html``;
            const bodyDiv = html`
                <div id="${this.bodyId}" class="${this.bodyClass}" style="${this.bodyStyle}">
                    ${this._content}
                </div>`;

            const htmlConfig = html`
                ${titleDiv}
                ${bodyDiv}
            `;
            return htmlConfig;
        }

        firstUpdated () {
            // Assert first updated state. Check that input parameters have been correctly provided.
            // This is the earliest possible time to assert user input.
            let assertion = this.title != null && typeof this.title === 'string';
            let assertionMessage = 'this.title does not exist or is not type string';
            Log.assert(assertion, assertionMessage);

            assertion = this.bodyId != null;
            assertionMessage = 'this.bodyId is not assigned a value';
            Log.assert(assertion, assertionMessage);

            assertion = typeof this.bodyId === 'string';
            assertionMessage = 'this.bodyId is not type string';
            Log.assert(assertion, { bodyId: this.bodyId, assertionMessage });

            assertion = this.bodyClass != null && typeof this.bodyClass === 'string';
            assertionMessage = 'this.bodyClass does not exist or is not type string';
            Log.assert(assertion, { bodyClass: this.bodyClass, assertionMessage });

            // Carry on with the first update.
            this.setAttribute('id', this.id);
            this.classList.add(this.class, WIDGET_GROUP_CLASS);
            this.style.backgroundColor = this.backgroundColor;
        }

        /**
         * Overrides appendChild. We don't want users to be able to append any number
         * of children; we want, at most, 1 child.
         *
         * @param {Element} node The child node to append
         */
        appendChild (node) {
            // eslint-disable-next-line no-undef
            if (!(node instanceof Element)) {
                throw new Error('Cannot append non-element node to ContentWidget');
            } // ----------------------------

            this._content = node;
            this.render();
        }

        /**
         * Override this element's getBoundingClientRect to instead return the body element's client rect.
         * @returns The body element's client rect
         */
        getBoundingClientRect () {
            const bodyElement = this.querySelector(`#${this.bodyId}`);
            if (bodyElement) return bodyElement.getBoundingClientRect();
            else return this.firstElementChild.getBoundingClientRect(); // Fallback
        }

        /**
         * Sets the title of this content widget.
         *
         * @param {string} newTitle The new title for this ContentWidget
         */
        setTitle (newTitle) {
            if (newTitle == null || typeof newTitle !== 'string') {
                throw new Error('Content widget title must be a string');
            } // ------------

            this.title = newTitle;
        }

        disconnectedCallback () {
            super.disconnectedCallback();

            // g3168840: Before this Content Widget completely gets destroyed, we must ensure that
            // its content must be destroyed as well. This covers:
            // 1. mw-widgets with a "disconnectedCallback" method that runs after being removed from the DOM.
            // 2. Objects with a "destroy" method.

            // eslint-disable-next-line no-undef
            if (this._content instanceof Element) {
                this._content.remove();
            } else if (this._content instanceof Object) {
                if (typeof this._content.destroy === 'function') this.content.destroy();
            }
        }
    }

    const contentWidget = defineWidget({
        name: 'mw-datatools-datacleaner-contentwidget',
        widgetClass: ContentWidget
    });

    /**
     * The LayoutWidget allows you to create a grid of cells. A LayoutWidget may have any number of
     * rows or columns (mutually exclusive). LayoutWidgets may have an infinite amount of nested LayoutWidgets.
     */
    class LayoutWidget extends WidgetBase {
        static get properties () {
            return {
                layoutType: {
                    reflect: false,
                    type: Boolean
                },
                contentWidgetChildren: {
                    reflect: false,
                    type: Array
                }
            };
        }

        constructor () {
            super();

            this.layoutType = CONST_COLS;
            this.contentWidgetChildren = [];
        }

        /**
         * The LayoutWidget is functionally just a div. The render function uses the layout type
         * to set the appropriate class for this widget.
         */
        render () {
            const usingCols = this.layoutType === CONST_COLS;
            const layoutClass = usingCols ? COLUMN_LAYOUT_CLASS : ROW_LAYOUT_CLASS;
            this.classList.add(layoutClass);

            const htmlConfig = html``;
            return htmlConfig;
        }

        getFirstChild () {
            return this.contentWidgetChildren.length > 0
                ? this.contentWidgetChildren[0]
                : null;
        }

        getLastChild () {
            return this.contentWidgetChildren.length > 0
                ? this.contentWidgetChildren[this.contentWidgetChildren.length - 1]
                : null;
        }

        // Add an empty widget. This is the same as "addWidget", but "content" is always set to null
        // if it isn't already.
        // This exists to make code readability a little easier.
        async addEmptyWidget (params) {
            if (params != null) {
                params.content = null;
                return await this.addWidget(params);
            } else {
                return await this.addWidget({ content: null });
            }
        }

        /**
         * Adds a child Content Widget to this Layout Widget. It automatically gets appended to
         * this Layout Widget and gets returned if you need to make further modifications.
         *
         * @param {object} params Input parameters for the child widget
         * @param {string} params.title (optional) Title for the content widget
         * @param {string} params.backgroundColor (optional) The background color for the content widget
         * @param {string} params.contentBodyId (optional) The ID for the content widget
         * @param {string} params.contentBodyClass (optional) The class for the content widget
         * @param {string} params.contentBodyStyle (optional) The styling for the content widget
         * @returns The new widget
         */
        async addWidget (params) {
            // Run assertions on the input parameters.
            if (params == null) {
                throw new Error('Cannot add widget without parameters');
            } // ----------------

            if (params.title != null && typeof params.title !== 'string') {
                throw new Error('params.title must be a string');
            }
            if (params.backgroundColor != null && typeof params.backgroundColor !== 'string') {
                throw new Error('params.backgroundColor must be a string');
            }
            if (params.contentBodyId != null && typeof params.contentBodyId !== 'string') {
                throw new Error('params.contentBodyId must be a string');
            }
            if (params.contentBodyClass != null && typeof params.contentBodyClass !== 'string') {
                throw new Error('params.contentBodyClass must be a string');
            }
            if (params.contentBodyStyle != null && typeof params.contentBodyStyle !== 'string') {
                throw new Error('params.contentBodyStyle must be a string');
            } // ----------------

            // Use default values if needed.
            const content = params.content;
            const title = params.title || '';
            const contentWidgetId = params.id || '';
            const backgroundColor = params.backgroundColor || DEFAULT_BG_COLOR;
            // eslint-disable-next-line no-undef
            const contentBodyId = params.contentBodyId || self.crypto.randomUUID();
            const contentBodyClass = params.contentBodyClass || '';
            // TODO: "contentBodyStyle" is here solely for working around a UIVariableEditor sizing quirk.
            // It's best to remove it if we can properly size UIVariableEditors.
            const contentBodyStyle = params.contentBodyStyle || 'width:100%;height:100%;';

            // Create and append the child widget.
            const contentWidgetParams = {
                title,
                id: contentWidgetId,
                class: this.contentWidgetClass,
                backgroundColor,
                bodyId: contentBodyId,
                bodyClass: contentBodyClass,
                bodyStyle: contentBodyStyle
            };
            const widgetWrapper = contentWidget(contentWidgetParams);
            if (content) widgetWrapper.appendChild(content);
            this.appendChild(widgetWrapper);

            this.contentWidgetChildren.push(widgetWrapper);
            await this.updateComplete;

            return widgetWrapper;
        }

        /**
         * Sets the layout type for this LayoutWidget.
         *
         * If the layout type is "rows", then this widget's children will be stacked on top of each other:
         * -----
         * |   |
         * |---|
         * |   |
         * |---|
         * |   |
         * -----
         * If the layout type is "cols", then this widget's children will be placed side by side:
         * -------------
         * |   |   |   |
         * |   |   |   |
         * -------------
         *
         * @param {string} layoutType The new layout type for this Layout Widget (either "rows" or "cols")
         */
        setLayoutType (layoutType) {
            const invalidLayoutType = !VALID_LAYOUT_TYPES.some(listing => listing === layoutType);
            if (invalidLayoutType) {
                throw new Error(`layoutType must be either "${CONST_COLS}" or "${CONST_ROWS}"; is ${layoutType}`);
            } // -------------------

            const usingCols = layoutType === CONST_COLS;
            this.contentWidgetClass = usingCols ? COLUMN_WIDGET_CLASS : ROW_WIDGET_CLASS;

            this.layoutType = layoutType;
            this.render(); // Force refresh
        }
    }

    const layoutWidget = defineWidget({
        name: 'mw-datatools-datacleaner-layoutwidget',
        widgetClass: LayoutWidget
    });
    return layoutWidget;
});
