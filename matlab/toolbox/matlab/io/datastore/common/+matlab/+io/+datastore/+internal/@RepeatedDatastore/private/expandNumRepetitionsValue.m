function indices = expandNumRepetitionsValue(~, numRepetitions)
%expandNumRepetitionsValue   Expands a NumRepetitions scalar into vector
%   indices.
%
%   Example:
%     rptds.expandNumRepetitionsValue(3) % Returns [1 2 3]'
%     rptds.expandNumRepetitionsValue(4) % Returns [1 2 3 4]'
%     rptds.expandNumRepetitionsValue(0) % Returns [0] (A special case)

%   Copyright 2021-2022 The MathWorks, Inc.

    if numRepetitions == 0
        indices = 0;
    else
        % Reshape the result to always be a column vector of double.
        indices = reshape(1:double(numRepetitions), [], 1);
    end
end
