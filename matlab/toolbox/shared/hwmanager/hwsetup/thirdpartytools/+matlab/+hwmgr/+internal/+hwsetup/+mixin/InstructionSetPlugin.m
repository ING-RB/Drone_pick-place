classdef InstructionSetPlugin < handle & matlab.mixin.SetGet
    %INSTRUCTIONSETPLUGIN is a class designed to manage and interact
    % with a collection of instruction set objects.
    %
    % Example Usage:
    %   plugin = InstructionSetPlugin('/path/to/folder');
    %   instructionSet = plugin.getInstructionSet('desiredInstructionSetName');
    %   allInstructionSets = plugin.getAllInstructionSets();
    %   installStatus = plugin.getInstallStatus({'name1', 'name2'});
    %
    % See also: matlab.hwmgr.internal.getInstructionSetsFromFolder

    properties(Access = protected)
        InstructionSets (1, :) cell % Cell array to store instruction set objects.
    end

    methods
        function obj = InstructionSetPlugin(folder)

            % Initialize
            allInstructionSets = {};
            if ~iscell(folder)
                folder = {folder}; % Convert to cell array
            end
            for i = 1:length(folder)
                currentFolder = folder{i};
                currentInstructionSets = matlab.hwmgr.internal.getInstructionSetsFromFolder(currentFolder);
                allInstructionSets = vertcat(allInstructionSets(:), currentInstructionSets(:));
            end
            obj.InstructionSets = allInstructionSets;
        end

        function out = getInstructionSet(obj, name)
            % Retrieves one or more instruction set objects by their names.
            % This method now supports input as either a single name
            % (string/character vector)or a cell array of names. In the
            % case of a cell array, it returns a cell array of matching
            % instruction set objects.

            if ~iscell(name)
                name = {name};
            end
            out = {}; 
            for i = 1:length(name)
                index = cellfun(@(x) strcmp(x.getInstructionSetName(), name{i}), obj.InstructionSets);
                matchIndex = find(index, 1); % Find the index of the first match
                if ~isempty(matchIndex)
                    out{end+1} = obj.InstructionSets{matchIndex}; % Add the matching instruction set to 'out'
                end
            end
        end

        function out = getAllInstructionSets(obj)
            %getAllInstructionSets Returns all instruction set objects
            % loaded into the plugin.

            out = obj.InstructionSets;
        end

        function status = getInstallStatus(obj, cellarraynames)
            % getInstallStatus Returns the installation status of specified
            % instruction sets.

            status = cell(1, length(cellarraynames));
            for i = 1:length(cellarraynames)
                currentIndex = cellfun(@(x) strcmp(x.getInstructionSetName(), cellarraynames{i}), obj.InstructionSets);
                if any(currentIndex)
                    istobj = obj.InstructionSets{find(currentIndex, 1)}; % Get the first matching InstructionSet.
                    status{i} = istobj.isInstalled();
                else
                    status{i} = false;
                end
            end
        end
    end
end