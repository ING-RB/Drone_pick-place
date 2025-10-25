classdef (Hidden) EditorUtils
%EDITORUTILS Static utility methods for matlab.desktop.editor functions
%
%   This function is unsupported and might change or be removed without
%   notice in a future version.

% These are utility functions to be used by matlab.desktop.editor
% functions and are not meant to be called by users directly.

% Copyright 2009-2023 The MathWorks, Inc.

    methods (Access = private)
        function obj = EditorUtils
            obj = [];
        end
    end

    methods (Static)
        function storageLocation = fileNameToStorageLocation(filename)
        %fileNameToStorageLocation Convert string file name to StorageLocation object.
            storageLocation = com.mathworks.widgets.datamodel.FileStorageLocation(filename);
        end

        function jea = getJavaEditorApplication
        %getJavaEditorApplication Return Java Editor application.
            jea = com.mathworks.mlservices.MLEditorServices.getEditorApplication;
        end

        function lea = getLiveEditorApplication
        %getLiveEditorApplication Return Live Editor application.
            lea = com.mathworks.mde.liveeditor.LiveEditorApplication.getInstance;
        end

        function isPlainCodeSupported = isPlainCodeInLiveEditorSupported
        %isPlainCodeInLiveEditorSupported Returns true if the plain
        %code files are supported in the Live Editor.
            isPlainCodeSupported = com.mathworks.services.mlx.MlxFileUtils.isPlainCodeInLiveEditorSupported;
        end

        function isFileSupported = isFileSupportedInLiveEditor(filename)
        %isFileSupportedInLiveEditor Returns true if the file is supported in the Live Editor.
            isFileSupported = com.mathworks.services.mlx.MlxFileUtils.isFileSupportedInLiveEditor(filename);
        end

        function result = isLiveCodeFile(filename)
            % Calls the private API to return is live or not
            result = isLive(filename);
        end

        function result = isAbsolute(filename)
        %isAbsolute Returns true if the filename is an absolute path
            if ispc
               result = ~isempty(regexp(filename,'^[a-zA-Z]*:\/','once')) ...
                        || ~isempty(regexp(filename,'^[a-zA-Z]*:\\','once')) ...
                        || strncmp(filename,'\\',2) ...
                        || strncmp(filename,'//',2);
            else
               result = strncmp(filename,'/',1);
            end
        end

        function canonicalPath = getCanonicalPath(filename)
        %getCanonicalPath Returns canonicalized path for input filename.
        % If the path cannot be canonicalized then returns the input filename.
            try
                canonicalPath = builtin('_canonicalizepath', filename);
            catch
                canonicalPath = filename;
            end
        end

        function assertOpen(obj, variablename)
        %assertOpen Throw error if Editor Document is not open.
            try
                assert(isa(obj, 'matlab.desktop.editor.DocumentInterface'), ...
                       message('MATLAB:Editor:Document:InvalidDocumentInput', variablename));
                assert(~isempty(obj) && all([obj.Opened]), ...
                       message('MATLAB:Editor:Document:EditorClosed'));
            catch ex
                throwAsCaller(ex);
            end
        end

        function assertScalar(obj)
        %assertScalar Throw error for non-scalar input.
            try
                assert(ischar(obj) || numel(obj) <= 1, ...
                       message('MATLAB:Editor:Document:NonScalarInput'));
            catch ex
                throwAsCaller(ex);
            end
        end

        function assertChar(obj, variablename)
        %assertChar Throw error if the input is not a 1-by-n or n-by-1 char vector.
            try
                assert(ischar(obj) && (isempty(obj) || isvector(obj)), ...
                       message('MATLAB:Editor:Document:NonStringInput', variablename));
            catch ex
                throwAsCaller(ex);
            end
        end

        function assertNumericScalar(input, variablename)
        %assertNumericScalar Throw error if the input is not a numeric scalar.
            try
                assert(isnumeric(input) && isscalar(input) && ~isnan(input), ...
                       message('MATLAB:Editor:Document:NonNumericScalarInput', variablename));
            catch ex
                throwAsCaller(ex);
            end
        end

        function assertLessEqualInt32Max(input, variablename)
        %assertLessEqualInt32Max Throw error if the input is greater than maximum of 32-bit integer.
            try
                assert(isnumeric(input) && isscalar(input) && ~isnan(input) && input <= intmax('int32'), ...
                       message('MATLAB:Editor:Document:Invalid32BitInteger', variablename));
            catch ex
                throwAsCaller(ex);
            end
        end

        function assertPositiveLessEqualInt32Max(input, variablename)
        %assertPositiveLessEqualInt32Max Throw error if the input is negative or greater than maximum of 32-bit integer.
            try
                assert(isnumeric(input) && isscalar(input) && ~isnan(input) && input >= 0 && input <= intmax('int32'), ...
                       message('MATLAB:Editor:Document:Invalid32BitNegativeInteger', variablename));
            catch ex
                throwAsCaller(ex);
            end
        end

        cellArray = javaCollectionToArray(javaCollection)
    end
end
