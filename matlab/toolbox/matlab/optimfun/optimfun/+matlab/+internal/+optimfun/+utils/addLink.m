function [taggedString,openTag,closeTag] = addLink(linkedText,toolboxName, ... 
                                                   linkAnchor,isCSH)
%

%ADDLINK add a hyperlink to a string for display in the MATLAB Command
%Window.
%
%   taggedString = addLink(linkedText,toolboxName,linkAnchor,isCSH) takes
%   an input string (linkedText) and wraps it in html tags that execute a
%   MATLAB command to open the documentation browser to a specified
%   location (linkAnchor) in the Optimization or Global Optimization
%   Toolbox documentation, depending on what "short name" (e.g. 'optim') is
%   provided by input toolboxName. The result (taggedString) can be
%   inserted in any text printed to the MATLAB Command Window (e.g. error,
%   MException, warning, fprintf).

%   Copyright 2009-2019 The MathWorks, Inc.

if feature('hotlinks') && ~isdeployed   
    windowType = '';
    if isCSH
        windowType = ',''CSHelpWindow''';
    end
    % Create explicit char array so as to avoid translation
    openTag = sprintf('<a href = "matlab: helpview(''%s'',''%s''%s);">',...
        toolboxName,linkAnchor,windowType);
    closeTag = '</a>';
    taggedString = [openTag linkedText closeTag];
else
    taggedString = linkedText;
    openTag = '';
    closeTag = '';
end
