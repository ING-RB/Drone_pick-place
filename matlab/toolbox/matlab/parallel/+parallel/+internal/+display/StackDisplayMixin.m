% StackDisplayMixin - Used for formatting error and warnings stacks

% Copyright 2015-2020 The MathWorks, Inc.

classdef (Hidden) StackDisplayMixin
    methods (Abstract, Access = protected)
        % Used to help build error and warning stacks for display on the client.
        list = listAttachedFilesAndPaths(obj)
    end

    methods (Access = protected)
        function stackString = getStackCellStr(obj, stack, showLinks)
            % Display the stack, hotlinking as required
            numStacks = numel(stack);
            stackString = cell(numStacks, 1);

            % We'll need to show links to error stack frames, but preferably not
            % from the temporary AttachedFiles location, so work out
            % what was supplied with the job in the AttachedFiles and AdditionalPaths.
            jobFilesAndPaths = listAttachedFilesAndPaths(obj);
            [jobFiles, jobFilenames] = iGetAllMATLABFiles(jobFilesAndPaths);
            for ii = 1:numStacks
                currStack = stack(ii);
                [~, filename] = fileparts(currStack.file);
                stackString{ii} = parallel.internal.display.StackDisplayMixin.getStackString(currStack, filename);
                % If there is no file to open, because, for example, the task is using an
                % anonymous function, we should not link to anything.
                if showLinks && ~isempty(filename)
                    stackString{ii} = char(obj.getHTMLStackItem(currStack, stackString{ii}, filename, jobFiles, jobFilenames));
                end
            end
        end

        function htmlStackItem = getHTMLStackItem(~, currStack, stackString, erroredFilename, jobFiles, jobFilenames)
            % If the file was supplied in the AttachedFiles / AdditionalPaths
            % then use that as the link so we have a hope of referencing it
            % correctly on the client, otherwise use the actual
            % file in the error stack.
            matchingFile = find(strcmpi(jobFilenames, erroredFilename), 1, 'first');
            if isempty(matchingFile)
                linkFile = currStack.file;
            else
                linkFile = jobFiles{matchingFile};
            end
            matlabCommand = sprintf('opentoline(''%s'', %d, 0)', ...
                linkFile, currStack.line);
            htmlStackItem = parallel.internal.display.HTMLDisplayType(stackString, matlabCommand);
        end

    end

    methods ( Static )
        function stackString = getStackString(currStack, erroredFilename)
            if strcmp(currStack.name, erroredFilename)
                fileDisplayName = erroredFilename;
            else
                fileDisplayName = sprintf('%s>%s', erroredFilename, currStack.name);
            end
            stackString = getString(message('MATLAB:parallel:display:CodeLine', ...
                                            fileDisplayName, currStack.line));
        end
    end
end

function [fullFilePaths, filenames] = iGetAllMATLABFiles(allLocations)
    fullFilePaths = {};
    for ii = 1:numel(allLocations)
        currLocation = allLocations{ii};
        if exist(currLocation, 'dir')
            relevantContents = what(currLocation);
            % We need to correctly concatenate all the contents of the
            % output of what together. So firstly get the outputs as a cell
            % array of vertical cell arrays, then concatenate that
            % together. The assumption below is that whatever structure
            % array is given to the arrayfun call below it will have a '.m'
            % field to dereference.
            namesCell =  arrayfun( @(x) x.m(:), relevantContents, 'UniformOutput' , false);
            names = vertcat(namesCell{:});
            fullMFilePaths = fullfile(currLocation, names);
            fullFilePaths = [fullFilePaths; fullMFilePaths]; %#ok<AGROW>
            % TODO - can we bothered to traverse the packages too?
        elseif exist(currLocation, 'file')
            fullFilePaths = [fullFilePaths; currLocation]; %#ok<AGROW>
        end
    end
    % Get just the filename as well
    [~, filenames] = cellfun(@fileparts, fullFilePaths, 'UniformOutput', false);
end
