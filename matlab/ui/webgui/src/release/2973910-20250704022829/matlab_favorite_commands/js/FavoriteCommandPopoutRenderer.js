/* Copyright 2021 The MathWorks, Inc. */
define([
    'MW/popout/PopoutRenderer'
], function (PopoutRenderer) {
    class FavoriteCommandPopoutRenderer extends PopoutRenderer {
        constructor (options) {
            super();

            this._validateOptions(options);
        }

        _validateOptions (options) {
            if (!options.syntaxHighlighter) {
                throw new Error('Expected syntax highlighter in FavoriteCommandPopoutRenderer constructor args');
            } else if (!options.syntaxHighlighter.getDocument || !options.syntaxHighlighter.getView) {
                throw new Error('Expected options.syntaxHighlighter to have a getDocument and getView method');
            } else {
                this.syntaxHighlighter = options.syntaxHighlighter;
            }
        }

        getSyntaxHighlighter () {
            return this.syntaxHighlighter;
        }

        async createPopoutContents (contents) {
            let contentDiv = document.createElement('div');
            contentDiv.className = 'favoriteCommandPopoutContent';

            if (contents.label || contents.text) {
                let headerDiv = this._createHeader(contents);
                contentDiv.appendChild(headerDiv);
            }

            if (contents.code) {
                let descriptionDiv = await this._createDescription(contents);
                contentDiv.appendChild(descriptionDiv);
            }

            return contentDiv;
        }

        _createHeader (contents) {
            let header = document.createElement('div');
            if (contents.icon) {
                let iconDiv = document.createElement('div');
                iconDiv.className = 'favoriteCommandPopoutIcon';
                iconDiv.classList.add(contents.icon);
                header.appendChild(iconDiv);
            }

            let label = document.createElement('div');
            label.className = 'favoriteCommandPopoutLabel';
            label.textContent = contents.label || contents.text;

            header.appendChild(label);

            header.className = 'favoriteCommandPopoutHeader';

            return header;
        }

        async _createDescription (contents) {
            let descriptionNode = await this._getSyntaxHighlightedDescription(contents);
            descriptionNode.classList.add('favoriteCommandPopoutDescription');

            return descriptionNode;
        }

        async _getSyntaxHighlightedDescription (contents) {
            let rtcDocument = await this.syntaxHighlighter.getDocument();
            rtcDocument.setText(contents.code);

            let rtcView = this.syntaxHighlighter.getView();
            let container = rtcView.createStyledContainer();
            let syntaxHighlightedDomNode = rtcView.getDomtarget();
            syntaxHighlightedDomNode.tabIndex = -1;

            syntaxHighlightedDomNode = syntaxHighlightedDomNode.cloneNode(true);
            container.appendChild(syntaxHighlightedDomNode);

            let descriptionNode = container.cloneNode(true);

            return descriptionNode;
        }
    }

    return FavoriteCommandPopoutRenderer;
});
