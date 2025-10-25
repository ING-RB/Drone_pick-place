/**
 * @file Converts an HTML DOM to HTML markup.
 * 
 * This script is intended to be used by an instance of the MATLAB
 * Report Generator's HTMLFilePrepper class to convert an HTML file
 * to the DOM API's DOM. The script assumes that the HTML file
 * has previously been loaded into the HTML browser in which this
 * script is running. The script generates HTML markup from the
 * HTML DOM representation of the file's body element.
 */

// Copyright 2019-2024 The MathWorks, Inc.

/** Instance of the DOM writer.
 * @type {HTMLDOMWriter}
 */
var htmlDOMWriter;
(function(query) {

    const computedCSSProperties = [
        "background-color",
        "border-bottom-color",
        "border-bottom-style",
        "border-bottom-width",
        "border-left-color",
        "border-left-style",
        "border-left-width",
        "border-right-color",
        "border-right-style",
        "border-right-width",
        "border-top-color",
        "border-top-style",
        "border-top-width",
        "color",
        "counter-increment",
        "counter-reset",
        // "display",
        "font-family",
        "font-size",
        "font-style",
        "font-weight",
        "line-height",
        "list-style-type",
        "margin-bottom",
        "margin-left",
        "margin-right",
        "margin-top",
        "padding-bottom",
        "padding-left",
        "padding-right",
        "padding-top",
        "text-align",
        "text-decoration",
        "text-indent",
        "vertical-align",
        "white-space"
    ];

    const definedCSSProperties = [
        "height",
        "width"
    ];

    /** Generates HTML markup from DOM body element.*/
    class HTMLDOMWriter {
        constructor(htmlRoot) {
            /** Recursively generate markup. */
            this.markup = this.buildMarkup(htmlRoot, '');
        }

        /** 
         * Recursively build markup from a DOM element.
         * @param {Node} domElem - DOM element
         */
        buildMarkup(domElem, markup) {
            let elemName = domElem.nodeName.toLowerCase();

            if ((elemName === "script") || (elemName === "style")) {
                return markup;
            }

            markup = markup + '<' + elemName;

            /**
             * Generate attribute markup for this element
             * (except style attribute, see below).
             */
            const attrs = domElem.attributes;
            for (let i = 0; i < attrs.length; i++) {
                const attrName = attrs[i].name;
                if (attrName != 'style') {
                    const attrValue = attrs[i].value;
                    markup = markup + ' ' + attrName + '="' + attrValue + '"';
                }
            }

            /** Generate style markup for this DOM element. */
            let style = getComputedStyle(domElem);
            let styleMarkup = '';
            for (const propName of computedCSSProperties) {
                const propValue = style.getPropertyValue(propName);

                /** Replace double with single quotes in property value.
                 * This is necessary to avoid cases, such as
                 * style="font-family:"Times New Roman""
                 */
                const value = propValue.replace(/"/g, "'");
                styleMarkup = styleMarkup + propName + ':' + value + ';';
            }
            for (const propName of definedCSSProperties) {
                const propValue = domElem.style[propName];
                if ((propValue !== undefined ) && (propValue.length > 0)) {
                    const value = propValue.replace(/"/g, "'");
                    styleMarkup = styleMarkup + propName + ':' + value + ';';
                }
            }

            /**
             * counter-reset and counter-increment are supported by html2dom but
             * are not computed by Chrome.
             */
            const resetValue = domElem.style.counterReset;
            if (resetValue) {
                styleMarkup = styleMarkup + 'counter-reset:' + resetValue + ';';
            }

            const incrValue = domElem.style.counterIncrement;
            if (incrValue) {
                styleMarkup = styleMarkup + 'counter-increment:' + incrValue + ';';
            }

            if (styleMarkup) {
                markup = markup + ' style="' + styleMarkup + '"';
            }

            markup = markup + '>';

            /** Build element content markup */

            let nodeList = domElem.childNodes;
            for (let i = 0; i < nodeList.length; i++) {
                let childNode = nodeList[i];

                if (childNode.nodeType == 3) { 
                    /**
                     * Child node is a text node. Add its content to
                     * the markup.
                     */
                    markup = markup +  childNode.nodeValue
                        .replace(/&/g, "&amp;")
                        .replace(/>/g, "&gt;")
                        .replace(/</g, "&lt;");
                } else {

                    if (childNode.nodeType == 1) {

                        /** Child node is a DOM element. Add its markup
                         * to the markup.
                         */
                        markup = this.buildMarkup(childNode, markup);
                    }
                }
            }

            markup = markup + '</' + elemName + '>';
            return markup;
        }

        getHTMLMarkup() {
            return this.markup;
        }
    }

    htmlDOMWriter = new HTMLDOMWriter(document.getElementsByTagName("body")[0]);

})(htmlDOMWriter || (htmlDOMWriter = {}));
htmlDOMWriter.getHTMLMarkup();