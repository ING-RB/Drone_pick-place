function t2 = primitiveHorzcat(t1,varargin)
%

%PRIMITIVEHORZCAT Raw horizontal concatenation for tables with no error checking.
%   T = PRIMITIVEHORZCAT(T1, T2, ...) horizontally concatenates the tables T1,
%   T2, ... positionally w.r.t rows, without regard to any row labels other than
%   those in T1. All inputs are assumed to be the same height. All inputs must
%   be tabular, and are assumed to have the same row labels, or no row labels.
%   Variable names must not conflict.

%   Copyright 2018-2024 The MathWorks, Inc.

try
    t1_nrows = t1.rowDim.length;
    t1_nvars = t1.varDim.length;

    nvarsTotal = t1_nvars;
    for i = 1:length(varargin)
        nvarsTotal = nvarsTotal + size(varargin{i},2); % dispatch to overloaded size, not built-in
    end
    
    t2_data = t1.data;
    % Create a new var dim, lengthening the old one would waste time creating
    % default var names.
    t2_varDim = t1.varDim.createLike(nvarsTotal); % empty var names
    t2_varDim = t2_varDim.assignInto(t1.varDim,1:t1_nvars);
    t2_rowDim = t1.rowDim;
    t2_nvars = t1_nvars;
    % Keep track of whether the current dimension names are defaults or not.
    haveDefaultDimNames = isequal(t1.metaDim.labels,t1.defaultDimNames);
    t2_metaDim = t1.metaDim;
    t2_arrayProps = t1.arrayProps;
    for j = 1:length(varargin)
        b = varargin{j};
        b_nrows = b.rowDim.length;
        b_nvars = b.varDim.length;
        assert(b_nrows == t1_nrows);
        
        % There's no comparison of row labels, the new set of variables is just
        % matched up positionally.
        t2_data = horzcat(t2_data, b.data); %#ok<AGROW>
        % Prevent events on eventtables.
        if isa(t1,"eventtable") && istimetable(b)
            b.rowDim = b.rowDim.setTimeEvents([]);
        end
        t2_rowDim = t2_rowDim.mergeProps(b.rowDim);
        t2_varDim = t2_varDim.assignInto(b.varDim,t2_nvars+(1:b_nvars));
        t2_nvars = t2_nvars + b_nvars;
        % Update the dimension names if this is the first time we are seeing
        % non-default names
        if haveDefaultDimNames && ~isequal(b.metaDim.labels,b.defaultDimNames)
            t2_metaDim = t2_metaDim.setLabels(b.metaDim.labels);
            haveDefaultDimNames = false;
        end
        t2_arrayProps = tabular.mergeArrayProps(t2_arrayProps,b.arrayProps);
    end
    t2 = t1;
    t2.data = t2_data;

    % Var names are assumed unique, but fix any conflicts between the
    % combined var names of the result and the dim names of the leading
    % time/table.
    t2.varDim = t2_varDim;
    t2.rowDim = t2_rowDim;
    t2.metaDim = t2_metaDim;
    t2.metaDim = t2.metaDim.checkAgainstVarLabels(t2.varDim.labels,'silent');
    t2.arrayProps = t2_arrayProps;
catch ME
    throwAsCaller(ME)
end
