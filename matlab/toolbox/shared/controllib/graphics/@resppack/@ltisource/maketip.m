function str = maketip(src,event_obj,info,CursorInfo)
%MAKETIP  Build data tips for LTI responses.
%
%   INFO is a structure built dynamically by the data tip interface
%   and passed to MAKETIP to facilitate construction of the tip text.

%   Author(s): P. Gahinet, B. Eryilmaz.
%   Revised  : K. Subbarao 10-29-2001   
%   Copyright 1986-2013 The MathWorks, Inc.

% Context 
r = info.Carrier;
h = r.Parent;

% Model array indices
Size = size(src.Model);
if length(Size)<3
   astr = '';
elseif all(Size(4:end)==1)
   astr = sprintf('(:,:,%d)',info.ArrayIndex);
else
   asize = Size(3:end);
   aindex = cell(1,length(asize));
   [aindex{:}] = ind2sub(asize,info.ArrayIndex);
   astr = sprintf(',%d',aindex{:});
   astr = sprintf('(:,:%s)',astr);
end


% Temp Code path for testing GraphicsVersion 1 and 2 datatips
if nargin == 3;
    % Revisit
    str = maketip(info.View,event_obj,info);
else
    % Call using CursorInfo (Graphics Version 2 Compatible path)
    str = maketip(info.View,event_obj,info,CursorInfo);
end



% Customize header
str{1} = getString(message('Controllib:plots:strSystemLabel', r.Name, astr));
% Add escape for '_' to prevent subscript in datatip labels
str{1} = strrep(str{1},'_','\_');

% Add Sampling Grid Information
FieldNames = fieldnames(src.Model.SamplingGrid);
if ~isempty(FieldNames)
    for ct = 1:length(FieldNames)
        str{end+1} = sprintf('%s: %0.5g', FieldNames{ct},src.Model.SamplingGrid.(FieldNames{ct})(info.ArrayIndex));
    end
end

