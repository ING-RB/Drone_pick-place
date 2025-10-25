function [tt, tiwide] = stack(tw,varargin)
%STACK Stack up data from multiple variables into a single variable
%   T = STACK(WIDE,DATAVARS) 
%   T = STACK(WIDE,DATAVARS,NAME1,VALUE1,...)
%   [T, IWIDE] = STACK(...) 
%
%   See also TABLE/STACK, TIMETABLE/STACK

%   Copyright 2016-2023 The MathWorks, Inc.

narginchk(2,inf);
nargoutchk(0,2);
tw = tall.validateType(tw, upper(mfilename), {'table', 'timetable'}, 1);
tall.checkNotTall(upper(mfilename), 1, varargin{:});

% Create dummy table to determine variable names and types. 

% Stack the tall table
if nargout < 2
    tt = chunkfun(@(x)stack(x,varargin{:}), tw);
else
    sliceIds = getAbsoluteSliceIndices(tw);
    [tt, tiwide] = chunkfun(@(x,idx)iStackWithIdx(x,idx,varargin{:}), tw, sliceIds);
end

requiresVarMerging = false;
tt.Adaptor = joinBySample(@(w) stack(w, varargin{:}), requiresVarMerging, tw.Adaptor);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [out, idx] = iStackWithIdx(x, sliceIds, varargin)
% Function to run in each chunk to stack the table and get indices

% Stack table
[out, idx] = stack(x, varargin{:});

% Map absolute indices in sliceIds according to the order in idx
idx = sliceIds(idx);
end