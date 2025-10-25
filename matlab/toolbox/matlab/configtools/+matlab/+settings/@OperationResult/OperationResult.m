classdef OperationResult
    % OperationResult stores the results of an
    % operation performed on the personal settings
    % of a toolbox

    %   Copyright 2019 The MathWorks, Inc.

    properties (GetAccess = public, SetAccess = immutable)
        % Operation to which this result is associated to
        % For example, "move a.b.c a.b.d"
        Operation (1,1) string
        % Operation status
        % For example, "Success", "Failed", or "Skipped"
        Status (1,1) string
        % List of exceptions that occured during the operation
        ExceptionLog matlab.settings.ReleaseCompatibilityException
    end
end
