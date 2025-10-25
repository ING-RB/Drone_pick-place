function fontname(varargin)
%FONTNAME Change font name for objects in a figure
%   FONTNAME(fname) sets the font name of all text associated with the 
%   current figure. Use listfonts for a list of available system fonts.
%   
%   FONTNAME("default") resets the font name back to default font name
%   values for text within the current figure.
%
%   FONTNAME(obj,...) sets the font name for a specific graphics object or 
%   an array of graphics objects that contain text. If obj contains other 
%   graphics objects, such as a figure that contains UI components or an 
%   axes that has a legend, fontname sets the font name for all of the text 
%   associated with objects within obj. 
%
%   See also FONTSIZE, LISTFONTS, UISETFONT.

%   Copyright 2021-2024 The MathWorks, Inc.

import matlab.graphics.chart.internal.inputparsingutils.peelFirstArgParent
[parent, args] = peelFirstArgParent(varargin);
if ~isempty(parent)
    narginchk(2,2);
else
    narginchk(1,1);
    parent = gcf;
end
fname = args{1};

matlab.graphics.internal.mustBeValidGraphicsInFigure(parent(:))
mustBeTextScalar(fname)
mustBeValidFontName(fname)

% Find objects with public FontName property
allObjs = findall(parent,'-property','FontName');

% Some text objects are internal only (e.g. tiledlayout labels, legend 
% title.) We need to pull these in explicitly.
axesManagedChildren = matlab.graphics.internal.getAxesManagedTextObjects(allObjs);
legCBManagedChildren = matlab.graphics.internal.getLegendColorbarManagedTextObjects(allObjs);
tiledLayoutText = matlab.graphics.internal.findTiledLayoutText(parent);
allObjs = unique([allObjs; axesManagedChildren'; legCBManagedChildren'; tiledLayoutText]);

% Exclude Axes named children (Titles, Labels) from the list of objects. 
% These get font properties from the Axes and we should not be setting them 
% directly. Legends & Colorbars do NOT get FontName from axes when they
% have manual font names so we do need to set those directly.
objs = allObjs(~ismember(allObjs,axesManagedChildren));

% Set the font name. Setting the fontname to "default" resets the font back
% to its class default.
set(objs,'FontName',fname);

% In the default case, also want to reset the mode property to auto.
if fname == "default"
    % Use "isprop" instead of "findobj" to make sure we reset hidden mode 
    % properties as well as public ones. We need to use allObjs here to
    % assure named children get mode properties reset to auto as well.
    objs_hasMode = allObjs(isprop(allObjs,'FontNameMode'));
    set(objs_hasMode,'FontNameMode','auto');
end
end

%% Function argument validation for font name
function mustBeValidFontName(name)
validFonts = lower(listfonts);
name = lower(name);
if ~ismember(name, validFonts) && ~any(strcmp(name,{'fixedwidth','default'}))
    msg = message('MATLAB:graphics:fontfunctions:BadFont', name);
    warningstatus = warning('OFF', 'BACKTRACE');
    warning(msg);
    warning(warningstatus);
end
end