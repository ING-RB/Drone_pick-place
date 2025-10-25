function [omitMissing,funWrapper] = processMinMaxOptionalInputs(fun,varargin) %#codegen
%PROCESSMINMAXOPTIONALINPUTS Process the DIM, MISSINGFLAG, and LINEARFLAG inputs to min/max.

%   Copyright 2022 The MathWorks, Inc.

% Replace any potential 'omitmissing/undefined' or 'includemissing/undefined'
% flags in 'varargin' with 'omitnan' or 'includenan' respectively and use those
% when calling the function. These along with the other optional arguments need
% to be constant, so we cannot return those in a cell array of updated args as
% that might lose constness. Instead we will create a wrapper function handle
% that has all the optional arguments supplied to it and then then min/max can
% simply call this function handle with the two operands.

for ii = 1:nargin-1 % ComparisonMethod not supported.
    coder.internal.errorIf(matlab.internal.coder.datatypes.checkInputName(varargin{ii},{'ComparisonMethod'}),'MATLAB:min:InvalidAbsRealType');
end

% We cannot assign to varargin in codegen and creating a new cell array would
% result in losing constness, so keep track of where the missing flag is located
% and while creating the funWrapper, use the updated flag at that location.
missingFlagIdx = 0;
omitMissing = true; % use 'omitmissing' by default
if nargin > 1
    % Count the number of optional arguments.
    numOpts = numel(varargin);
    isScalarText = (ischar(varargin{1}) && isrow(varargin{1})) || (isstring(varargin{1}) && isscalar(varargin{1}));
    if ~isScalarText ...
            || (coder.internal.isConst(varargin{1}) && matlab.internal.coder.datatypes.checkInputName(varargin{1},{'all'}))
        % First one is a dim arg so exclude it from numOpts.
        numOpts = numOpts-1;
    end

    if numOpts > 0
        % Check if the last input is 'linear'
        if matlab.internal.coder.datatypes.checkInputName(varargin{end},{'linear'})
            if numOpts > 1
                % If the last input is 'linear', we need to check the second to last
                % input for the missing flag.
                [omitMissing,missingFlag] = validateMissingOption(varargin{end-1});
                missingFlagIdx = nargin-2;
            else
                % No missing flag present, omitMissing is true.
            end
        else
            % missing flag is the last input.
            [omitMissing,missingFlag] = validateMissingOption(varargin{end});
            missingFlagIdx = nargin-1;
        end
    end
end

if missingFlagIdx == 0
    % No missing flag found so no updates necessary for the varargin.
    funWrapper = @(a,b) fun(a,b,varargin{:});
else
    % We found a missing flag, so use the updated flag when calling the
    % function.
    funWrapper = @(a,b) fun(a,b,varargin{1:missingFlagIdx-1},missingFlag,varargin{missingFlagIdx+1:end});
end