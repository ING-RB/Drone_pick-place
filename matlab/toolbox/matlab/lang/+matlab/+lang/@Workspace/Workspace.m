classdef Workspace < handle &...
        matlab.mixin.indexing.RedefinesDot &...
        matlab.mixin.indexing.OverridesPublicDotMethodCall &...
        matlab.mixin.internal.indexing.DisallowCompletionOfDotMethodNames &...
        matlab.mixin.Scalar &...
        matlab.mixin.CustomDisplay
    %   Workspace

    %   Copyright 2024 The MathWorks, Inc.

    properties (Access = private, Hidden = true)
        m_workspace
        m_id
    end

    methods(Access = private, Hidden = true)
        function varTable = getVariablesForDisplay(obj)
            varStruct = obj.m_workspace.getVariablesForDisplay();
            varTable = struct2table(varStruct);
            varTable.Name = char(varTable.Name);
            varTable.Size = char(varTable.Size);
            varTable.Class = char(varTable.Class);
        end

        function displayHeader(~)
            text = getString(message('MATLAB:lang:Workspace:displayHeader'));
            fprintf(text + "\n\n");
        end
    end

    methods(Access = protected)
        function varargout = dotReference(obj, IO)

            varName = IO(1).Name;
            if ~obj.m_workspace.hasVariables(varName)
                if ismethod(obj,varName)
                    error(message('MATLAB:lang:Workspace:dotInvocationNotSupported'));
                end
                error(message('MATLAB:lang:Workspace:variableNotFound', varName));
            end
            varValue = obj.m_workspace.getValue(varName);
            if isscalar(IO)
                [varargout{1:nargout}] = varValue;
            else
                [varargout{1:nargout}] = varValue.(IO(2:end));
            end
        end

        function obj = dotAssign(obj, IO, varargin)

            varName = IO(1).Name;
            if(isscalar(IO))
                obj.m_workspace.assignVariable(varName,varargin{:});
                return;
            end

            if obj.m_workspace.hasVariables(varName)
                varValue = obj.m_workspace.getValue(varName);
            else
                varValue = [];
            end

            [varValue.(IO(2:end))] = varargin{:};
            obj.m_workspace.assignVariable(varName, varValue);
        end

        function n = dotListLength(obj, IO, context)
            if(isscalar(IO))
                n = numel(obj);
                return;
            end

            firstLevelVarName = IO(1).Name;
            firstLevelVarValue = obj.m_workspace.getValue(firstLevelVarName);
            n = listLength(firstLevelVarValue,IO(2:end),context);
        end

        function displayScalarObject(obj)
            vars = getVariablesForDisplay(obj);
            numVars = height(vars);

            if numVars == 0
                text = getString(message('MATLAB:lang:Workspace:displayNoVariables'));
                fprintf(text + "\n\n");
                return;
            end

            displayHeader(obj);

            defaultNumDisplayVars = 20;
            wsName = inputname(1);

            if numVars <= defaultNumDisplayVars || isempty(wsName) || ~matlab.display.internal.isHotlinksSupported
                disp(vars);
                return;
            end

            disp(vars(1:defaultNumDisplayVars,:));
            fprintf("\t...\n\n");

            wsMissingMsg = getString(message('MATLAB:lang:Workspace:displayLinkMissingWorkspace', wsName));
            codeToExecute = sprintf("if exist('%s','var') && isa(%s,'matlab.lang.Workspace') && isvalid(%s)," + ...
                "displayAllVariables(%s),else,fprintf('%s\\n');end", wsName, wsName, wsName, wsName, wsMissingMsg);
            linkText = getString(message('MATLAB:lang:Workspace:displayLinkText', numVars));
            fprintf("\t<a href=""matlab:%s"">%s</a>\n\n", codeToExecute, linkText);
        end
    end

    methods(Hidden = true)
        function displayAllVariables(obj)
            displayHeader(obj);
            disp(getVariablesForDisplay(obj));
        end
    end

    methods(Static)
        obj = baseWorkspace();
        obj = currentWorkspace();
        obj = globalWorkspace();
    end

    methods
        function obj = Workspace(inputData)
            arguments
                inputData.Source (1,1) {mustBeA(inputData.Source ,"matlab.lang.Workspace")}
                inputData.Variables {mustBeValidVariableName, mustBeNonempty}
            end

            obj.m_workspace = matlab.lang.internal.WorkspaceData;
            obj.m_id = num2str(obj.m_workspace.getId());
            fn = fieldnames(inputData);
            if(isempty(fn))
                return
            end
            ln = length(fn);
            if(isequal(ln, 1))
                if(~isequal(fn{1},'Source'))
                    error(message('MATLAB:lang:Workspace:sourceNotProvided'));
                end
                obj.m_workspace.copyVariables(inputData.Source.m_workspace)
            end
            if(isequal(ln, 2))
                variableNames  = convertCharsToStrings(inputData.Variables);
                hasVarIdx = inputData.Source.m_workspace.hasVariables(variableNames{:});
                missingVars = inputData.Variables(~hasVarIdx);
                if ~isempty(missingVars)
                    missingVarStr = strjoin(missingVars, ', ');
                    error(message('MATLAB:lang:Workspace:variablesNotFoundInSource', missingVarStr));
                end
                obj.m_workspace.copyVariables(inputData.Source.m_workspace, variableNames);
            end
        end

        function names = properties(obj)
            names = convertStringsToChars(obj.m_workspace.listVariables);
        end
    end
end
