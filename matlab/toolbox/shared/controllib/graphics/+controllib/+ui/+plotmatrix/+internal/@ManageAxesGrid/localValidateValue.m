function NewValue = localValidateValue(CurrentValue, NewValue, ValidateFcnHandle)
%

%   Copyright 2015-2020 The MathWorks, Inc.

% Validate NewValue against CurrentValue according to ValidateFcnHandle
% Returns a scalar value - as most of the set functions expect this.

% Difference between input and output
DiffMatrix = cellfun(ValidateFcnHandle, CurrentValue, NewValue);
DiffMatrix = ~DiffMatrix;

% Number of different elements
nDifferent = sum(sum(DiffMatrix));
ct = numel(CurrentValue);

if nDifferent == 1
    % Only one element is different
    NewValue = NewValue{DiffMatrix};
elseif nDifferent == 0
    % No elements are different - CurrentValue = NewValue
    NewValue = NewValue{1};
elseif nDifferent == ct
    % Number of different elements = size of property
    while ct
        % How many unique elements are specified
        % Example: Differentiate {[1 5]; [1 5]; [1 5]} from
        %                        {[1 5]; [1 6]; [1 7]}
        if any(NewValue{1} ~= NewValue{ct})
            error(message('Controllib:general:UnexpectedError', ...
                sprintf('Incompatible value specified')));
        end
        ct = ct-1;
    end
    NewValue = NewValue{1};
else
    error(message('Controllib:general:UnexpectedError', ...
        sprintf('Incompatible value specified')));
end
end
