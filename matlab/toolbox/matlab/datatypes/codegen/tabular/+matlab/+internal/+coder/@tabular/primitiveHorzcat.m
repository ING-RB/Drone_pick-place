function t2 = primitiveHorzcat(t1,varargin)   %#codegen
%PRIMITIVEHORZCAT Raw horizontal concatenation for tables with no error checking.
%   T = PRIMITIVEHORZCAT(T1, T2, ...) horizontally concatenates the tables T1,
%   T2, ... positionally w.r.t rows, without regard to any row labels other than
%   those in T1. All inputs are assumed to be the same height. All inputs must
%   be tabular, and are assumed to have the same row labels, or no row labels.
%   Variable names must not conflict.

%   Copyright 2020-2021 The MathWorks, Inc.

t1_nrows = t1.rowDim.length;
t1_nvars = t1.varDim.length;

nvarsTotal = t1_nvars;
for i = 1:length(varargin)
    nvarsTotal = nvarsTotal + varargin{i}.varDim.length;
end

t2_data = coder.nullcopy(cell(1,nvarsTotal));
t2_varDim = t1.varDim.createLike(nvarsTotal); % empty var names

t2_varlabels = coder.nullcopy(cell(1,nvarsTotal));
coder.unroll();
for i = 1:t1_nvars
    t2_data{i} = t1.data{i};
    t2_varlabels{i} = t1.varDim.labels{i};
end
t2_varDim = t2_varDim.moveProps(t1.varDim,1:t1_nvars,1:t1_nvars);
t2_nvars = t1_nvars;
% Track the index of the timetable that is the first one with non-default
% dimension names.
firstNonDefaultDimName = 0;
if ~isequal(t1.metaDim.labels, t1.defaultDimNames)
    firstNonDefaultDimName = 1;
end
coder.unroll();
for j = 1:length(varargin)
    % initializing t2_arrayProps in the first iteration. This done inside
    % the loop so that Coder will treat t2_arrayProps as a new variable in
    % each iteration.
    if j == 1
        t2_arrayProps = t1.arrayProps;
    end
    b = varargin{j};
    b_nrows = b.rowDim.length;
    b_nvars = b.varDim.length;
    assert(b_nrows == t1_nrows);
        
    for i = 1:b_nvars
        t2_data{t2_nvars+i} = b.data{i};
        t2_varlabels{t2_nvars+i} = b.varDim.labels{i};
    end
    t2_varDim = t2_varDim.moveProps(b.varDim,1:b_nvars,t2_nvars+(1:b_nvars));
    t2_nvars = t2_nvars + b_nvars;
    % Update the index if this is the first table with non-default dim names
    if firstNonDefaultDimName == 0 && ~isequal(b.metaDim.labels, b.defaultDimNames)
        firstNonDefaultDimName = j+1;
    end
    
    t2_arrayProps = t1.mergeArrayProps(t2_arrayProps,b.arrayProps);
end

if isempty(varargin)
    t2_arrayProps = t1.arrayProps;
end

t2 = t1.cloneAsEmpty();
t2.data = t2_data;

t2_varDim = t2_varDim.setLabels(t2_varlabels,[],nvarsTotal);
t2.varDim = t2_varDim;
t2.rowDim = t1.rowDim;
% in codegen, the below assignments are equivalent to t2.metaDim = t.metaDim,
% will never error because codegen doesn't change variable names in a conflict,
% but just errors
if firstNonDefaultDimName <= 1
    % Either t1 has non-default dim names or all tables have default
    % dim names, so just pick t1's dim names.
    t2.metaDim = t1.metaDim.checkAgainstVarLabels(t2.varDim.labels,'silent');
else
    % t1 has default dim names but another table in varargin has non-default
    % dim names, so pick that table's dim names.
    t2.metaDim = varargin{firstNonDefaultDimName-1}.metaDim.checkAgainstVarLabels(t2.varDim.labels,'silent');
end
t2.arrayProps = t2_arrayProps;


