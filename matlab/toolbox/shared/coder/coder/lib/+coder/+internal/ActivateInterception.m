classdef ActivateInterception < handle
    properties (Access=private)
        % Cell array of intercepted symbol names.
        % e.g.: {"foo", "bar"}
        interceptedSymbolNames (1,:) cell

        % Cell array of intercepted symbol paths.
        % e.g.: {'/path/to/my/file/', '/home/me/Documents'}
        interceptedSymbolPaths (1,:) cell

        % Cell array of handles to the dispatch functions, one for each of
        % the entry points functions.
        % e.g.: {@zeros, @ones}
        fcnHandles (1,:) cell

        % Cell array of booleans indicating whether interception for each
        % symbol is activated.
        isActivated (1,:) cell
    end

    properties (GetAccess=private, SetAccess=immutable)
        % This is the private key which, when passed to the synthetic
        % interception MEX, will allow certain important actions, such as
        % setting the dispatch function and unlocking the MEX.
        token = '220518022113-03011815-060103202113-051920';
    end

    methods
        function obj = ActivateInterception(interceptedSymbolPaths, dispatchFcnHandles)
            arguments (Repeating)
                interceptedSymbolPaths (1,1) string
                dispatchFcnHandles (1,1) function_handle
            end

            sortedPaths = sort([interceptedSymbolPaths{:}]);
            prevPath = sortedPaths(1);
            for i = 2:numel(sortedPaths)
                if strcmp(prevPath, sortedPaths(i))
                    error(message( ...
                        'Coder:builtins:MexInterceptionActivationDuplicateInterception', ...
                        sortedPaths(i)));
                end
                prevPath = sortedPaths(i);
            end

            numSymbols = numel(interceptedSymbolPaths);
            for i = 1:numSymbols
                s = interceptedSymbolPaths{i};

                if ~codergui.internal.util.isAbsolute(s)
                    error(message('Coder:builtins:MexInterceptionActivationNonAbsolutePath', s));
                end

                if ~isfile(s)
                    error(message('Coder:builtins:MexInterceptionActivationFileNotFound', s));
                end

                symbolName = coderapp.internal.util.getQualifiedFileName(s);
                if contains(symbolName, '.')
                    error(message('Coder:builtins:MexInterceptionActivationNamespace', s));
                end

                if ~isempty(meta.class.fromName(symbolName))
                    error(message('Coder:builtins:MexInterceptionActivationConstructor', s));
                end

                filepath = fileparts(s);
                obj.interceptedSymbolNames{end+1} = symbolName;
                obj.interceptedSymbolPaths{end+1} = filepath;
            end

            obj.fcnHandles = dispatchFcnHandles;
            obj.isActivated = repmat({false},1,numSymbols);

            % Upon construction of an ActivateInterception object, we will
            % activate the interception. After this, interception can be
            % activated/deactivated on demand.
            obj.activate();
        end

        % Activating interception consists of the following steps,
        % performed for each entry point function:
        %  1) Copy the synthetic MEX to the desired directory, renaming it
        %     to have the same name as the entry point function.
        %  2) Register the dispatch function by calling the newly-copied
        %     synthetic MEX and providing the token.
        function activate(obj)
            % Double check before copying the file that a file with the
            % same name doesn't already exist, since we don't want to
            % overwrite any files that the user has placed there.
            for i = 1:numel(obj.interceptedSymbolNames)
                symbolName = obj.interceptedSymbolNames{i};
                destMexName = constructMexName(symbolName, ...
                    obj.interceptedSymbolPaths{i});
                if ~obj.isActivated{i} && isfile(destMexName)
                    % We error if activation would create a MEX file that
                    % has the same name as an existing one. However, if
                    % interception for this particular symbol is recorded
                    % as being active, we instead silently continue and let
                    % activation be a NO-OP.
                    error(message( ...
                        'Coder:builtins:MexInterceptionActivationFileAlreadyExists', ...
                        symbolName, destMexName));
                end
            end

            for i = 1:numel(obj.interceptedSymbolNames)
                symbolName = obj.interceptedSymbolNames{i};
                symbolPath = obj.interceptedSymbolPaths{i};
                destMexName = constructMexName(symbolName, symbolPath);
                if obj.isActivated{i} && isfile(destMexName)
                    % We can treat this is a NO-OP if interception for this
                    % symbol is marked as active, but only if the MEX file
                    % exists.
                    continue;
                end
                copyfile(getSyntheticMexPath(), destMexName);
                resolvedName = which(symbolName);
                if isempty(resolvedName) || exist(resolvedName, 'file') ~= 3 % indicates MEX
                    cleanup = onCleanup(@obj.delete);
                    error(message('Coder:builtins:MexInterceptionActivationNotOnPath', ...
                        symbolName));
                end
                if ~strcmp(resolvedName, destMexName)
                    cleanup = onCleanup(@obj.delete);
                    error(message( ...
                        'Coder:builtins:MexInterceptionActivationSymbolShadowed', ...
                        destMexName, resolvedName));
                end
                fh = str2func(symbolName);
                fh(obj.token,'REGISTER',obj.fcnHandles{i});
                obj.isActivated{i} = true;
            end
        end

        function deactivate(obj, calledFromDestructor)
            arguments
                obj
                calledFromDestructor = false
            end
            errorMsg = [];
            if isempty(obj.interceptedSymbolNames)
                % We've already deleted this object.
                return;
            end
            for i = 1:numel(obj.interceptedSymbolNames)
                symbolName = obj.interceptedSymbolNames{i};
                symbolPath = obj.interceptedSymbolPaths{i};
                mexName = constructMexName(symbolName, symbolPath);
                if ~isfile(mexName)
                    if obj.isDebugModeEnabled
                        warning(message( ...
                            'Coder:builtins:MexInterceptionDeactivationNotActive', ...
                            symbolName));
                    end
                    continue;
                end
                fullSymbolPath = fullfile(symbolPath, strcat(symbolName,'.',mexext));
                resolvedName = which(symbolName);
                if ~strcmp(resolvedName, fullSymbolPath)
                    msg = message( ...
                        'Coder:builtins:MexInterceptionDectivationSymbolShadowed', ...
                        fullSymbolPath, resolvedName);
                    if calledFromDestructor
                        % If deactivation is occurring because the object
                        % is being destructed, don't warn or error, just
                        % display the message.
                        disp(getString(msg));
                    elseif isempty(errorMsg)
                        % Don't error yet, just record the first error for
                        % now, so we can ensure we first clean up
                        % everything else.
                        errorMsg = msg;
                    else
                        % If there are more than one instances of this
                        % error, just warn. At the end, we'll error on the
                        % first message.
                        warning(msg);
                    end
                else
                    fh = str2func(symbolName);
                    fh(obj.token,'UNLOCK');
                    clear(symbolName);
                    delete(mexName);
                end
                obj.isActivated{i} = false;
            end
            % ensure that MATLAB recognizes that the interception MEXes
            % have been deleted
            rehash;
            if ~isempty(errorMsg)
                error(errorMsg);
            end
        end

        % In order to clear the MEXes from memory, we need to first unlock
        % them, which we do below.
        function delete(obj)
            obj.deactivate(true);
        end
    end

    methods (Static)
        function y = isDebugModeEnabled
            y = coder.internal.mexInterceptionDebugMode;
        end
        function setDebugMode(x)
            coder.internal.mexInterceptionDebugMode(x);
        end
        function enableDebugMode
            coder.internal.ActivateInterception.setDebugMode(true);
        end
        function disableDebugMode
            coder.internal.ActivateInterception.setDebugMode(false);
        end
    end
end

function mexPath = getSyntheticMexPath()
    mexPath = which('coder.internal.mexRedirection');
end

function mexName = constructMexName(fcnName, fcnPath)
    mexName = fullfile(fcnPath, strcat(fcnName,'.',mexext));
end