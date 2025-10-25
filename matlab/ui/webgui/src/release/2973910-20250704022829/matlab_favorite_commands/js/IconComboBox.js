define([
    'dojo/_base/declare',
    'mw-form/ComboBox',
    'mw-form/mixins/property/IconMixin'
], function (declare, ComboBox, IconMixin) {
    return declare([ComboBox, IconMixin], {
        visualFamily: 'default',
        height: 22,

        /*
     * override of method in  "mw-form/ComboBox
     * The _initItems is called from the _setItemsAttr method to create menu items and add them to the
     * menu. After creating the menu items each menu item is assigned Click and Key Down event listeners.
     * This method also adds icons to the left of the text label
     * The method also constructs the "labelValue" and "valueLabel" maps while creating the menu items.
     * */
        _initMenuItems: function (items) {
        // If there are menu items already existing, they will need to be removed
        // from the menu. Also the _labelValue and _valueLabel maps need to be
        // reset to their initial values. The reset part is important because
        // this will ensure news items do not get added to the existing list og
        // maps which would be undesirable.
            if (this.get('menu').getChildren().length > 0) {
                this._destroyMenuItems();
            }
            // Loop over each item from the items array to create a new menu item
            // by using the label of each item as the text for each menu item.
            // The newly created menu item is added to the menu and event listeners
            // are attached to each menu item that listen on click and keydown events.
            items.forEach(function (item, i) {
            // each menu item would have a parent i.e. DOM structure would look like
            //
            //          <div class="mwWidget mwDefaultVisualFamily mwTextMixin mwSharedMenuItem mwMenuItem">
            //               <div class="mwTextNode">Label text content</div>
            //          </div>
            // This is done to keep the styling and tests intact from the MenuItem widgets
            // create the menuItemParent
                var menuItemParent = document.createElement('div');
                if (item.type && item.type === 'separator') {
                    menuItemParent.setAttribute('data-refuse-key-nav', true);
                    menuItemParent.setAttribute('data-menu-item-type', 'separator');
                    menuItemParent.classList.add('mwMenuSeparator');
                    this.get('menu').menuItemsNode.appendChild(menuItemParent);
                } else {
                    menuItemParent.setAttribute('tabIndex', '0');
                    ['mwDefaultVisualFamily', 'mwTextMixin', 'mwTextMixin', 'mwWidget', 'mwSharedMenuItem', 'mwMenuItem'].forEach(function (c) {
                        menuItemParent.classList.add(c);
                    });
                    // create the menuitem
                    var menuItem = document.createElement('div');
                    menuItem.classList.add('mwMenuItemParent');
                    // create iconNode
                    var iconNode = document.createElement('div');
                    iconNode.classList.add('mwIconNode');
                    iconNode.classList.add(item.icon);

                    // create textNode
                    var textNode = document.createElement('div');
                    textNode.classList.add('mwTextNode');
                    textNode.textContent = item.label;
                    // append the menuItem to it's parent
                    menuItem.appendChild(iconNode);
                    menuItem.appendChild(textNode);
                    menuItemParent.appendChild(menuItem);
                    // append the menuItemParent to menu's dom node
                    this.get('menu').menuItemsNode.appendChild(menuItemParent);
                    menuItemParent.addEventListener('mouseover', this._handleMenuItemMouseEnter.bind(this));
                }
            }, this);
        },
        /*
        * override of method in  "mw-form/ComboBox
        * This method handles the click event that occurs on a menu item.
        * The menu item that gets clicked becomes the selected value of the
        * combo box. The text of the menu item(label) is displayed as the value
        * of text field, with the icon to the left of it.
        * */
        _handleMenuClick: function (e) {
            if (this._isSeparator(e.target) || (!e.target.classList.contains('mwMenuItem') && !e.target.classList.contains('mwTextNode'))) {
                e.preventDefault();
                return;
            }
            // Find the item that was selected based on the click target
            var selectedItem = this._getItemForNode(e.target);
            // Determine the value of the corresponding item
            var selectedValue = selectedItem.value;
            var selectedIcon = selectedItem.icon;
            var oldValue = this.get('value');
            this.set('icon', selectedIcon);
            this.set('value', selectedValue);

            if (oldValue !== selectedValue) {
                this._triggerChangeEvent('value', oldValue, selectedValue);
            }
            this.closeMenu();
        },

        buildRendering: function () {
            this.inherited(arguments);
            this._textField.placeAt(this.textFieldContainerNode);
            this.iconNode = document.createElement('div');
            this.iconNode.classList.add('mwIconNode');
            this.textFieldContainerNode.prepend(this.iconNode);
            this.textFieldContainerNode.classList.add('mwArrowContainerNode');
            this.textFieldContainerNode.classList.add('mwTextContainer');
            this.inputNode = this._textField.inputNode;
            // assign domNode of the widget to be the focus node by default
            this.focusNode = this.domNode;
        },

        _setValueAttr: function (value) {
            // If a pre-selected value is passed in as argument and if it is
            // equal to any of the item's value present in the items array, that
            // value becomes the selected value of the combo box in both editable
            // and non-editable cases.
            var selected = this._getSelectedItemFromValue(value);
            if ((typeof value === 'number' ? value.toString() : value) && selected && selected.index !== undefined) {
                var selectedLabel = selected.label;
                this._textField.set('value', selectedLabel);
                this.set('icon', selected.icon);
                this._isTextEmpty = true;
                this._removeSelectedMenuItemColor();
                if (this.get('menu').getChildren().length > 0 && selected.index !== undefined) {
                    this.get('menu').getChildren()[selected.index].classList.add('mwComboBoxSelectedMenuItem');
                }
            } else if ((typeof value === 'number' ? value.toString() : value) && !selected) {
                if (this.get('editable')) {
                    this._removeSelectedMenuItemColor();
                    this._textField.set('value', value);
                    this._isTextEmpty = false;
                } else {
                    if (!this.get('items') || this.get('items').length === 0) { // see g1397593
                        this._pendingValue = value;
                        return;
                    } else {
                        throw new Error('Value must match an existing item for non-editable combo box');
                    }
                }
            } else if (value === '') {
                this._textField.set('value', '');
                if (this._get('value') !== undefined) {
                    this._removeSelectedMenuItemColor();
                    this._isTextEmpty = true;
                }
                if (this.get('text') !== '') {
                    this._isTextEmpty = false;
                }
            }
            if (this._isTextEmpty === true) {
                this.set('text', '');
            } else {
                this.set('text', value);
            }
            this._set('value', value);
        },
        _getSelectedItemFromLabel: function (label) {
            var selectedItem = {};
            if (this.get('items') && this.get('items').length > 0) {
                for (var i = 0; i < this.get('items').length; i++) {
                    var item = this.get('items')[i];
                    if (item.label !== undefined && item.label === label) {
                        selectedItem.label = item.label;
                        selectedItem.value = item.value;
                        selectedItem.icon = item.icon;
                        selectedItem.index = i;
                        break;
                    }
                }
            }
            return selectedItem.index !== undefined ? selectedItem : undefined;
        },

        _getSelectedItemFromValue: function (value) {
            var selectedItem = {};
            if (this.get('items') && this.get('items').length > 0) {
                for (var i = 0; i < this.get('items').length; i++) {
                    var item = this.get('items')[i];
                    // check for object equality also. see g1600969
                    if (item.value !== undefined &&
                        ((item.value === value) ||
                        (typeof item.value === 'object' && JSON.stringify(item.value) === JSON.stringify(value)))) {
                        selectedItem.label = item.label;
                        selectedItem.value = item.value;
                        selectedItem.icon = item.icon;
                        selectedItem.index = i;
                        break;
                    }
                }
            }
            return selectedItem.index !== undefined ? selectedItem : undefined;
        }

    });
});
