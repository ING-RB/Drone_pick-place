function imageComponent = uiimage(varargin)
%UIIMAGE Create image component
%   im = UIIMAGE creates an image component in a new figure and returns the
%   image object. MATLAB calls the uifigure function to create the figure.
%
%   im = uiimage(Name,Value) specifies image property values using
%   one or more Name,Value pair arguments.
%
%   im = uiimage(parent) creates an image in the specified parent
%   container. The parent container can be a figure created using the
%   uifigure function, or one of its child containers: Tab, Panel, or ButtonGroup.
%
%   im = uiimage(parent,Name,Value) creates the image in the
%   specified container and sets one or more image property values.
%
%   Example 1: Create an image
%      fig = uifigure;
%      im = uiimage(fig);
%
%   Example 2: Set ImageSource for image
%      fig = uifigure;
%      im = uiimage(fig);
%      im.ImageSource = 'peppers.png';
%
%   Example 3: Set ScaleMethod for image
%      fig = uifigure;
%      im = uiimage(fig);
%      im.ScaleMethod = 'fill';
%
%   See also UIFIGURE, IMSHOW

%   Copyright 2018 The MathWorks, Inc.

args.className = 'matlab.ui.control.Image';

args.functionName = 'uiimage';

args.userInputs = varargin;

try
    imageComponent = matlab.ui.control.internal.model.ComponentCreation.createComponent(args);
catch ex
    error('MATLAB:ui:Image:unknownInput', ...
        ex.message);
end
