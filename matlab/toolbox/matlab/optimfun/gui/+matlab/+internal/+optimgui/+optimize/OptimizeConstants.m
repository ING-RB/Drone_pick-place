classdef OptimizeConstants < handle
    % The OptimizeConstants class is a common reference point for Optimize LET constants
    %
    % See also matlab.internal.optimgui.optimize.solverbased.models.OptimizeState
    
    % Copyright 2020-2022 The MathWorks, Inc.
    
    properties (Constant)
        
        % These properties represent unset inputs into the LET
        UnsetDropDownValue (1, :) char = 'select variable'
        DefaultDropDownValue (1, :) char = 'default value'
        UnsetFromFileFcn (1, :) char = matlab.internal.optimgui.optimize.utils.getMessage('Labels', 'FromFileDefault');
        
        % These properties help represent the default state of the LET. ...
        % NOTE, when constraints get deleted, their values in the state revert back to default
        DefaultObjectiveType (1, :) char = 'Unsure';
        DefaultConstraintType cell = {'Unsure'};
        DefaultSolverName (1, :) char = 'fmincon';
        % Fcn value struct fields include:
        %   Source (1, :) char - The source of the function, either 'FromFile', 'LocalFcn', or 'FcnHandle'
        %   Name (1, :) char - Name of the function. When Source is 'FcnHandle', this is the variable name
        %   UnsetFromFileFcn (1, :) char - The unset from file function name as it is locale dependent
        %   VariableList cell array of (1, :) char or empty - Ordered names of all function arguments
        %   FreeVariable (1, :) char or empty - Name of the optimization argument
        %   FixedValues cell array of (1, :) char or empty - Variable names for the fixed function arguments
        DefaultFcnParse struct = struct(...
            'Source', 'FromFile', ...
            'Name', matlab.internal.optimgui.optimize.OptimizeConstants.UnsetFromFileFcn, ...
            'UnsetFromFileFcn', matlab.internal.optimgui.optimize.OptimizeConstants.UnsetFromFileFcn, ...
            'VariableList', [], ...
            'FreeVariable', '', ...
            'FixedValues', []);
        % LinearConstraint value struct fields include:
        %   LHS (1, :) char - Matrix variable name set from a filtered WorkspaceDropDown
        %   RHS (1, :) char - Vector variable name set from a filtered WorkspaceDropDown
        DefaultLinearConstraint (1, 1) struct = struct('LHS', matlab.internal.optimgui.optimize.OptimizeConstants.UnsetDropDownValue, ...
            'RHS', matlab.internal.optimgui.optimize.OptimizeConstants.UnsetDropDownValue);
        % Bounds value struct fields include:
        %   Source (1, :) char - The source of the bounds input, either 'SpecifyBounds' or 'FromWorkspace'
        %   Bounds (1, :) char - Reference value of the bounds constraint
        %          (1, :) char of a scalar number when Source is 'SpecifyBounds'
        %          (1, :) char of a variable name when Source is 'FromWorkspace'
        %   WorkspaceValue double - Value of the bounds
        DefaultLowerBounds (1, 1) struct = struct('Source', 'SpecifyBounds', ...
            'Bounds', '-Inf', 'WorkspaceValue', -Inf);
        DefaultUpperBounds (1, 1) struct = struct('Source', 'SpecifyBounds', ...
            'Bounds', 'Inf', 'WorkspaceValue', Inf);
        DefaultNonScalarWorkspaceValue = [1, 2];
        DefaultOptionsStruct (1, 1) struct = struct('Display', 'final', 'PlotFcn', '[]');

        % Grid size references
        RowHeight (1, 1) double = 22;
        ImageGridWidth (1, 1) double = 16;
    end
end
