classdef BoundsConstraintInput < matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput
    % obj = matlab.internal.optimgui.optimize.solverbased.models.inputs.BoundsConstraintInput(State, Name) ...
    % constructs a BoundsConstraintInput with the specified State and Name properties.
    %
    % See also matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput, matlab.internal.optimgui.optimize.widgets.uiBoundsWidget
    
    % Copyright 2020-2022 The MathWorks, Inc.
    
    % A BoundsConstraintInput's Value property is a (1, 1) struct set from a uiBoundsWidget.
    % Value struct fields include:
    %   Source (1, :) char - The source of the bounds input, either 'SpecifyBounds' or 'FromWorkspace'
    %   Bounds (1, :) char - Reference value of the bounds constraint
    %          (1, :) char of a scalar number when Source is 'SpecifyBounds'
    %          (1, :) char of a variable name when Source is 'FromWorkspace'
    % A WorkspaceValue field is also added by the setValue method
    
    properties (Access = public)
        
        % Based on the solver, scalar bounds need to be expanded to match the dimensions of something.
        % Let's default to the most common property and have specific SolverModel's overwrite as necessary
        ScalarMatch (1, :) char = 'InitialPoint';
    end
    
    methods (Access = public)
        
        function obj = BoundsConstraintInput(State, Name)
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput(State, Name);
        
        % This widget type and FilterVariablesFcn are baked into a BoundsConstraintInput
        obj.Widget = 'matlab.internal.optimgui.optimize.solverbased.views.inputs.BoundsConstraintView';
        obj.WidgetProperties.FilterVariablesFcn = matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.getArrayFilter();
        
        % Pull tooltip and label widget properties from catalog
        obj.WidgetProperties.Tooltip = matlab.internal.optimgui.optimize.utils.getMessage('Tooltips', 'ArrayTooltip');
        obj.WidgetProperties.BoundsLabel = matlab.internal.optimgui.optimize.utils.getMessage(...
            'Labels', [obj.StatePropertyName, 'Label']);
        
        % Pull the default value from the Static constants class based on this
        % BoundsConstraintInputs Name property
        obj.DefaultValue = matlab.internal.optimgui.optimize.OptimizeConstants.(['Default', obj.StatePropertyName]);
        
        % Value to reset the widget to when Source is 'SpecifyBounds';
        obj.WidgetProperties.DefaultValue = obj.DefaultValue.Bounds;
        end
        
        function tf = isSet(obj)
        
        % Compare Bounds field of Value struct property to the UnsetDropDownValue AND check if
        % the constraint was set by the user. This is necessary because the State defaults
        % to a valid scalar input.  However, if the user is not viewing/setting this constraint
        % explicitly, let's handle as unset
        tf = ~strcmp(obj.Value.Bounds, matlab.internal.optimgui.optimize.OptimizeConstants.UnsetDropDownValue) && ...
            ismember(obj.StatePropertyName, obj.State.ConstraintType);
        end
        
        function code = generateCode(obj)
        
        % If the BoundsConstraintInput is set, return the Bounds field of the
        % Value struct property.
        % Else, return empty brackets
        if obj.isSet

            % If the input value is a varname, add back-ticks for generated code
            if isvarname(obj.Value.Bounds)
                valueCode = matlab.internal.optimgui.optimize.utils.addBackTicks(obj.Value.Bounds);
            else
                valueCode = obj.Value.Bounds;
            end
            
            % If the Source is SpecifyBounds AND there is a variable to size match, expand accordingly
            % Else, just return the Value
            if strcmp(obj.Value.Source, 'SpecifyBounds') && ~isempty(obj.ScalarMatch)
                switch obj.Value.Bounds
                    case '0'
                        code = ['zeros(', obj.getExpansionCode()];
                    case '1'
                        code = ['ones(', obj.getExpansionCode()];
                    case 'Inf'
                        code = ['Inf(', obj.getExpansionCode()];
                    otherwise
                        code = ['repmat(', valueCode, ',', obj.getExpansionCode()];
                end
            else
                code = valueCode;
            end
        else
            code = '[]';
        end
        end
    end
    
    methods (Access = protected)
        
        function setValue(obj, value)
            
        % Maintain the WorkspaceValue field for 20b
        % forward compatibility. If the user is not
        % specifying a scalar, set WorkspaceValue field to
        % a non-scalar
        if strcmp(value.Source, 'SpecifyBounds')
            value.WorkspaceValue = str2double(value.Bounds);
        else
            value.WorkspaceValue = matlab.internal.optimgui.optimize.OptimizeConstants.DefaultNonScalarWorkspaceValue;
        end
        
        % Set corresponding property in the State
        obj.State.(obj.StatePropertyName) = value;
        end
    end
    
    methods (Access = private)
        
        function code = getExpansionCode(obj)
        
        % The NumberOfVariables State property is a whole number, so use the value to expand the bounds.
        % The LLSMat State property is a matrix, so use the number of columns to expand the bounds.
        % Otherwise, expand based on the size of the ScalarMatch property
        matchBackTicks = matlab.internal.optimgui.optimize.utils.addBackTicks(obj.State.(obj.ScalarMatch));
        switch obj.ScalarMatch
            case 'NumberOfVariables'
                code = [matchBackTicks, ',1)'];
            case 'LLSMat'
                code = ['width(', matchBackTicks, '),1)'];
            otherwise
                code = ['size(', matchBackTicks, '))'];
        end
        end
    end
end
