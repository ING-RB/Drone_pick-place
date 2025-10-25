function colorPickerComponent = uicolorpicker(varargin)
%UICOLORPICKER Create color picker component
%   cp = UICOLORPICKER creates a color picker component in a new figure
%   window and returns the ColorPicker object. MATLAB calls the uifigure
%   function to create the figure.
%
%   cp = UICOLORPICKER(parent) creates the color picker component in the
%   specified parent container. The parent can be a Figure object created
%   using the uifigure function or one of its child containers.
%
%   cp = UICOLORPICKER(___,Name,Value) specifies ColorPicker properties
%   using one or more name-value arguments. Use this option with any of the
%   input argument combinations in the previous syntaxes.
%
%   Example 1: Create a color picker
%      fig = uifigure;
%      cp = uicolorpicker(fig);
%
%   Example 2: Set initial value for the color picker
%      fig = uifigure;
%      cp = uicolorpicker(fig);
%      cp.Value = [0 0 1];
%
%   Example 3: Code response to color selection
%      fig = uifigure;
%      cp = uicolorpicker(fig);
%      cp.ValueChangedFcn = @(src,event)display(event);
%
%   See also UISETCOLOR

%   Copyright 2023 The MathWorks, Inc.

args.className = 'matlab.ui.control.ColorPicker';

args.functionName = 'uicolorpicker';

args.userInputs = varargin;

try
    colorPickerComponent = matlab.ui.control.internal.model.ComponentCreation.createComponent(args);
catch ex
    error('MATLAB:ui:ColorPicker:unknownInput', ...
        ex.message);
end