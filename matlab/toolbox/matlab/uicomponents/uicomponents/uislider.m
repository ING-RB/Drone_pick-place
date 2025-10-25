function sliderComponent = uislider(varargin)
%UISLIDER Create standard slider or range slider component
%   slider = UISLIDER creates a standard slider in a new UI figure window.
%
%   slider = UISLIDER(style) creates a slider of the specified style.
%
%   slider = UISLIDER(parent) specifies the object in which to 
%   create the slider.
%
%   slider = UISLIDER(parent,style) creates a slider of the specified style
%   in the specified parent object.
%
%   slider = UISLIDER( ___ ,Name,Value) specifies slider properties using
%   one or more Name,Value pair arguments. Use this option with any of the
%   input argument combinations in the previous syntaxes.
%
%   Example 1: Create a Slider
%      % Create a standard slider, the default style for a slider.
%      slider = uislider;
%
%   Example 2: Create a Range Slider
%      % Create a range slider by specifying the style as range.
%      slider = uislider('range');
%
%   Example 3: Specify the Parent Object for a Standard Slider
%      fig = uifigure;
%      slider = uislider(fig);
%
%   See also UIFIGURE, UIGAUGE, UIKNOB, UISPINNER

%   Copyright 2017-2023 The MathWorks, Inc.

args.styleNames = { ...
    'slider',...
    'range',...
    };

args.classNames = {...
    'matlab.ui.control.Slider', ...
    'matlab.ui.control.RangeSlider' ...
    };
    
args.defaultClassName = 'matlab.ui.control.Slider';

args.functionName = 'uislider';
args.defaultClassName = 'matlab.ui.control.Slider';

args.userInputs = varargin;

try
    sliderComponent = matlab.ui.control.internal.model.ComponentCreation.createComponentInFamily(args);
catch ex
    error('MATLAB:ui:Slider:unknownInput', ...
        ex.message);
end
