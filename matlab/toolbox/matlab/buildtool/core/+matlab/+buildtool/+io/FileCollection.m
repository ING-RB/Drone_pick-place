classdef FileCollection < ...
        matlab.buildtool.io.Buildable & ...
        matlab.mixin.internal.MatrixDisplay & ...
        matlab.mixin.CustomCompactDisplayProvider
    % FileCollection - Collection of files
    %
    %   The matlab.buildtool.io.FileCollection class represents a collection of
    %   files. You can use this class to define file-based inputs and outputs
    %   of a task.
    %
    %   When specifying the inputs and outputs of a task, you can use string
    %   vectors instead of FileCollection objects. MATLAB automatically
    %   converts string vectors to FileCollection objects.
    %
    %   To create a FileCollection object directly, use the Plan.files method.
    %
    %   FileCollection methods:
    %      fromPaths - Create file collections from paths
    %      paths     - Paths to files in the collection
    %      replace   - Find and replace one or more substrings in paths of the collection
    %      select    - Select files from the collection
    %      transform - Transform files in the collection
    %
    %   Example:
    %
    %      % Import the Task class.
    %      import matlab.buildtool.Task
    %
    %      % Create a plan with no tasks.
    %      plan = buildplan;
    %
    %      % Add a task that obfuscates all .m files in the folder "src".
    %      plan("pcode") = Task( ...
    %          Inputs="src/**/*.m", ...
    %          Outputs="src/**/*.p", ...
    %          Actions=@(ctx)pcode(ctx.Task.Inputs.paths{:},"-inplace"));
    %
    %      % Run the task.
    %      run(plan,"pcode");
    %
    %      % Run the task again. The build runner skips the task because none
    %      % of the input or output files has changed since the last run.
    %      run(plan,"pcode");
    %
    %      % Delete the .p files.
    %      delete(plan("pcode").Outputs.paths{:})
    %
    %      % Run the task again. The build runner runs the task because the
    %      % output files no longer exist.
    %      run(plan,"pcode");
    %
    %   See also matlab.buildtool.Plan.files, matlab.buildtool.Task, BUILDPLAN

    %   Copyright 2022-2024 The MathWorks, Inc.

    methods (Sealed)
        function p = paths(collection)
            % paths - Paths to files in the collection
            %
            %   PATHS = paths(COLLECTION) returns the paths to the files in
            %   COLLECTION as a string row vector.

            arguments
                collection matlab.buildtool.io.FileCollection
            end

            p = string.empty(1,0);
            for c = collection(:)'
                p = [p c.elementPaths()]; %#ok<AGROW>
            end
        end

        function ffc = select(collection, filter)
            % select - Select files from the collection
            %
            %   NEWCOLLECTION = select(COLLECTION,FILTER) returns a file
            %   collection consisting of files in COLLECTION whose paths
            %   satisfy the condition set by the function handle FILTER.
            %
            %   Example:
            %
            %      % Import the Task class.
            %      import matlab.buildtool.Task
            %
            %      % Create a plan with no tasks.
            %      plan = buildplan;
            %
            %      % Create a file collection including all .m files in the
            %      % current folder and its subfolders.
            %      mFiles = plan.files("**/*.m");
            %
            %      % Select the source files by excluding "buildfile.m".
            %      sourceFiles = mFiles.select(@(path) ~strcmpi(path,"buildfile.m"));
            %
            %      % Add a task that checks all source files for code issues.
            %      plan("check") = Task( ...
            %          Inputs=sourceFiles, ...
            %          Actions=@(ctx)codeIssues(ctx.Task.Inputs.paths()));
            %
            %      % Run the task.
            %      run(plan,"check");

            arguments
                collection matlab.buildtool.io.FileCollection
                filter (1,1) function_handle
            end
            import matlab.buildtool.io.FileCollection;

            if isempty(collection)
                ffc = collection;
                return;
            end

            ffc = [];
            for c = collection(:)'
                ffc = [ffc; c.selectElement(filter)]; %#ok<AGROW>
            end
            ffc = [ffc FileCollection.empty()];
            if isrow(collection)
                ffc = ffc';
            end
        end

        function tfc = transform(collection, transform, options)
            % transform - Transform files in the collection
            %
            %   NEWCOLLECTION = transform(COLLECTION,TRANSFORM) creates a file
            %   collection array, the same size as COLLECTION,
            %   whose paths are the paths in COLLECTION transformed
            %   by the function handle TRANSFORM. The method returns the new
            %   file collections as a matlab.buildtool.io.FileCollection array.
            %
            %   NEWCOLLECTION = transform(COLLECTION,TRANSFORM,AllowResizing=true)
            %   relaxes the constraint that NEWCOLLECTION must be the same size as COLLECTION.
            %   When you use this syntax, transforming a matlab.buildtool.io.File object returns a
            %   matlab.buildtool.io.FileCollection object. For example,
            %   tfc = fc.transform(@(path)[path replace(path,".m",".p")],AllowResizing=true)
            %   returns the file collection array, tfc, containing both the collections of source files,
            %   fc, and the collections of corresponding P-code files.
            %
            %   When you specify AllowResizing as true, the method returns
            %   NEWCOLLECTION as an array of
            %   matlab.buildtool.io.FileCollection objects with
            %   the same size as COLLECTION.
            %   
            %
            %   Example:
            %
            %      % Import the Task class.
            %      import matlab.buildtool.Task
            %
            %      % Create a plan with no tasks.
            %      plan = buildplan;
            %
            %      % Create a source file collection including all .m files
            %      % in the folder "src" and its subfolders.
            %      sourceFiles = plan.files("src/**/*.m");
            %
            %      % Transform each source file to a corresponding P-code file.
            %      pcodeFiles = sourceFiles.transform(@(path) replace(path,".m",".p"));
            %
            %      % Add a task that obfuscates all the source files.
            %      plan("pcode") = Task( ...
            %          Inputs=sourceFiles, ...
            %          Outputs=pcodeFiles, ...
            %          Actions=@(ctx)pcode(ctx.Task.Inputs.paths{:},"-inplace"));
            %
            %      % Run the task.
            %      run(plan,"pcode");

            arguments
                collection matlab.buildtool.io.FileCollection
                transform (1,1) function_handle
                options.AllowResizing (1,1) logical = false
            end
            import matlab.buildtool.io.FileCollection;

            if isempty(collection)
                tfc = collection;
                return;
            end

            tfc = [];
            for c = collection(:)'
                tfc = [tfc; c.transformElement(transform, AllowResizing=options.AllowResizing)]; %#ok<AGROW>
            end
            tfc = [tfc FileCollection.empty()];
            tfc = reshape(tfc, size(collection));
        end

        function tfc = replace(collection, old, new)
            % replace - Find and replace one or more substrings in paths of the collection
            %
            %   NEWCOLLECTION = replace(COLLECTION,OLD,NEW) replaces all occurrences
            %   of the substring OLD in paths of the specified file collection
            %   with NEW. If OLD contains multiple substrings, then NEW either
            %   must be the same size as OLD, or must be a single substring.
            %
            %   replace is a convenience method. For example, replace(collection,old,new)
            %   is functionally equivalent to transform(collection,@(path) replace(path,old,new)).
            %
            %   Example:
            %
            %      % Import the Task class.
            %      import matlab.buildtool.Task
            %
            %      % Create a plan with no tasks.
            %      plan = buildplan;
            %
            %      % Create a source file collection including all .m files
            %      % in the folder "src" and its subfolders.
            %      sourceFiles = plan.files("src/**/*.m");
            %
            %      % Transform each source file to a corresponding P-code file.
            %      pcodeFiles = sourceFiles.replace(".m",".p");
            %
            %      % Add a task that obfuscates all the source files.
            %      plan("pcode") = Task( ...
            %          Inputs=sourceFiles, ...
            %          Outputs=pcodeFiles, ...
            %          Actions=@(ctx)pcode(ctx.Task.Inputs.paths{:},"-inplace"));
            %
            %      % Run the task.
            %      run(plan,"pcode");

            tfc = collection.transform(@(p) p.replace(old, new));
        end
    end

    methods (Hidden, Sealed)
        function p = absolutePaths(collection)
            % absolutePaths - Absolute paths to files in the collection
            % 
            %   ABSOLUTE = absolutePaths(COLLECTION) returns the absolute paths
            %   to the files in COLLECTION as a string row vector.

            arguments
                collection matlab.buildtool.io.FileCollection
            end
            
            import matlab.buildtool.internal.io.absolutePath;

            p = string.empty(1,0);
            for c = collection(:)'
                p = [p absolutePath(c.paths())]; %#ok<AGROW>
            end
        end
    end

    methods (Static)
        function c = fromPaths(paths)
            % fromPaths - Create file collections from paths
            %
            %   C = matlab.buildtool.io.FileCollection.fromPaths(PATHS) creates file
            %   collections from the specified file and folder paths. The method
            %   returns collections as a matlab.buildtool.io.FileCollection array the
            %   same size as paths.

            arguments
                paths string {mustBeNonzeroLengthText}
            end

            import matlab.buildtool.io.Glob;
            import matlab.buildtool.io.File;
            import matlab.buildtool.io.FileCollection;

            c = FileCollection.empty();
            for p = paths(:)'
                if hasWildcard(p)
                    c = [c Glob(p)]; %#ok<AGROW>
                else
                    c = [c File(p)]; %#ok<AGROW>
                end
            end
            c = reshape(c, size(paths));
        end
    end

    methods (Access = protected)
        function ffc = selectElement(collection, filter)
            arguments
                collection (1,1) matlab.buildtool.io.FileCollection
                filter (1,1) function_handle
            end
            import matlab.buildtool.io.FilteredFileCollection;
            ffc = FilteredFileCollection(collection, filter);
        end

        function tfc = transformElement(collection, transform, options)
            arguments
                collection (1,1) matlab.buildtool.io.FileCollection
                transform (1,1) function_handle
                options.AllowResizing (1,1) logical = false
            end
            import matlab.buildtool.io.TransformedFileCollection;
            tfc = TransformedFileCollection(collection, transform, AllowResizing=options.AllowResizing);
        end
    end

    methods (Abstract, Access = protected)
        p = elementPaths(collection)
    end

    methods (Sealed, Hidden)
        function disp(collection, name)
            rep = textRepresentation(collection);
            
            % Temporarily replace quotes
            rep = strrep(rep, "'", char(1));

            % Let cellstr disp do the real work
            s = char(matlab.display.internal.obsoleteCellDisp(cellstr(rep)));

            % For N-D arrays, put array name in front of page header
            % e.g. '(:,:,1) = ' -> 'A(:,:,1) = '
            if ~ismatrix(collection) && nargin == 2
                s = regexprep(s, "(\([0-9:,]+\))", strcat(name,"$1"));
            end

            % Remove quotes that enclose each cell
            s = strrep(s, "'", " ");

            % Put embedded quotes back
            s = strrep(s, char(1), "'");
            
            fprintf("%s", s);
        end

        function rep = compactRepresentationForSingleLine(collection, displayConfiguration, width)
            rep = widthConstrainedDataRepresentation(collection, displayConfiguration, width, ...
                StringArray=textRepresentation(collection));
        end

        function rep = compactRepresentationForColumn(collection, displayConfiguration, width)
            rep = widthConstrainedDataRepresentation(collection, displayConfiguration, width, ...
                StringArray=textRepresentation(collection));
        end

        function rep = widthConstrainedDataRepresentation(collection, displayConfiguration, varargin)
            % Overridden to seal
            rep = widthConstrainedDataRepresentation@matlab.mixin.CustomCompactDisplayProvider(collection, displayConfiguration, varargin{:});
        end

        function rep = fitDisplayRepresentationToWidth(collection, displayConfiguration, varargin)
            % Overridden to seal
            rep = fitDisplayRepresentationToWidth@matlab.mixin.CustomCompactDisplayProvider(collection, displayConfiguration, varargin{:});
        end

        function rep = compactRepresentation(collection, displayConfiguration, varargin)
            % Overridden to seal
            rep = compactRepresentation@matlab.mixin.CustomCompactDisplayProvider(collection, displayConfiguration, varargin{:});
        end
    end

    methods (Sealed, Access = protected)
        function displayImpl(collection, name)
            % Overridden to seal
            displayImpl@matlab.mixin.internal.MatrixDisplay(collection, name);
        end

        function rep = textRepresentation(collection)
            rep = arrayfun(@elementTextRepresentation, collection);
            rep = [rep string.empty()];
        end
    end

    methods (Access = protected)
        function rep = elementTextRepresentation(collection)
            rep = simpleClassName(collection);
        end
    end
end

function tf = hasWildcard(pattern)
tf = contains(pattern, "*");
end

function n = simpleClassName(obj)
n = string(class(obj));
s = split(n, ".");
n = s(end);
end

% LocalWords:  buildfile buildplan fc inplace subfolders tfc NEWCOLLECTION
