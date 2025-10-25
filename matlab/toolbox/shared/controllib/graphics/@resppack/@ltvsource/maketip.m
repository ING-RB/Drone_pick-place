function str = maketip(src,event_obj,info,CursorInfo)
%MAKETIP  Build data tips for LTI responses.
%
%   INFO is a structure built dynamically by the data tip interface
%   and passed to MAKETIP to facilitate construction of the tip text.

%   Copyright 2023 The MathWorks, Inc.

% Context 
r = info.Carrier;

% Temp Code path for testing GraphicsVersion 1 and 2 datatips
if nargin == 3
    % Revisit
    str = maketip(info.View,event_obj,info);
else
    % Call using CursorInfo (Graphics Version 2 Compatible path)
    str = maketip(info.View,event_obj,info,CursorInfo);
end

% Customize header
str{1} = getString(message('Controllib:plots:strSystemLabel', r.Name, ''));
% Add escape for '_' to prevent subscript in datatip labels
str{1} = strrep(str{1},'_','\_');
