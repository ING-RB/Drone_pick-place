%AbstractConstantData Interface for interacting with value-objects that
%represent the structural data underlying a Constant.

% Copyright 2022-2023 The MathWorks, Inc.

classdef (Abstract) AbstractConstantData
    methods (Abstract)
        % Perform any initialization required.
        %
        % This must not throw an exception.
        obj = initialize(obj);

        % Perform any cleanup required.
        %
        % This may throw an exception.
        cleanup(obj);

        % Get the associated Value.
        %
        % This may throw an exception.
        value = getValue(obj);

        % Get the associated constructor arguments (required for
        % serialization).
        %
        % This must not throw an exception
        args = getConstructorArgs(obj);
    end
end