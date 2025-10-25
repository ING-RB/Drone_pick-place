function hh = subtitle(varargin)
%SUBTITLE Graph subtitle.
%   SUBTITLE('txt') adds the specified subtitle to the axes or chart 
%   returned by the gca command. Reissuing the subtitle command causes the 
%   new subtitle to replace the old subtitle.
%
%   SUBTITLE(...,'Property1',PropertyValue1,'Property2',PropertyValue2,...)
%   sets the values of the specified properties of the subtitle.
%
%   SUBTITLE(target,...) adds the subtitle to the specified target object.
%
%   H = SUBTITLE(...) returns the handle to the text object used as the 
%   subtitle.
%
%   See also XLABEL, YLABEL, ZLABEL, TEXT, TITLE.

%   Copyright 1984-2022 The MathWorks, Inc.

% Parse the inputs and validate the target.
[targets, label, nvPairs] = labelcheck('Subtitle',varargin);
label = label{1};

% Chart subclass support
% Invoke subtitle method with same number of outputs to defer output arg
% error handling to the method.
if isa(targets,'matlab.graphics.chart.Chart')
    if(nargout == 1)
        hh = subtitle(targets, label, nvPairs{:});
    else
        subtitle(targets, label, nvPairs{:});
    end
    return
end

if isempty(label)
    label = '';
end

matlab.graphics.internal.markFigure(targets);
h = reshape([targets.Subtitle], size(targets));

try
    set(h, 'String', label, nvPairs{:});
catch ex
    throw(ex);
end

if nargout > 0
    hh = h;
end
