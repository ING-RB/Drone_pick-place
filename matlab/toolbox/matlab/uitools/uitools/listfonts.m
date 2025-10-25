function fonts = listfonts(handle)
%LISTFONTS Get list of available system fonts in cell array.
%   C = LISTFONTS returns list of available system fonts.
%
%   C = LISTFONTS(H) returns system fonts with object's FontName
%   sorted into the list.
%
%   Examples:
%     Example1:
%       list = listfonts
%
%     Example2:
%       h = uicontrol('Style', 'text', 'string', 'My Font');
%       list = listfonts(h)
%
%   See also UISETFONT.

%   Copyright 1984-2024 The MathWorks, Inc.

persistent systemfonts;
if nargin == 1
    try
        currentfont = {get(handle, 'FontName')};
    catch ME %#ok<NASGU>
        currentfont = {''};
    end
else
    currentfont = {''};
end

isjava = usejava('awt');
% Grab a check regarding whether it is MATLAB Online
import matlab.internal.capability.Capability;
useLocal = Capability.isSupported(Capability.LocalClient);

if isempty(systemfonts)
    if matlab.ui.internal.dialog.DialogUtils.checkDecaf
        fonts = {pf.fonts.getInstalledFontList().font_name}.';
    elseif isjava
        fontlist = com.mathworks.mwswing.FontUtils.getFontNames.toArray();
        fonts = cell(fontlist);
    else
        fonts = {};
    end
    
    if useLocal
        % always add postscipt fonts to the system fonts list.
        systemfonts = [fonts;
            {
            'Courier';
            'Helvetica';
            'Monospaced';
            'SansSerif';
            'Serif';
            'Symbol';
            'Times';
            }];
    else
        systemfonts = getCommonFonts();
    end
end

% add the current font to the system font list if it's there
if isempty(currentfont{1})
    fonts = systemfonts;
else
    fonts = [systemfonts; currentfont];
end

% return a sorted and unique font list to the user
[f,i] = unique(lower(fonts));  %#ok
fonts = fonts(i);
end

function commonFonts = getCommonFonts()
% List of fonts that are common on many platforms
commonFonts = {
    'Arial';
    'Arial Black';
    'Arial Narrow';
    'Comic Sans MS';
    'Courier';
    'Courier New';
    'Georgia';
    'Helvetica';
    'Impact';
    'Monospaced';
    'SansSerif';
    'Serif';
    'Symbol';
    'Terminal';
    'Times';
    'Times New Roman';
    'Trebuchet MS';
    'Verdana';
    };
end