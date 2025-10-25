classdef Workspace < handle & matlab.mixin.indexing.RedefinesDot &...
    matlab.mixin.indexing.OverridesPublicDotMethodCall &...
    matlab.mixin.internal.indexing.DisallowCompletionOfDotMethodNames
%

%   Copyright 2020-2024 The MathWorks, Inc.

    properties (Access = private, Hidden = true)
        m_workspace
        m_id
    end

    methods(Access = protected)
        function varargout = dotReference(obj, IO)

            varName = IO(1).Name;
            if( ismethod(obj,varName))
                error('Dot invocation of method is not supported');
            end
            VarValue = obj.m_workspace.getValue(varName);
            if isscalar(IO)
                [varargout{1:nargout}] = VarValue;
            else
                [varargout{1:nargout}] = VarValue.(IO(2:end));

            end
        end

        function obj = dotAssign(obj, IO, varargin)

            VarName = IO(1).Name;
            if( ismethod(obj,VarName))
                error('Variable name cannot be same as method name');
            end
            if(isscalar(IO))
                obj.m_workspace.assignVariable(VarName,varargin{:});
                return;
            end

            if obj.m_workspace.hasVariables(VarName)
                VarValue = obj.m_workspace.getValue(VarName);
            else
                VarValue = [];
            end

            [VarValue.(IO(2:end))] = varargin{:};
            obj.m_workspace.assignVariable(VarName, VarValue);
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
    end

    methods
        function obj = Workspace(varargin)
           obj.m_workspace = matlab.lang.internal.WorkspaceData;
           obj.m_id = num2str(obj.m_workspace.getId());

           if(isempty(varargin))
               return;
           end
           for in = 1:nargin
               obj.m_workspace.assignVariable(varargin{in},evalin('caller',varargin{in}, '[]'));
           end
        end

        function copyVariables(obj, src, args)
            arguments
                obj
                src
                args.Variables {mustBeText} = string.empty
            end
            if (isa(src, "matlab.lang.internal.Workspace"))
                srcWS = src.m_workspace;
            else
                srcWS = src;
            end
            if (~isempty(args.Variables))
                obj.m_workspace.copyVariables(srcWS, args.Variables);
            else
                obj.m_workspace.copyVariables(srcWS);
            end
        end

        function val = getValue(obj,var)
            val = obj.m_workspace.getValue(var);
        end

        function val = hasVariables(obj,var)
            val = obj.m_workspace.hasVariables(var);
        end

        function assignVariable(obj,var,val)
            obj.m_workspace.assignVariable(var,val);
        end

        function varargout = evaluateIn(obj,expression)
            [varargout{1:nargout}] = obj.m_workspace.evaluateIn(expression);
        end

        function out = listVariables(obj)
            out = obj.m_workspace.listVariables();
        end

        function clearVariables(obj,varargin)
            obj.m_workspace.clearVariables(varargin{:});
        end

        function listener = registerVariablesChangedListener(obj, callback)
            listener = matlab.internal.mvm.eventmgr.MVMEvent.subscribe(...
                strcat("::MathWorks::ExecutionEvents::VariablesChangedInDesiredWorkspaceEvent", obj.m_id), callback);
        end

        function listener = registerVariablesDeletedListener(obj, callback)
            listener = matlab.internal.mvm.eventmgr.MVMEvent.subscribe(...
                strcat("::MathWorks::ExecutionEvents::VariablesDeletedInDesiredWorkspaceEvent", obj.m_id), callback);
        end

        function listener = registerWorkspaceClearedListener(obj, callback)
            listener = matlab.internal.mvm.eventmgr.MVMEvent.subscribe(...
                strcat("::MathWorks::ExecutionEvents::ClearedDesiredWorkspaceEvent", obj.m_id), callback);
        end

        function  C = horzcat(varargin)
            error('Cannot concatenate');
        end

        function C =  vertcat(varargin)
            error('Cannot concatenate');
        end
    end
end
