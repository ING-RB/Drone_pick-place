function hyperlinkComponent = uihyperlink(varargin)
%UIHYPERLINK Create hyperlink component
%   hlink = UIHYPERLINK creates a hyperlink in a new UI figure window.
%
%   hlink = UIHYPERLINK(parent) specifies the object in which to create 
%   the check box.
%
%   hlink = UIHYPERLINK( ___ ,Name,Value) specifies hyperlink properties
%   using one or more Name,Value pair arguments. Use this option with any
%   of the input argument combinations in the previous syntaxes.
%
%   Example 1: Create Hyperlink
%      hlink = uihyperlink;
%      % Specify the Parent Object for a Hyperlink
%      fig = uifigure;
%      hlink = uihyperlink(fig);
%
%   See also UIFIGURE, UIBUTTON, UIIMAGE 

%   Copyright 2020 The MathWorks, Inc.

args.className = 'matlab.ui.control.Hyperlink';

args.functionName = 'uihyperlink';

args.userInputs = varargin;

try
    hyperlinkComponent = matlab.ui.control.internal.model.ComponentCreation.createComponent(args);
catch exc
    error('MATLAB:ui:Hyperlink:unknownInput', ...
        exc.message);
end
