classdef (Abstract) AbstractFcnComponent < matlab.internal.optimgui.optimize.widgets.AbstractOptimComponent
    % The AbstractFcnComponent Abstract class defines common properties and
    % methods for Optimization GUI custom components. FcnComponents include
    % LocalFcnComponent and FcnFileComponent
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2021-2023 The MathWorks, Inc.

    properties (Hidden, Access = public, Transient, NonCopyable)

        % Input for specifying the fcn name, like a button or dropdown
        Input % (1, 1) Class varies by subclass
    end

    methods (Abstract, Static, Access = public)

        % Subclasses define the method to create the fcn template
        createTemplate(fcnName, fcnText);
    end
end
