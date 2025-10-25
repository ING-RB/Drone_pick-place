classdef FileName < internal.matlab.editorconverters.datatype.AbstractFilePath
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Used as a property type for filenames
    
    % Copyright 2017-2020 The MathWorks, Inc.
    
    methods
        function obj = FileName(varargin)
             % When a single object is inspected, varagin will be a single value.
             % But when inspecting multiple objects, use the last one in the
             % list, which is the default for inspecting multiple objects.
             obj = obj@internal.matlab.editorconverters.datatype.AbstractFilePath(varargin{end});        
        end
    end
    
    methods(Access = protected)
        function valid = validatePath(~, path)
            % a valid file name value is either:
            %   - empty
            %   - on the MATLAB path and includes a file extension
            
            [~, ~, ext] = fileparts(path);
            if isempty(path) || (~isempty(ext) && any(which(path)))
                valid = true;
            else
                error(struct('identifier', 'FileName:FileNotFound', ...
                    'message', ['Could not locate file on MATLAB path: ' path]));
            end
        end
    end
end
