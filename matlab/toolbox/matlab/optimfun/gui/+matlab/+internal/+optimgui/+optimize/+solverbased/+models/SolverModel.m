classdef (Abstract) SolverModel < matlab.internal.optimgui.optimize.models.AbstractTaskModel
    % The SolverModel Abstract class defines common properties and methods
    % for Optimize LET solver model classes
    
    % Copyright 2020-2023 The MathWorks, Inc.
    
    properties (GetAccess = public, SetAccess = protected)
        
        % Name of the solver: 'fmincon', 'linprog',...
        Name (1, :) char
        
        % cellstr of solver's miscellaneous inputs, for example: InitialPoint, LinearObjective,...
        % The inputs are in the order required by the solver's code syntax. Used to join the
        % generated code of the individual solver inputs in the right order.
        % All of these inputs must be set from the view side before generating code
        SolverMiscInputs (1, :) cell
        
        % cellstr of solver's optional miscellaneous inputs. These inputs are not
        % required for code generation and come after any constraints in the code syntax
        SolverMiscInputsOptional (1, :) cell
        
        % cellstr of solver's constraints in the order required by the solver's
        % code syntax. Used to join the generated code of the individual constraint
        % inputs in the right order
        Constraints (1, :) cell
        
        % Solver's options model. Handles options logic and code generation
        Options matlab.internal.optimgui.optimize.solverbased.models.OptionsModel
    end
    
    properties (Dependent, GetAccess = public, SetAccess = protected)
        
        % Append SolverMiscInputs and SolverMiscInputsOptional. Used when creating
        % inputs in a loop and by the Solver view class when creating the necessary
        % number of Labels and WorkspaceDropDowns
        SolverMiscInputsAll (1, :) cell
        
        % cellstr of solver's required inputs to generate code. This list is
        % dynamic. It gets updated as users view constraints and if the Algorithm changes
        RequiredInputs (1, :) cell
    end
    
    % Get methods
    methods
        
        function value = get.SolverMiscInputsAll(obj)
        value = [obj.SolverMiscInputs, obj.SolverMiscInputsOptional];
        end
        
        function value = get.RequiredInputs(obj)
        % Wrap get.RequiredInputs so that subclasses can extend the method
        value = obj.getRequiredInputs();
        end
    end
    
    methods (Access = public)
        
        function obj = SolverModel(state, name, solverMiscInputs, solverMiscInputsOptional)
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.models.AbstractTaskModel(...
            state);
        
        % Set Name and possibly SolverMiscInputs and SolverMiscInputsOptional
        % properties from input arguments
        obj.Name = name;
        if nargin > 2
            obj.SolverMiscInputs = solverMiscInputs;
            if nargin > 3
                obj.SolverMiscInputsOptional = solverMiscInputsOptional;
            end
        end
        
        % Create this solver's misc. inputs. Subclasses define solver misc. input
        % properties and the cellstrs SolverMiscInputs and SolverMiscInputsOptional.
        for input = obj.SolverMiscInputsAll
            obj.(input{:}) = matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.createInput(obj.State, input{:});
        end
        
        % Create OptionsModel object
        obj.Options = matlab.internal.optimgui.optimize.solverbased.models.OptionsModel(obj.State);
        end
        
        function [tf, whatsMissing] = isSet(obj)
        
        % Called by the OptimizeModel generateCode and generateSummary methods to
        % determine which code and task summary line to display
        
        % What's missing from the required inputs?
        [tf, whatsMissing] = obj.isInputsListSet(obj.RequiredInputs, 'all');
        end
        
        function [outputs, code] = generateCode(obj)
        
        % Called by the Optimize class when all required inputs are set. This method asks various
        % elemental properties for their own pieces of code and then joins them together in the right
        % order. It aims to build up the following template:
        % code = [anonymousObjFcnCode,...
        %    anonymousConFcnCode, ...
        %    optionsCode, ...
        %    matlab.internal.optimgui.optimize.utils.getMessage('CodeGeneration', 'solveComment'), newline, ...
        %    solverCallCode, newline, newline, ...
        %    clearCode];
        % Some pieces will not be relevant for all solvers. For example, an unconstrained solver
        % will never have anonymous fcn code for a nonlinear constraint. That piece will
        % be set to an empty char '' so it can be appended in the same way
        
        % Output variable names from call to solver
        outputs = {matlab.internal.optimgui.optimize.utils.getMessage('CodeGeneration', 'solverOutput1'), ...
            matlab.internal.optimgui.optimize.utils.getMessage('CodeGeneration', 'solverOutput2')};
        
        % optionsCode is the code that creates an optimoptions object or an
        % optimset struct for any nondefault options set by the user. If an
        % object/struct has been created, we need to clear the variable we make.
        % For example, optionsCode may look like this:
        % options = optimoptions('linprog', 'ConstraintTolerance',0.001);
        [optionsCode, optionsClear] = obj.Options.generateCode();
        
        % Generate ObjectiveFcn code pieces
        [solverObjFcnCode, anonymousObjFcnCode, anonymousObjFcnClear] = ...
            obj.generateObjectiveFcnCode();
        
        % Generate code for required solver misc. inputs
        SolverMiscInputsCode = obj.generateInputsCode(obj.SolverMiscInputs);
        
        % If this solver has constraints, generate its code pieces or set them to empty
        if ~isempty(obj.Constraints)
            [constraintsCode, anonymousConFcnCode, anonymousConFcnClear] = obj.('generateConstraintInputsCode');
        else
            constraintsCode = '';
            anonymousConFcnCode = '';
            anonymousConFcnClear = '';
        end
        
        % Generate code for optional solver misc. inputs
        SolverMiscInputsOptionalCode = obj.generateInputsCode(obj.SolverMiscInputsOptional);
        
        % Append together all inputs into the solver. For example, for fmincon
        % this variable may look like this: myObjFcn,x0,[],[],Aeq,beq,[],[],[],options
        % for lsqcurvefit: myObjFcn,x0,inputData,outputData,myLowerBounds,[],options
        allInputsCode = [solverObjFcnCode, SolverMiscInputsCode, ...
            constraintsCode, SolverMiscInputsOptionalCode];
        
        % If the user is not specifying any nondefault options, we don't have
        % to pass in the options object/struct. This mean we may also be able to
        % get rid of extra '[]'s. For example, myObjFcn,x0,[],[],Aeq,beq,[],[],[],options
        % would return myObjFcn,x0,[],[],Aeq,beq if no options code is required
        if isempty(optionsClear)
            allInputsCode = obj.trimAllInputsCode(allInputsCode);
        else
            allInputsCode = [allInputsCode, 'options'];
        end
        
        % If no options object/struct or anonymous fcn code/variables were created
        % then we don't need any code to clear these variables
        % Else, clear any variables created
        if isempty([optionsClear, anonymousObjFcnClear, anonymousConFcnClear])
            clearCode = '';
        else
            clearCode = [matlab.internal.optimgui.optimize.utils.getMessage('CodeGeneration', 'clearComment'), newline, ...
                'clearvars ', anonymousObjFcnClear, anonymousConFcnClear, optionsClear];
        end
        
        % Append the output arguments, solver name, inputs code, and closing ');'
        % For example, this variable may look like this:
        % '[solution, objectiveValue] = linprog(myLinearObjective,[],[],Aeq,beq]);', or
        % [solution, objectiveValue] = fmincon(myObjFcn,x0,[],[],[],[],lb,[],[],options);
        solverCallCode = ['[', outputs{1}, ',', outputs{2}, '] = ', obj.Name, '(', ...
            allInputsCode, ');'];
        
        % % Add newlines as necessary if the code is long
        solverCallCode = matlab.internal.optimgui.optimize.utils.reformatCode(solverCallCode);
        
        % Finally, append all of the code pieces
        code = [anonymousObjFcnCode,...
            anonymousConFcnCode, ...
            optionsCode, ...
            matlab.internal.optimgui.optimize.utils.getMessage('CodeGeneration', 'solveComment'), newline, ...
            solverCallCode, newline, newline, ...
            clearCode];
        end
        
        function [solverObjFcnCode, anonymousObjFcnCode, anonymousObjFcnClear] = generateObjectiveFcnCode(obj)
        
        % Called by the generateCode method. Separate method for sub-classes to override
        
        % If this solver has an ObjectiveFcn input, generate its code pieces or set them to empty
        if isprop(obj, 'ObjectiveFcn')
            [solverObjFcnCode, anonymousObjFcnCode, anonymousObjFcnClear] = obj.('ObjectiveFcn').generateCode();
            solverObjFcnCode = [solverObjFcnCode, ','];
        else
            solverObjFcnCode = '';
            anonymousObjFcnCode = '';
            anonymousObjFcnClear = '';
        end
        end
        
        function [outputs, code] = generateWhatsMissingCode(~, whatsMissing)
        
        % Called by the Optimize class when all required inputs are NOT set.
        % Generates a call to disp with the missing inputs
        
        % No outputs for this generated code
        outputs = {};
        
        % Generate disp code
        code = ['disp([''', matlab.internal.optimgui.optimize.utils.getMessage('CodeGeneration', 'selectMessage'), ...
            blanks(1), strjoin(whatsMissing, ', '), '''])'];
        
        % The code could get very long, add in newlines as appropriate
        code = matlab.internal.optimgui.optimize.utils.reformatCode(code, ', ', ...
            [','' ', 'newline ...', newline, blanks(4), '''']);
        
        % If no newline was needed, remove brackets
        if ~contains(code, newline)
            code = strrep(code, 'disp([', 'disp(');
            code = strrep(code, '])', ')');
        end
        end
        
        function summary = generateSummary(obj)
        
        % This method is called by the Optimize class. When the LET is generating code,
        % we also generate a summary of what the code is doing. The summary in this method
        % is valid for most solvers. Have solver subclasses override if necessary
        summary = getString(message('MATLAB:optimfun_gui:CodeGeneration:setSummary', ...
            ['`', obj.('ObjectiveFcn').Value.Name, '`'], ['`', obj.Name, '`']));
        end
    end
    
    methods (Access = protected)
        
        function [tf, whatsMissing] = isInputsListSet(obj, inputsList, type)
        % Type can be 'any' or 'all', used to dynamically evaluate those fcns
        
        % Check if each object in inputsList is set
        % If it's NOT, add input to whatsMissing cellstr
        tfInputs = false(size(inputsList));
        whatsMissing = cell(size(inputsList));
        for count = 1:numel(inputsList)
            tfInputs(count) = obj.(inputsList{count}).isSet();
            if ~tfInputs(count)
                whatsMissing{count} = obj.(inputsList{count}).generateWhatsMissingCode(...
                    any(strcmp(obj.(inputsList{count}).StatePropertyName, obj.Constraints)));
            end
        end
        
        % Dynamically evaluate 'any' or 'all' functions
        tf = feval(type, tfInputs);
        
        % Remove empty cells
        whatsMissing(cellfun(@isempty, whatsMissing)) = [];
        end
        
        function code = generateInputsCode(obj, inputList)
        
        % Generate code for each input object. Join each elemental code piece with a comma
        inputsCode = cell(size(inputList));
        for count = 1:numel(inputList)
            inputsCode{count} = obj.(inputList{count}).generateCode();
        end
        code = strjoin(inputsCode, ',');
        
        % If there was at least one input, append a comma to the end as well
        if numel(inputList) > 0
            code = [code, ','];
        end
        end
        
        function value = getRequiredInputs(obj)
        
        % For all solvers, the SolverMiscInputs are always required
        value = obj.SolverMiscInputs;
        
        % If the solver has an ObjectiveFcn, it will be required
        if isprop(obj, 'ObjectiveFcn')
            value = ['ObjectiveFcn', value];
        end
        end
    end
    
    methods (Static, Access = public)
        
        function SolverModel = createSolverModel(SolverName, State)
        
        % Create instances of SolverModels
        SolverModel = feval(['matlab.internal.optimgui.optimize.solverbased.models.solvers.', ...
            matlab.internal.optimgui.optimize.utils.upperFirstLetter(SolverName)], State);
        end
        
        function trimmedCode = trimAllInputsCode(allInputsCode)
        
        % If the user is not specifying any nondefault options, we don't have
        % to pass in the options object/struct. This mean we may also be able to
        % get rid if extra '[]'s. This code checks inputs backwards to find which
        % inputs to trim
        
        % Split code into cell array based on comma (ignore trailing comma)
        cellInputs = strsplit(allInputsCode(1:end - 1), ',');
        
        % Loop through the cell array backwards and remove the cell if its '[]'
        % Else, break the loop
        numInputs = numel(cellInputs);
        for count = numInputs:-1:0
            if strcmp(cellInputs{count}, '[]')
                cellInputs(count) = [];
            else
                break
            end
        end
        
        % Join remaning inputs with a comma
        trimmedCode = strjoin(cellInputs, ',');
        end
    end
end
