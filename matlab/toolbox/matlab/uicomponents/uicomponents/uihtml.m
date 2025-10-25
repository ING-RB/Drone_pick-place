function component = uihtml(varargin)
%UIHTML Create HTML component
%
% h = uihtml creates an HTML component in a new figure and returns the HTML
% object. MATLAB calls the uifigure function to create the figure. 
% 
% h = uihtml(parent) creates an HTML component in the specified parent
% container. The parent can be a figure created using the uifigure
% function, or one of its child containers.
%
% h = uihtml(___,Name,Value) specifies UI HTML component properties using
% one or more name-value pair arguments. For example,
% 'HTMLSource','./<yourfile>.html' sets the HTML source to an HTML file.
% Specify name-value pairs after all other input arguments.
%
% Example 1: Create HTML and add markup
% 
%   uf = uifigure('Position',[561 497 333 239]);
%   h = uihtml(uf);
%   h.HTMLSource = '<p><b><span style="color:red">Hello</span> <u>World</u>!</b></p>';
%
% Example 2: Create HTML and point it to your file
%    
%   uf = uifigure('Position',[20 20 430 400]);
%   h = uihtml(uf);
%   h.HTMLSource = './yourfile.html';
%
%   See also jsonencode, jsondecode, uifigure

%   Copyright 2019 The MathWorks, Inc.

args.className = 'matlab.ui.control.HTML';

args.functionName = 'uihtml';

args.userInputs = varargin;

try
    component = matlab.ui.control.internal.model.ComponentCreation.createComponent(args);
    
catch ex
    error('MATLAB:ui:HTML:unknownInput', ...
        ex.message);
end
