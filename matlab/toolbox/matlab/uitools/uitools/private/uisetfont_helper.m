function fontstruct = uisetfont_helper(varargin)
%

%   Copyright 2007-2020 The MathWorks, Inc.

[fontstruct,title,fhandle] = parseArgs(varargin{:});
c = matlab.ui.internal.dialog.DialogUtils.disableAllWindowsSafely(true);

fcDialog = matlab.ui.internal.dialog.DialogUtils.createFontChooser(title, fontstruct);
fcDialogCleanup = onCleanup(@() delete(fcDialog));

fontstruct = showDialog(fcDialog);
delete(c);
delete(fcDialogCleanup);

if  ~isempty(fhandle)
    setPointFontOnHandle(fhandle,fontstruct);
end

% Done. MCOS Object fcDialog cleans up and its java peer at the end of its
% scope(AbstractDialog has a destructor that every subclass
% inherits)
function [fontstruct,title,handle] = parseArgs(varargin)
handle = [];
fontstruct = [];
title = getString(message('MATLAB:uistring:uisetfont:TitleFont'));
if nargin>2
    error(message('MATLAB:uisetfont:TooManyInputs')) ;
end
if (nargin==2)
    if ~ischar(varargin{2})
        error(message('MATLAB:uisetfont:InvalidTitleType'));
    end
    title = varargin{2};
end
if  (nargin>=1)
    if ishghandle(varargin{1})
        handle = varargin{1};
        fontstruct = getPointFontFromHandle(handle);
    elseif isstruct(varargin{1})
        fontstruct = varargin{1};
    elseif ischar(varargin{1})
        if (nargin > 1)
            error(message('MATLAB:uisetfont:InvalidParameterList'));
        end
        title = varargin{1};
    else
        error(message('MATLAB:uisetfont:InvalidFirstParameter'));
    end
end

%Given the dialog, user chooses to select or not select
function fontstruct = showDialog(fcDialog)
fcDialog.show;
fontstruct = fcDialog.SelectedFont;
if isempty(fontstruct)
    fontstruct = 0;
end


%Helper functions to convert font sizes based on the font units of the
%handle object
function setPointFontOnHandle(fhandle,fontstruct)
tempunits = getPropIfExists(fhandle,'FontUnits');

% For UIComponents like uilabel, FontSize is specified in 'pixels'.
% There is no FontUnits property for such components. Hence, we need to 
% convert the FontSize in 'points' returned by FontChooser to 'pixels'
% before updating these Component. However, there is an exception.
% Handles like the one returned by Xaxis property of an axes object does
% not  have a FontUnits property. But, FontSize is in 'points'. These objects
% should be filtered out.
% g2905772 update: Since FontSmoothing is deprecated, now we only need the if
% condition below to find the uicomponents and do the conversion (also refer to fontsize.m)
isUicomps = isa(fhandle,'matlab.ui.control.Component');
if isstruct(fontstruct) && isUicomps
    fig = ancestor(fhandle,'figure');
    % convert FontSize from pt to px as fhandle does not support pt
    vec = hgconvertunits(fig, [0 0 fontstruct.FontSize, fontstruct.FontSize], 'points', 'pixels', fig);
    fontstruct.FontSize = vec(3);
end
try
    setPropIfExists(fhandle,fontstruct);
catch ex %#ok<NASGU>
end

setPropIfExists(fhandle,'FontUnits',tempunits);

function fs = getPointFontFromHandle(fhandle)
tempunits = getPropIfExists(fhandle,'FontUnits');
setPropIfExists(fhandle, 'FontUnits', 'points');

fs = [];
try       
    fs = addToStructIfPropExists(fhandle, 'FontName',fs);
    fs = addToStructIfPropExists(fhandle, 'FontWeight',fs);
    fs = addToStructIfPropExists(fhandle, 'FontAngle',fs);
    fs = addToStructIfPropExists(fhandle, 'FontUnits',fs);
    fs = addToStructIfPropExists(fhandle, 'FontSize',fs);
catch ex %#ok<NASGU>
end    
if(isempty(fs))
    error(message('MATLAB:uisetfont:NoFontProperties'));
end

% For UIComponents like uilabel, FontSize is specified in 'pixels'.
% There is no FontUnits property for such components. Hence, we need to 
% convert the FontSize in 'pixels' to 'points' as FontChooser accepts only 'points'. 
% However, there is an exception.
% Handles like the one returned by Xaxis property of an axes object does
% not have a FontUnits property. But FontSize is in 'points'. These objects
% should be filtered out.
% g2905772 update: Since FontSmoothing is deprecated, now we only need the if
% condition below to find the uicomponents and do the conversion (also refer to fontsize.m)
isUicomps = isa(fhandle,'matlab.ui.control.Component');
if isstruct(fs) && isUicomps
    fig = ancestor(fhandle,'figure');
    % convert FontSize from px to pt
    vec = hgconvertunits(fig, [0 0 fs.FontSize, fs.FontSize], 'pixels', 'points', fig);
    fs.FontSize = vec(3);
end
setPropIfExists(fhandle, 'FontUnits', tempunits);



function val = getPropIfExists(obj,prop)
val = [];
if isprop(obj,prop)
    val = get(obj,prop);
end

function setPropIfExists(obj,prop,val)
if isstruct(prop)
    for f = fieldnames(prop)'
        setPropIfExists(obj,f{:},prop.(f{:}));
    end
else
    if isprop(obj,prop)
        set(obj,prop,val);
    end
end

function str = addToStructIfPropExists(obj,prop,str)
if isprop(obj,prop)
    str.(prop) = get(obj,prop);
end
