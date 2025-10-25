classdef GeneratedMexInterception < handle
%

%   Copyright 2024-2025 The MathWorks, Inc.

    properties (Access=private)
        % Cell array of generated MEX function names
        % e.g.: {'foo_mex', 'buzz_mex', ...}
        mexFunctions (1,:) cell

        % Cell array of source M-file names which correspond to the MEXes
        % e.g.: {'foo', 'buzz', ...}
        interceptionSources (1,:) cell

        % Cell array of cell arrays corresponding to the list of entry
        % point function names for each MEX
        % e.g.: {{'foo', 'foo_baz', 'foo_bar'}, {'buzz'}}
        entryPoints (1,:) cell

        % Array of ActivationInterception objects, each of which controls
        % interception for one entry point function
        activationObjs (1,:) coder.internal.ActivateInterception

        % Object of GeneratedMexInterceptionInfo, keeps track of which mex
        % functions have been invoked
        MexInterceptionInfo coder.internal.GeneratedMexInterceptionInfo;
    end

    methods
        function obj = GeneratedMexInterception(mexFunctions)
            arguments
                % Cell array of MEX function names
                % e.g.: {'foo_mex', 'buzz_mex'}
                mexFunctions (1,:) cell
            end

            obj.mexFunctions = mexFunctions;

            obj.MexInterceptionInfo = coder.internal.GeneratedMexInterceptionInfo();

            % Validate that the interception targets are all valid MEX
            % files which can be found on the path.
            for s = obj.mexFunctions
                if ~codergui.internal.util.isAbsolute(s{1})
                    error(message('Coder:builtins:MexInterceptionActivationNonAbsolutePath', s{1}));
                end
                if ~isfile(s{1})
                    error(message('Coder:builtins:MexInterceptionGenerationFileNotFound', s{1}));
                end
                symbolName = coderapp.internal.util.getQualifiedFileName(s{1});
                symbolPath = which(symbolName);
                if ~isempty(symbolPath) && exist(symbolPath,'file') ~= 3 % 3 indicates a MEX file
                    error(message('Coder:builtins:MexInterceptionGenerationMexNotOnPath', symbolName));
                end
            end

            % For each MEX file, determine and record all entry point
            % function names.
            obj.entryPoints = cell(1,numel(obj.mexFunctions));
            for i = 1:numel(obj.mexFunctions)
                s = obj.mexFunctions{i};
                mexPath = which(s);
                if isempty(mexPath)
                    error(message('Coder:builtins:MexInterceptionGenerationMexNotOnPath', s));
                end
                if ~strcmp(s, mexPath)
                    error(message('Coder:builtins:MexInterceptionActivationSymbolShadowed', s, mexPath));
                end
                obj.entryPoints{i} = obj.getMexEntryPoints(mexPath);
            end
        end

        function activateInterception(obj)
            % If we're already storing some activation objects, then just
            % re-register them. Don't re-add them. Trying to re-register an
            % already-registed interception is a no-op.
            if ~isempty(obj.activationObjs)
                for ao = obj.activationObjs
                    ao.activate();
                end
                return;
            end

            % Instead of assigning directly into obj.activationObjs, we use
            % this tempoarary local var and assign this to the class
            % property only at the end. This ensures that all the
            % activation objs are deleted if creation of any errors.
            tmpActivationObjs = coder.internal.ActivateInterception.empty;

            % Iterate through all the entry point functions and register
            % interceptions for them by the following steps:
            %  1) Construct a `dispatcher` struct with the information
            %     about the entry point function and its MEX
            %  2) Construct an ActivateInterception object, passing to it
            %     the entry point name and the `dispatch` function, which
            %     here directly captures the `dispatcher` struct we have
            %     just created.
            %  3) Store the ActivateInterception object so we can
            %     deactivate, reactivate, and clean up later.
            for i = 1:numel(obj.mexFunctions)
                ep = obj.entryPoints{i};
                dispatcher.isMultiEntryPoint = numel(ep) > 1;
                dispatcher.generatedMexName = ...
                    coderapp.internal.util.getQualifiedFileName(obj.mexFunctions{i});
                
                obj.MexInterceptionInfo.InvokedMexMap(dispatcher.generatedMexName) = false;

                for j = 1:numel(ep)
                    dispatcher.entryPointName = coderapp.internal.util.getQualifiedFileName(ep{j});
                    tmpActivationObjs(end+1) = createActivationObj(ep{j}, dispatcher, obj.MexInterceptionInfo); %#ok<AGROW>                  
                end
            end

            obj.activationObjs = tmpActivationObjs;
        end

        function deactivateInterception(obj)
            for ao = obj.activationObjs
                ao.deactivate();
            end
        end

        % The `delete` method cleans up the ActivateInterception object and
        % clearing the generated MEXes which are being redirected to.
        function delete(obj)
            for ao = obj.activationObjs
                delete(ao);
            end
            for mex = obj.mexFunctions
                clear(mex{1});
            end
        end
        
        function isInvoked = isMexInvoked(obj, mexFcn)
            isInvoked = obj.MexInterceptionInfo.InvokedMexMap(mexFcn);
        end
    end

    methods (Static)
        function y = isDebugModeEnabled
            y = coder.internal.ActivateInterception.isDebugModeEnabled;
        end
        function setDebugMode(x)
            coder.internal.ActivateInterception.setDebugMode(x);
        end
        function enableDebugMode
            coder.internal.ActivateInterception.enableDebugMode;
        end
        function disableDebugMode
            coder.internal.ActivateInterception.disableDebugMode;
        end
    end

    methods (Access=private, Static)
        function entryPointNames = getMexEntryPoints(mexPath)
            props = coder.internal.Project().getMexFcnProperties(mexPath);
            if ~isfield(props, 'EntryPoints')
                error(message('Coder:builtins:MexInterceptionGenerationInvalidMex', mexPath));
            end
            entryPointNames = unique({props.EntryPoints.ResolvedFilePath});
        end
    end
end

% The `dispatch` function will be passed as a handle to each
% copy of the synthetic MEX that will enable interception for a
% particular entry point function. It takes a `dispatcher`
% object, which is a simple struct that stores information
% about the MEX and the entry point. Varargin captures the
% arguments to be passed along to the MEX which intercepts the
% entry point.

% The `dispatcher` struct has the following fields:
%  * isMultiEntryPoint
%  * generatedMexName
%  * entryPointName
function varargout = dispatch(dispatcher, mexInterceptionInfo, varargin)
    if dispatcher.isMultiEntryPoint
        [varargout{1:nargout}] = feval( ...
            dispatcher.generatedMexName, ...
            dispatcher.entryPointName, ...
            varargin{:});
    else
        [varargout{1:nargout}] = feval( ...
            dispatcher.generatedMexName, ...
            varargin{:});
    end
    mexInterceptionInfo.InvokedMexMap(dispatcher.generatedMexName) = true;
end

% This constructor call is in its own free function so we can be extra sure
% that the anonymous function does not capture anything that it shouldn't,
% since this function handle will be stored in the synthetic MEX.
% Unintended capturing may cause issues.
function ao = createActivationObj(symbolName, dispatcher, mexInterceptionInfo)
    function varargout = kernel(varargin)
        [varargout{1:nargout}] = dispatch(dispatcher, mexInterceptionInfo, varargin{:});
    end

    ao = coder.internal.ActivateInterception(symbolName, @kernel);
end
