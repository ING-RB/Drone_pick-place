classdef FileCollectionValidator < matlab.buildtool.internal.validations.Validator
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2022-2023 The MathWorks, Inc.

    methods
        function msg = validate(validator, value)
            arguments
                validator (1,1) matlab.buildtool.internal.validations.FileCollectionValidator %#ok<INUSA>
                value (1,1) matlab.buildtool.io.FileCollection
            end

            import matlab.buildtool.validations.ValidationFailure;
            
            paths = value.absolutePaths();
            nonexistentPaths = paths(~isfile(paths) & ~isfolder(paths));
            
            if isempty(nonexistentPaths)
                msg = message.empty();
            else
                msg = message("MATLAB:buildtool:FileCollectionValidator:UnableToFindFilesOrFolders", "'"+strjoin(nonexistentPaths,"', '")+"'");
            end
        end
    end
end
