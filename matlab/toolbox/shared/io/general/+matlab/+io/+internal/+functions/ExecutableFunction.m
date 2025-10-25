classdef ExecutableFunction < matlab.io.internal.FunctionInterface ...
        & matlab.mixin.CustomDisplay
    %EXECUTABLEFUNCTION A mixin which defines an executable function

    % Copyright 2018-2020 MathWorks, Inc.
    properties (SetAccess = private, GetAccess = protected, Transient)
        SuppliedStruct
        ParameterNames
        RequiredNames
        Parser
    end

    properties (SetAccess = immutable, GetAccess = protected, Dependent)
        NumRequired
    end

    methods
        %%
        function func = ExecutableFunction()
            % inspect the meta class of this instance for required and
            % parameter inputs
            me = metaclass(func);
            isParam = [me.PropertyList.Parameter];
            isRequired = [me.PropertyList.Required];

            names = string({me.PropertyList.Name});
            allArguments = names(isParam|isRequired);

            % assign the default fields of the supplied struct.
            suppliedStruct = struct;
            for i = 1:numel(allArguments)
                suppliedStruct.(allArguments(i)) = false;
            end
            func.SuppliedStruct = suppliedStruct;

            % required parameters must be supplied.
            requiredNames = names(isRequired);
            for n = requiredNames
                suppliedStruct.(n) = true;
            end
            func.RequiredNames = requiredNames;

            % create the NV pair parser.
            parameterNames = names(isParam);
            if isa(func,'matlab.io.internal.functions.HasAliases')
                aliases = func.getAliases();
            else
                aliases = matlab.io.internal.functions.ParameterAlias.empty(1,0);
            end
            func.Parser = matlab.io.internal.validators.ArgumentParser(parameterNames,aliases);
            func.ParameterNames = parameterNames;
        end
        
        function val = get.NumRequired(func)
            val = numel(func.usingRequired());
        end

        function names = usingRequired(func)
            names = func.RequiredNames;
        end

        %%
        function [varargout] = validateAndExecute(func,varargin)
            % Do standard validation, and then execute.
            matlab.io.internal.validators.validateNVPairs(varargin{func.NumRequired+1:end});

            [func, supplied, additionalArgs] = func.validate(varargin{:});
            [varargout{1:nargout}] = func.execute(supplied,additionalArgs{:});
        end

        %%
        function [func, supplied, additionalArgs] = validate(func,varargin)

            [func, paramStruct, supplied, additionalArgs, results] = func.parseArguments(varargin{:});
            func = func.assignArguments(paramStruct, supplied);

            func.checkStandardConditions(additionalArgs, results, varargin);
        end

        %%
        function checkStandardConditions(func,additionalArgs,results,args)
            if ~isempty(results.AmbiguousMatch)
                error(message('MATLAB:table:parseArgs:AmbiguousParamName',args{func.NumRequired+2*results.AmbiguousMatch(1).idx - 1}))
            end
            if ~isempty(additionalArgs)
                error(message('MATLAB:textio:textio:UnknownParameter',additionalArgs{1}))
            end
        end

        %%
        function func = assignArguments(func, paramStruct, supplied)
            % assign parameter values to object
            paramnames = fieldnames(paramStruct);
            for i = 1:numel(paramnames)
                name = paramnames{i};
                if supplied.(name)
                    func.(name) = paramStruct.(name); % validate by object setter
                end
            end
        end

        %%
        function [func,paramStruct,supplied,additionalArgs,results] = parseArguments(func,varargin)
            %validate input arguments
            [func,supplied] = func.validateRequired(varargin);
            [paramStruct,supplied,additionalArgs,results] = func.parseNVPairs(varargin(func.NumRequired+1:end), supplied);
        end

        function [func,args] = extractArg(func,argname, args, numRequired)
            namesIdx = (numRequired+1):2:(numel(args)-1);
            [args{namesIdx}] = convertStringsToChars(args{namesIdx});
            results = func.Parser.canonicalizeNames(args(namesIdx));
            matches = find(results.CanonicalNames == argname);
            args(namesIdx) = cellstr(results.CanonicalNames);
            if ~isempty(matches)
                % Use the last setting for file type
                func.(argname) = args{2*matches(end)+numRequired};
                args([2*matches(1:end-1); 2*matches(1:end-1)]+(numRequired+[-1;1])) = [];
            end
        end
        %%
        function [func,supplied] = validateRequired(func, args, supplied)
            if nargin < 3
                supplied = func.SuppliedStruct;
            end
            % Process Required Names in order
            numReq = func.NumRequired;
            reqNames = func.usingRequired();
            for i = 1:numReq
                name = reqNames(i);
                func.(name) = args{i};
                supplied.(name) = true;
            end
        end

        function [paramStruct,supplied,additionalArgs,results] = parseNVPairs(func,params,supplied)
            if nargin < 3
                supplied = func.SuppliedStruct;
            end
            % get only the NV pairs
            parser = func.Parser;
            if ~isempty(params)
                [params{1:2:end}] = convertStringsToChars(params{1:2:end});
                % resolve partial matches
                results = parser.canonicalizeNames(params(1:2:end));
                params(1:2:end) = cellstr(results.CanonicalNames);
            else
                results = parser.canonicalizeNames({});
            end

            % get the argument struct
            [paramStruct,additionalArgs] = parser.extractArgs(params{:});

            paramnames = string(fieldnames(paramStruct));
            for name = paramnames(:)'
                supplied.(name) = true;
            end
        end
    end
    methods (Access=protected)

        function header = getHeader(obj)
            if ~isscalar(obj)
                header = getHeader@matlab.mixin.CustomDisplay(obj);
            else
                header = matlab.mixin.CustomDisplay.getClassNameForHeader(obj);
                header = ['  ExecutableFunction: ' header newline];
            end
        end

        function groups = getPropertyGroups(obj)
            if ~isscalar(obj)
                groups = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
            else
                % Get Required
                groups = matlab.mixin.util.PropertyGroup.empty();
                groups = getPropGroupFromNames('Required Inputs:',groups,obj,obj.RequiredNames);
                % Get Parameters
                groups = getPropGroupFromNames('Parameter (Name-Value Pair) Inputs:',groups,obj,obj.ParameterNames);
                % Get Non-Inputs
                n = setdiff(properties(obj),[obj.RequiredNames, obj.ParameterNames]);
                groups= getPropGroupFromNames('Non-Input Properties:',groups,obj,n);
                groups= getAliasesPropGroup(groups,obj.Parser.Aliases);
            end
        end

        function s = obj2struct(func,supplied)
            s = struct();
            for n = fieldnames(supplied)'
                if supplied.(n{1})
                    s.(n{1}) = func.(n{1});
                end
            end
        end
    end

    methods (Abstract)
        [varargout] = execute(func,supplied,varargin);
    end

end

function groups = getPropGroupFromNames(title,groups,func,names)
if numel(names) > 0
    s = struct();
    for i = 1:numel(names)
        s.(names{i}) = func.(names{i});
    end
    groups(end+1) = matlab.mixin.util.PropertyGroup(s,title);
end
end

function groups= getAliasesPropGroup(groups,aliases)
if ~isempty(aliases)
    s = struct();
    for a = aliases
        s.(a.CanonicalName) = a.AlternateNames;
    end
    groups(end+1) = matlab.mixin.util.PropertyGroup(s,"Parameter Aliases:");
end
end