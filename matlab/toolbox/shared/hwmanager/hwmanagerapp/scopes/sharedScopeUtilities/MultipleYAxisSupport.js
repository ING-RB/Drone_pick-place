/* Copyright 2020-2024 The MathWorks, Inc.
 *
 * This class adds MultipleYAxis Capabilities
 */
'use strict';
define([
    'dojo/_base/declare',
    'webscopes/axes/Axes'
], function (
    declare,
    Axes
) {
    return declare(Axes, {
        multiYAxisEnabled: false,

        _nextYAxisKey: 1,

        // updates the yAxisKey and colors of the y-axes
        enableMultiYAxis: function () {
            if (this.multiYAxisEnabled) {
                return;
            }
            this.multiYAxisEnabled = true;
            const lines = this.children;
            if (lines.length <= 1) {
                // Currently, there is only one line, no need to add more y axis
                return;
            }
            let ind;
            for (ind = 0; ind < lines.length; ind++) {
                if (ind === 0) {
                    this.getYRuler(ind).color = lines[ind].color;
                    continue;
                }
                // Don't add Y-axis for ind=0, it already exists.
                const newYAxis = this.addYAxis(ind, {}, {});
                // Move line to this y axis
                lines[ind].yAxisKey = ind;

                // Change axis color to line color
                newYAxis.ruler.color = lines[ind].color;
            }
            this._nextYAxisKey = ind++;
        },

        // updates the yAxisKey and colors of the y-axis
        disableMultiYAxis: function () {
            if (!this.multiYAxisEnabled) {
                return;
            }
            this.multiYAxisEnabled = false;

            this._nextYAxisKey = 1;
            const lines = this.children;
            for (let ind = 0; ind < lines.length; ind++) {
                // Move line to default y axis
                const oldKey = lines[ind].yAxisKey;
                lines[ind].yAxisKey = 0;
                if (ind === 0) {
                    // For the first line, keep its Y-axis, reset lebel and set the key to 0
                    this.getYRuler(oldKey).label = undefined;

                    // Base axes class will error if YAxis is changed from 0 to 0
                    if (oldKey !== 0) {
                        this.changeYAxisKey(oldKey, 0);
                    }
                    continue;
                }
                // Following Y-axis are guaranteed to have a non-zero key, so no conflict
                this.removeYAxis(oldKey);
            }

            // If there is no line, simply reset axis key if necessary
            if (lines.length === 0 && this.getYRuler().key !== 0) {
                this.changeYAxisKey(this.getYRuler().key, 0);
            }
            // Make sure the default Y ruler has the default color
            this.getYRuler().color = 'auto';
            // Make sure the legend is realigned
            this.updateLegendLocation();
        },

        // update the Color of the axis represented by the minorYAxisKey
        updateYRulerColor: function (minorYAxisKey, newColor) {
            if (!this.multiYAxisEnabled) {
                // minor Y axis does not apply to single Y-axis mode
                return;
            }
            // Get the y ruler from YAxisKey
            const yRuler = this.getYRuler(minorYAxisKey);
            if (yRuler === undefined) {
                return;
            }
            yRuler.color = newColor;
        },

        // update the Label of the axis represented by the minorYAxisKey
        setMinorYLabel: function (minorYAxisKey, newMinorYLabel) {
            // Minor Y label is only set in multi Y axis mode
            if (!this.multiYAxisEnabled) {
                return;
            }
            // Get the y ruler from YAxisKey
            const yRuler = this.getYRuler(minorYAxisKey);
            if (yRuler === undefined) {
                return;
            }
            if (yRuler.label === undefined) {
                // Add a new label
                yRuler.addLabel({ string: newMinorYLabel });
            } else {
                // Change string for existing label
                yRuler.label.string = newMinorYLabel;
            }
            this.updateLegendLocation();
        },

        // update the YLimits of the axis represented by the minorYAxisKey
        setMinorYLimits: function (minorYAxisKey, newMinorYLimits) {
            // Minor Y Limits are only set in multi Y axis mode
            if (!this.multiYAxisEnabled) {
                return;
            }
            // Get the y ruler from YAxisKey
            const yRuler = this.getYRuler(minorYAxisKey);
            if (yRuler === undefined) {
                return;
            }
            yRuler.setLimits(newMinorYLimits);
        },

        // update the YScale of the axis represented by the minorYAxisKey
        setMinorYScale: function (minorYAxisKey, newMinorYScale) {
            // Minor Y Scale are only set in multi Y axis mode
            if (!this.multiYAxisEnabled) {
                return;
            }
            // Get the y ruler from YAxisKey
            this._yAxes[minorYAxisKey].dataSpace.scale = newMinorYScale;
        },

        // call the appropriate function based on the flag of the MultipleYAxis
        setEnableMultiYAxis: function (flag) {
            if (flag) {
                this.enableMultiYAxis();
            } else {
                this.disableMultiYAxis();
            }
        },

        // get the YLimits of the axis represented by the minorYAxisKey
        getMinorYLimits: function (minorYAxisKey) {
            // Minor Y Limits are only set in multi Y axis mode
            if (!this.multiYAxisEnabled || this.getYRuler(minorYAxisKey) === undefined) {
                return undefined;
            }
            const minorRuler = this.getYRuler(minorYAxisKey);
            return minorRuler.getLimits();
        },

        // Selected property getters
        // --------------------------------- End -------------------------------

        // Override superclass method to catch error
        // Base Axes class does not validate the key
        getYRuler: function getYRuler () {
            try {
                return this.inherited(getYRuler, arguments);
            } catch (error) {
                return undefined;
            }
        },

        // Override superclass method to add new Y-axis for new line
        // in multi y-axis mode
        addChild: function addChild () {
            const child = this.inherited(addChild, arguments);
            if (this.multiYAxisEnabled) {
                if (this.children.length > 1) {
                    // Add Y-axis if we have more than one line and multi y-axis enabled
                    const axisKey = this._nextYAxisKey;
                    this._nextYAxisKey++;
                    this.addYAxis(axisKey, {}, {});
                    child.yAxisKey = axisKey;
                } else {
                    // If there is only one axis, make sure new line has the same yAxisKey as the axis
                    const axisKey = this.getAllYAxesKeys()[0];
                    child.yAxisKey = axisKey;
                }
            }
            return child;
        },

        // Override superclass method to remove Y-axis for the line
        // in multi y-axis mode
        removeChild: function removeChild (child) {
            this.inherited(removeChild, arguments);
            // In multi y-axis mode
            if (this.multiYAxisEnabled) {
                if (this.getAllYAxesKeys().length >= 2) {
                    // Remove the corresponding y-axis if there are two or more y-axis
                    this.removeYAxis(child.getYAxisKey());
                } else {
                    // If there is only one axis left, only reset the axis specific y label
                    this.setMinorYLabel(child.getYAxisKey(), '');
                }
            }
        },

        // Override superclass method to change default y ruler color
        addYAxis: function addYAxis () {
            const yAxis = this.inherited(addYAxis, arguments);

            this.updateLegendLocation();

            yAxis.ruler.getAutoColor = function () {
                const axes = this.parent;
                if (axes.getAllYAxesKeys().length === 1) {
                    if (axes.colorTheme === 'light') {
                        return '#000000';
                    }
                    return '#afafaf';
                }
                return axes.getColor(this.index);
            };
            return yAxis;
        }
    });
});
