classdef FunctionInput < matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput
    % obj = matlab.internal.optimgui.optimize.solverbased.models.inputs.FunctionInput(State, Name, TemplateType) ...
    % constructs a FunctionInput with the specified State, Name, and TemplateType properties.
    %
    % See also matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput
    
    % Copyright 2020-2022 The MathWorks, Inc.
    
    % A FunctionInput's Value property is a (1, 1) struct
    % Value struct fields include:
    %   Source (1, :) char - The source of the function, either 'FromFile', 'LocalFcn', or 'FcnHandle'
    %   Name (1, :) - Name of the function. When Source is 'FcnHandle', this is the variable name
    %   UnsetFromFileFcn (1, :) char - The unset from file function name as it is locale dependent
    %   VariableList cell array of (1, :) char or empty - Ordered names of all function arguments
    %   FreeVariable (1, :) char or empty - Name of the optimization argument
    %   FixedValues cell array of (1, :) char or empty - Variable names for the fixed function arguments
    
    methods (Access = public)
        
        function obj = FunctionInput(State, Name, TemplateType)
        
        % Call superclass constructor
        obj@matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput(State, Name);
        
        % This widget type and FilterVariablesFcn are baked into a FunctionInput
        obj.Widget = 'matlab.internal.optimgui.optimize.solverbased.views.inputs.FunctionView';
        obj.WidgetProperties.FilterVariablesFcn = matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput.getFunctionFilter();
        
        % Set TemplateType and DocLinkID widget properties from input arguments
        obj.WidgetProperties.TemplateType = TemplateType;
        obj.WidgetProperties.DocLinkID = TemplateType;
        
        % Pull tooltip widget property from catalog
        obj.WidgetProperties.Tooltip = matlab.internal.optimgui.optimize.utils.getMessage('Tooltips', 'FunctionTooltip');
        
        % lsqcurvefit objective function requires xdata as an input. The user passes this argument
        % to the solver and the solver passes it into the function. Therefore, we only want to parse
        % the function if their are more than 2 arguments. For all other functions, we will parse
        % if there are more than 1 argument. Default to 1 here and have the lsqcurvefit
        % solver class update
        obj.WidgetProperties.NumberOfArgsThresh = 1;
        
        % Pull the default value from the Static constants class
        obj.DefaultValue = matlab.internal.optimgui.optimize.OptimizeConstants.DefaultFcnParse;
        end
        
        function tf = isSet(obj)
        
        % Check if a function value has been set AND ensure the user has set all required fcn inputs
        tf = obj.isFunctionValueSet && (~any(strcmp(matlab.internal.optimgui.optimize.OptimizeConstants.UnsetDropDownValue, ...
            obj.Value.FixedValues)) || numel(obj.Value.VariableList) <= obj.WidgetProperties.NumberOfArgsThresh);
        end
        
        function [solverFcnCode, anonymousFcnCode, anonymousFcnClear] = generateCode(obj)
        
        % If the FunctionInput is set, return the solver call syntax (solverFcnCode),
        % the anonymous fcn code (anonymousFcnCode), and the code clearing the
        % anaonymous fcn (anonymousFcnClear).
        % Else, return empty brackets for solverFcnCode and empty char for
        % anonymousFcnCode and anonymousFcnClear
        if obj.isSet()
            
            % If an anonymous fcn DOESN'T need to be created, return empty char for
            % anonymousFcnCode and anonymousFcnClear
            % Else, generate the code
            if numel(obj.Value.VariableList) <= obj.WidgetProperties.NumberOfArgsThresh
                
                % If Source is FcnHandle, assign Value to solverFcnCode
                % Else, append @ to convert to function handle
                fcnNameBackTicks = matlab.internal.optimgui.optimize.utils.addBackTicks(obj.Value.Name);
                if strcmp(obj.Value.Source, 'FcnHandle')
                    solverFcnCode = fcnNameBackTicks;
                else
                    solverFcnCode = ['@', fcnNameBackTicks];
                end
                
                % Anonymous function code
                anonymousFcnCode = '';
                
                % Clear anonymous function variable
                anonymousFcnClear = '';
            else
                
                % Pull variable name that will be assigned the anonymous fcn from a catalog
                % based on the Name property
                anonymousFcnName = matlab.internal.optimgui.optimize.utils.getMessage('CodeGeneration', obj.StatePropertyName);
                
                % Solver call syntax is the name of the anonymous fcn
                solverFcnCode = anonymousFcnName;
                
                % Pull the anonymous function code comment from a catalog
                anonymousFcnComment = [matlab.internal.optimgui.optimize.utils.getMessage('CodeGeneration', 'anonymousFcnComment'), ...
                    ' ', anonymousFcnName, newline];
                
                % Anonymous function code. Includes call to matlab.internal.optimgui.optimize.utils.reformatCode to
                % to insert [',...', newline, blanks(4)] if the code line gets long
                anonymousFcnCode = matlab.internal.optimgui.optimize.solverbased.models.inputs.FunctionInput.getAnonymousFcnSyntax(obj.Value);
                anonymousFcnCode = matlab.internal.optimgui.optimize.utils.reformatCode(...
                    [anonymousFcnName, ' = @(', ...
                    matlab.internal.optimgui.optimize.utils.addBackTicks(obj.Value.FreeVariable), ')', ...
                    matlab.internal.optimgui.optimize.utils.addBackTicks(obj.Value.Name), ...
                    anonymousFcnCode]);

                % Append comment, code, and 2 newline chars
                anonymousFcnCode = [anonymousFcnComment, anonymousFcnCode, newline, newline];
                
                % Clear anonymous function variable
                anonymousFcnClear = [anonymousFcnName, ' ']; % append space
            end
        else
            
            solverFcnCode = '[]';
            anonymousFcnCode = '';
            anonymousFcnClear = '';
        end
        end
        
        function code = generateWhatsMissingCode(obj, isConstraint)
        
        % What's missing code depends on whether the function selection
        % or fixed inputs are missing
        
        % If the function value is set, fixed inputs are missing.
        % Generate either objective or constraint message.
        % Else, function value is unset. Call superclass method
        if obj.isFunctionValueSet()
            if isConstraint
                code = matlab.internal.optimgui.optimize.utils.getMessage(...
                    'CodeGeneration', 'nonlconFcnFixedInputs');
            else
                code = matlab.internal.optimgui.optimize.utils.getMessage(...
                    'CodeGeneration', 'objFcnFixedInputs');
            end
        else
            % Call superclass method
            code = generateWhatsMissingCode@matlab.internal.optimgui.optimize.solverbased.models.inputs.SolverInput(obj, isConstraint);
        end
        end
    end
    
    methods (Access = private)
        
        function tf = isFunctionValueSet(obj)
        
        % Compare Value property to the UnsetDropDownValue when Source is LocalFcn or FcnHandle and
        % the default unset message when Source is FromFile
        switch obj.Value.Source
            case {'LocalFcn', 'FcnHandle'}
                tf = ~strcmp(obj.Value.Name, matlab.internal.optimgui.optimize.OptimizeConstants.UnsetDropDownValue);
            case 'FromFile'
                tf = ~strcmp(obj.Value.Name, matlab.internal.optimgui.optimize.OptimizeConstants.UnsetFromFileFcn);
        end
        end
    end
    
    methods (Static, Access = private)
        
        function code = getAnonymousFcnSyntax(Value)

        % Free variable index
        indFreeVariable = find(strcmp(Value.VariableList, Value.FreeVariable));

        % Inject FreeVariable into arguments. It seems when data is converted to JSON,
        % (1, :) cells are converted to (:, 1) cells. For assurance when concatenating,
        % explicitly set dimensions and append accordingly
        Value.FixedValues = reshape(Value.FixedValues, 1, []);
        args = [Value.FixedValues(1:indFreeVariable - 1), Value.FreeVariable, ...
            Value.FixedValues(indFreeVariable:end)];

        % Add back-ticks to input arguments
        code = char("(" + join("`" + string(args) + "`", ",") + ");");
        end
    end
    
    methods (Static, Access = public)
        
        function [code, name] = getFcnTemplate(type)
        % This function returns the fcn templates and the name of the fcn created
        % Fcn templates are a mix of catalog entries and hard-coded math expressions
        
        [name,fcnHeader,comments,editComment,variableCode,exCode] = localBuildTemplate();
        switch type
            case 'lsqCfObj' % lsqcurvefit
                % Erase "(k)" from the example code for the runnable code
                exCode = erase(exCode,"(k)");
            case 'surrogateObj' % surrogateopt
                % Edit example code to remove "subject to", "<=" and
                % add the struct assignment
                exCode(2) = [];
                exCode = ["f.Fval = ";"f.Ineq = "] + exCode;
                exCode(2) = replace(exCode(2),"<=","-");
            case 'nonlConstr'
                % Add extra comments and grab runnable version
                variableCode = ["% " + split(matlab.internal.optimgui.optimize.utils.getMessage('CodeGeneration','nonlConstrExtraComments'),newline); variableCode];
                exCode = split(matlab.internal.optimgui.optimize.utils.getMessage('CodeGeneration','nonlConstrRunnableCode'),newline);
        end
        
        code = char(join( ...
            [fcnHeader;
            comments;
            "";
            editComment;
            variableCode;
            exCode + ";";
            "end"], newline));
        
        % -------------- Nested helper function --------------
            function [name,fcnHeader,comments,editComment,variableCode,exCode] = localBuildTemplate()
            % Build template files
            % - Header line
            % - "Example:"
            % - Problem statement comment line
            % - Function code in comment form (multi-line)
            % - Blank
            % - Edit comment line
            % - Variable extract code (except fzero, fminbnd)
            % - Function code (multi-line)
            % - "end"
            
            fcnHeader = string(matlab.internal.optimgui.optimize.utils.getMessage('CodeGeneration', [type, 'HeaderCode']));
            name = char(extractBetween(fcnHeader,"= ","("));
            exCode = split(matlab.internal.optimgui.optimize.utils.getMessage('CodeGeneration', [type, 'ExampleCode']),newline);
            comments = "% " + ...
                [matlab.internal.optimgui.optimize.utils.getMessage('CodeGeneration', 'Example');
                matlab.internal.optimgui.optimize.utils.getMessage('CodeGeneration', [type, 'ExampleProblem']);
                exCode];
            
            editComment = "% " + matlab.internal.optimgui.optimize.utils.getMessage('CodeGeneration', 'EditCodeComment');
            variableCode = matlab.internal.optimgui.optimize.utils.getMessage('CodeGeneration', [type, 'VariableCode']);
            if ~isempty(variableCode)
                variableCode = split(variableCode,newline) + ";";
            end
            end % localBuildTemplate
        end % getFcnTemplate
    end
end
