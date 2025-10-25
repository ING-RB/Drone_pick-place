function out = applyToGroups(fcn, numOutputs, groupKeys, varargin)
%applyToGroups Apply a function handle to a set of groups.
%
% Syntax:
%  out = applyToGroups(fcn,numOutputs,groupKeys,groupedInput1,groupedInput2,..)
%
% Where:
%  - fcn is the function handle to apply per group.
%  - groupKeys is a column vector of group keys, one key per group.
%  - Each of groupedInputN is a cell column vector, with each cell
%    containing all input of varargin index N for one group.
%
% This assumes that all input arguments have been canonicalized and
% aligned, with any grouped broadcasts flattened. It will emit a
% NumGroups x NumOutputs cell array, each containing one chunk of output
% from the function for a specific group.

% Copyright 2017 The MathWorks, Inc.

numGroups = numel(groupKeys);
out = cell(numGroups, numOutputs);
inputs = cell(1, numel(varargin));
for ii = 1:size(groupKeys, 1)
    % We need to pull out all of the input slices associated with
    % the current unique key. If a given input consists of a single
    % slice, this will be associated with all keys.
    for jj = 1:numel(inputs)
        if iscell(varargin{jj})
            inputs{jj} = varargin{jj}{ii};
        else
            inputs{jj} = varargin{jj};
        end
    end
    
    [out{ii, :}] = feval(fcn, inputs{:});
end
