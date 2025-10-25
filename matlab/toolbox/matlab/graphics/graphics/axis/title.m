function [hh,hhsub] = title(varargin)
%TITLE  Graph title.
%   TITLE('txt') adds the specified title to the axes or chart returned by
%   the gca command. Reissuing the title command causes the new title to
%   replace the old title.
%
%   TITLE('txt','subtxt') adds a subtitle in addition to the title.
%
%   TITLE(...,'Property1',PropertyValue1,'Property2',PropertyValue2,...)
%   sets the values of the specified properties of the title, and subtitle
%   if specified.
%
%   TITLE(target,...) adds the title to the specified target object.
%
%   H = TITLE(...) returns the handle to the text object used as the title.
%
%   See also SUBTITLE, XLABEL, YLABEL, ZLABEL, TEXT.

%   Copyright 1984-2022 The MathWorks, Inc.

% Parse the inputs and validate the target.
[targets, label, nvPairs] = labelcheck('Title',varargin);

% Chart subclass support
% Invoke title method with same number of outputs to defer output arg
% error handling to the method.
if isa(targets, 'matlab.graphics.chart.Chart')
    if(nargout == 1)
        hh = title(targets, label{:}, nvPairs{:});
    else
        title(targets, label{:}, nvPairs{:});
    end
    return
end

if isempty(label{1})
    label{1} = '';
end

hSub = gobjects(size(targets));
if isscalar(targets) && isappdata(targets,'MWBYPASS_title')
    % MWBYPASS_title allows Control System Toolbox to overload the behavior
    % of the title command.
    h = mwbypass(targets, 'MWBYPASS_title', label{1}, nvPairs{:});
else
    matlab.graphics.internal.markFigure(targets);

    % Set the subtitle first, so that if the target does not support
    % subtitles, the error is thrown before modifying the title.
    if numel(label) == 2
        if ~all(isprop(targets, 'Subtitle'),'all')
            classParts = strsplit(class(targets),'.');
            error(message('MATLAB:title:SubtitleNotSupported', ...
                classParts{end}));
        end

        if isempty(label{2})
            label{2} = '';
        end

        hSub = reshape([targets.Subtitle], size(targets));
        try
            set(hSub, 'String', label{2}, nvPairs{:});
        catch ex
            throw(ex);
        end
    end

    h = reshape([targets.Title], size(targets));
    try
        set(h, 'String', label{1}, nvPairs{:});
    catch ex
        throw(ex);
    end
end

if nargout > 0
    hh = h;
end

if nargout > 1
    hhsub=hSub;
end
