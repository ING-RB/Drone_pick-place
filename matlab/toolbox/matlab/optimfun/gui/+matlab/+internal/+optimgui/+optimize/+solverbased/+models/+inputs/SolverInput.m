classdef (Abstract) SolverInput < matlab.internal.optimgui.optimize.models.AbstractTaskInput
    % The SolverInput Abstract class defines a common interface for Optimize LET input classes
    %
    % See also matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput,
    % matlab.internal.optimgui.optimize.solverbased.models.inputs.BoundsConstraintInput,
    % matlab.internal.optimgui.optimize.solverbased.models.inputs.FunctionInput,
    % matlab.internal.optimgui.optimize.solverbased.models.inputs.LinearConstraintInput
    
    % Copyright 2020-2022 The MathWorks, Inc.
    
    properties (GetAccess = public, SetAccess = protected)
        
        % Widget the view will use to represent this SolverInput
        Widget (1, :) char
        
        % "Conversational" label of this SolverInput for the view to display.
        % Pulled from catalog and set in subclass constructors
        DisplayLabel (1, :) char
        
        % Default value of this SolverInput. Pulled from matlab.internal.optimgui.optimize.OptimizeConstants
        % and set in subclass constructors
        DefaultValue % char or struct
    end
    
    properties (Access = public)
        
        % Tooltip for the DisplayLabel. Pulled from catalog and set in subclass
        % constructors. Allow solver model classes to customize this property
        DisplayLabelTooltip (1, :) char
        
        % The same widget may be used for different solver inputs. Store properties
        % of the widget for this SolverInput. Allow solver model classes and Options model
        % to customize these properties
        WidgetProperties (1, 1) struct
    end
    
    properties (Dependent, Access = public)
        
        % Return the widget property names from the WidgetProperties struct.
        % This helps the view update existing widgets when possible instead
        % of deleteing and making new ones
        WidgetPropertyNames (1, :) cell
    end
    
    % Set/get methods
    methods
        
        function value = get.WidgetPropertyNames(obj)
        
        % Return row vector cell array of the widget property names
        value = reshape(fieldnames(obj.WidgetProperties), 1, []);
        end
    end
    
    methods (Access = public)
        
        function obj = SolverInput(state, name)
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.models.AbstractTaskInput(...
            state, name);
        
        % Pull label and label tooltip from catalog using the Name property as an id
        obj.DisplayLabel = matlab.internal.optimgui.optimize.utils.getMessage('Labels', obj.StatePropertyName);
        obj.DisplayLabelTooltip = matlab.internal.optimgui.optimize.utils.getMessage('Tooltips', obj.StatePropertyName);

        % In some special cases, we may want to hide the input components 
        % from view and instead show a message. For example, when the user
        % adds a nonlinear constraint fcn for surrogateopt. Instead of showing
        % the fcn input components, a message tells the user to specify the
        % nonlinear constraint in the objective fcn. These are edge cases.
        % Default to no message and let specific solver classes override.
        obj.WidgetProperties.Message = '';
        end
        
        function code = generateWhatsMissingCode(obj, isConstraint)
        
        % If input is unset, generate code to display it's missing
        code = obj.DisplayLabel;
        % Append display label for constraints for clarity
        if isConstraint
            code = [code, blanks(1), ...
                lower(matlab.internal.optimgui.optimize.utils.getMessage('Labels', 'constraints'))];
        end
        end
    end
    
    methods (Static, Access = public)
        
        function input = createInput(State, type)
        % Factory method that creates instances of SolverInputs
        
        switch type
            
            case {'multiObj', 'scalarFcnObj', 'singleObj', 'scalarEqObj', 'lsqCfObj', 'nlsqObj', 'surrogateObj', 'fsolveObj'}
                input = matlab.internal.optimgui.optimize.solverbased.models.inputs.FunctionInput(State, 'ObjectiveFcn', type);
                
            case {'InitialPoint', 'LinearObjective', 'InputData', 'OutputData'}
                input = matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput(State, type, ...
                    matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.getArrayFilter(), ...
                    'ArrayTooltip');
                
            case {'Goal', 'Weight', 'LLSVec'}
                input = matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput(State, type, ...
                    matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.getVectorFilter(), ...
                    'VectorTooltip');
                
            case 'NumberOfVariables'
                input = matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput(State, type, ...
                    matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.getWholeNumberFilter(), ...
                    'WholeNumberTooltip');
                
            case 'LLSMat'
                input = matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput(State, type, ...
                    matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.getMatrixFilter(), ...
                    'MatrixTooltip');
                
            case 'QuadraticObjective'
                input = matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput(State, type, ...
                    matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.getSymmetricMatrixFilter(), ...
                    'SymmetricMatrixTooltip');
                
            case {'LinearInequality', 'LinearEquality'}
                input = matlab.internal.optimgui.optimize.solverbased.models.inputs.LinearConstraintInput(State, type);
                
            case {'LowerBounds', 'UpperBounds'}
                input = matlab.internal.optimgui.optimize.solverbased.models.inputs.BoundsConstraintInput(State, type);
                
            case 'nonlConstr'
                input = matlab.internal.optimgui.optimize.solverbased.models.inputs.FunctionInput(State, 'NonlinearConstraintFcn', type);
                
            case 'IntegerConstraint'
                input = matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput(State, type, ...
                    matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.getWholeNumberVectorFilter(), ...
                    'WholeNumberVectorTooltip', 'matlab.internal.optimgui.optimize.solverbased.views.inputs.ArrayInputView');
                
            case 'SecondOrderCone'
                input = matlab.internal.optimgui.optimize.solverbased.models.inputs.ArrayInput(State, type, ...
                    matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.getSecondOrderConeFilter(), ...
                    'SOConeTooltip', 'matlab.internal.optimgui.optimize.solverbased.views.inputs.ArrayInputView');
        end
        end
        
        % Static methods to provide filter functions for subclasses
        function FilterVariblesFcn = getArrayFilter()
        FilterVariblesFcn = @(x)isa(x, 'double') && isreal(x);
        end
        
        function FilterVariblesFcn = getVectorFilter()
        FilterVariblesFcn = @(x) isa(x, 'double') && isreal(x) && isvector(x);
        end
        
        function FilterVariblesFcn = getMatrixFilter()
        FilterVariblesFcn = @(x) isa(x, 'double') && isreal(x) && ismatrix(x);
        end
        
        function FilterVariblesFcn = getSymmetricMatrixFilter()
        FilterVariblesFcn = @(x) isa(x, 'double') && isreal(x) && ismatrix(x) && issymmetric(double(x));
        end
        
        function FilterVariblesFcn = getWholeNumberFilter()
        FilterVariblesFcn = @(x) isa(x, 'double') && isreal(x) && isscalar(x) && all((round(x) == x)) && all((x > 0));
        end
        
        function FilterVariblesFcn = getWholeNumberVectorFilter()
        FilterVariblesFcn = @(x) isa(x, 'double') && isreal(x) && isvector(x) && all((round(x) == x)) && all((x > 0));
        end
        
        function FilterVariblesFcn = getFunctionFilter()
        FilterVariblesFcn = @(x) isa(x, 'function_handle');
        end
        
        function FilterVariblesFcn = getSecondOrderConeFilter()
        FilterVariblesFcn = @(x) isa(x, 'optim.coneprog.SecondOrderConeConstraint');
        end

        function FilterVariblesFcn = getIntegerConstraintFilter()
        FilterVariblesFcn = @(x) isa(x, 'optim.intlinprog.IntegerConstraint') || ...
            (isa(x, 'double') && isreal(x) && isvector(x) && all((round(x) == x)) && all((x > 0)));
        end
        
        function FilterVariblesFcn = getScalarFilter()
        FilterVariblesFcn = @(x) isa(x, 'double') && isreal(x) && isscalar(x);
        end
        
        function FilterVariblesFcn = getFzeroInitialPointFilter()
        FilterVariblesFcn = @(x) isa(x, 'double') && isreal(x) && (isscalar(x) || (isvector(x) && numel(x) == 2));
        end

        function FilterVariblesFcn = getWholeNumberRowVectorFilter()
        FilterVariblesFcn = @(x) isa(x, 'double') && isreal(x) && isrow(x) && all((round(x) == x)) && all((x > 0));
        end
    end
end
