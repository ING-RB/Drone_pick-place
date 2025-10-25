classdef ExcludedPathStore < handle
    %

    % Copyright 2020-2023 The MathWorks, Inc.

    properties (Access = private)
        ExcludedPathEntries = string.empty;
    end

    methods (Static, Hidden, Access = private)
        function obj = getInstance()
            mlock;
            persistent instance
            if isempty(instance)
                instance = matlab.internal.path.ExcludedPathStore();
            end
            obj = instance;
        end
    end

    methods (Static, Hidden)
        % Adds the folder pathToExclude to the list of folders that savepath filters
        % from the path before generating pathdef.m.
        function addToCurrentExcludeList(pathToExclude)
            arguments (Input)
                pathToExclude (1,1) string
            end

            currentInstance = matlab.internal.path.ExcludedPathStore.getInstance();
            addToExcludeList(currentInstance, pathToExclude);
        end

        % Undoes the effect of addToCurrentExcludeList, given the same input argument.
        function removeFromCurrentExcludeList(pathToRestore)
            arguments (Input)
                pathToRestore (1,1) string
            end

            currentInstance = matlab.internal.path.ExcludedPathStore.getInstance();
            removeFromExcludeList(currentInstance, pathToRestore);
        end

        % Returns a string array containing the current list of excluded folders, each
        % of which is in canonicalized form. Exclude-list elements that cannot be
        % canonicalized are not included in the output.
        function excludeList = getCurrentExcludeList()
            arguments (Output)
                excludeList (1,:) string
            end

            currentInstance = matlab.internal.path.ExcludedPathStore.getInstance();
            excludeList = getExcludeList(currentInstance);
        end
    end

    methods (Access = private)
        function obj = ExcludedPathStore()
        end

        function excludeList = getExcludeList(obj)
            excludeList = rmmissing(arrayfun(@(pth) builtin("_canonicalizepath", pth), ...
                                             obj.ExcludedPathEntries, ...
                                             ErrorHandler = @(~, ~) string(missing)));
        end

        function addToExcludeList(obj, aPath)
            obj.ExcludedPathEntries(end+1) = aPath;
        end

        function removeFromExcludeList(obj, aPath)
            obj.ExcludedPathEntries(find(obj.ExcludedPathEntries == aPath, 1)) = [];
        end
    end
end
