function t1 = defaultarrayLike(varargin) %#codegen
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

% This is called by matlab.internal.datatypes.defaultarrayLike. If that
% function becomes a public function on the path, then this method would
% be unhidden, and calling defaultarrayLike(myTabular) will dispatch to
% this method directly.

% Replace data with default, to specified height. Preserve properties.

%   Copyright 2022 The MathWorks, Inc.

likeIdx = 0;
coder.unroll();
for i = 1:numel(varargin)
    if strcmpi('like', varargin{i})
        likeIdx = i;
        break;
    end
end
coder.const(likeIdx);  % must be constant
assert(likeIdx > 1 && likeIdx < nargin);
% Get the sz arguments, preserving const-ness of sz1 as n
if likeIdx == 1 % no size args
    n = 1;
else % size vector or separate size args, only need first size
    n = varargin{1}(1); % (only element of) first separate size arg, or first element of size vector
end

% Get the template argument
t = varargin{likeIdx+1};
% Get the optional ascellstr argument
if nargin > likeIdx+1
    ascellstr = varargin{likeIdx+2};
else
    ascellstr = true;
end

coder.internal.assert(isa(t, 'tabular'), 'MATLAB:table:UnsupportedDefaultValues', class(t));

% Create the default data
tdata = cell(1,width(t));
for i = 1:numel(tdata)
    var_i = t.data{i};
    tdata{i} = matlab.internal.coder.datatypes.defaultarrayLike(n,width(var_i),'like',var_i,ascellstr);
end

% Get the properties to copy to the output, and get row labels for the new length.
% Custom properties are not supported in codegen
[varDim, metaDim, rowDim, arrayProps] = getTabularProperties(t);
if n <= height(t)
    newRowDim1 = rowDim.shortenTo(n);
    newRowDimLabels = newRowDim1.labels;
else
    newRowDim2 = rowDim.lengthenTo(n);
    newRowDimLabels = newRowDim2.labels;
end

if isa(t,'table')
    if width(t) > 0
        t0 = table(tdata{:},'VariableNames',varDim.labels,'RowNames',newRowDimLabels);
    else
        t0 = array2table(zeros(n,0),'VariableNames',varDim.labels,'RowNames',newRowDimLabels);
    end
else
    if isa(rowDim, 'matlab.internal.coder.tabular.private.implicitRegularRowTimesDim')
        if rowDim.isSpecifiedAsRate
            if width(t) > 0
                t0 = timetable(tdata{:},'VariableNames',varDim.labels,'StartTime',rowDim.startTime,'SampleRate',rowDim.sampleRate);
            else
                t0 = array2timetable(zeros(n,0),'VariableNames',varDim.labels,'StartTime',rowDim.startTime,'SampleRate',rowDim.sampleRate);
            end
        else
            if width(t) > 0
                t0 = timetable(tdata{:},'VariableNames',varDim.labels,'StartTime',rowDim.startTime,'TimeStep',rowDim.timeStep);
            else
                t0 = array2timetable(zeros(n,0),'VariableNames',varDim.labels,'StartTime',rowDim.startTime,'TimeStep',rowDim.timeStep);
            end
        end
    else % explicitRegularRowTimesDim
        if width(t) > 0
            t0 = timetable(tdata{:},'VariableNames',varDim.labels,'RowTimes',newRowDimLabels);
        else
            t0 = array2timetable(zeros(n,0),'VariableNames',varDim.labels,'RowTimes',newRowDimLabels);
        end
    end
end
% Copy the input's properties; the new row dim has nothing new to offer beyond its shorter
% or longer row labels
t1 = updateTabularProperties(t0, varDim, metaDim, [], arrayProps);
