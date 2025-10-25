classdef FullPath < internal.matlab.editorconverters.datatype.AbstractFilePath
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Used as a property type for full paths
    
    % Copyright 2017-2020 The MathWorks, Inc.

    methods
        function obj = FullPath(varargin)
             % When a single object is inspected, varagin will be a single value.
             % But when inspecting multiple objects, use the last one in the
             % list, which is the default for inspecting multiple objects.
             obj = obj@internal.matlab.editorconverters.datatype.AbstractFilePath(varargin{end});        
        end
    end
    
    methods(Access = protected)
        function valid = validatePath(~, path)
            % a valid full path value is either:
            %   - empty
            %   - on the MATLAB path, so any(which(path)) && isequal(path, which(path))
            %   - not on the path, so ~any(which(path)) && exists(path, 'file')
            
            if isempty(path) ... 
                    || isequal(path, which(path)) ...
                    || (~any(which(path)) && exist(path, 'file')) ...
                    || any(which(path))
                valid = true;
            else
                error(struct('identifier', 'FullPath:FileNotFound', ...
                    'message', ['Could not locate file: ' char(path)]));
            end
        end
    end
end
