classdef MatFileInspector < matlab.depfun.internal.MwFileInspector
% MatFileInspector Determine what files and classes a MAT file requires.

% Copyright 2016-2020 The MathWorks, Inc.

    methods
        
        function obj = MatFileInspector(objs, fcns, flags)
            % Pass on the input arguments to the superclass constructor
            obj@matlab.depfun.internal.MwFileInspector(objs, fcns, flags);
        end
        
        function [identified_symbol, unknown_symbol] = determineType(obj, name) %#ok
            unknown_symbol = [];
            
            fullpath = '';
            if isfullpath(name)
                % WHICH cannot find .mat file even if the file full path is
                % given, when the file is not on the search path.
                if matlab.depfun.internal.cacheExist(name, 'file') == 2
                    fullpath = name;
                end
            else
                if matlab.depfun.internal.cacheExist(fullfile(pwd, name), 'file') == 2
                    fullpath = fullfile(pwd, name);
                else
                    fullpath = matlab.depfun.internal.cacheWhich(name);
                end
            end
                
            if isempty(fullpath)
                error(message('MATLAB:depfun:req:NameNotFound',name));
            end
                
            [~, filename, ext] = fileparts(fullpath);
            identified_symbol = matlab.depfun.internal.MatlabSymbol( ...
                    [filename ext], matlab.depfun.internal.MatlabType.Data, fullpath);
        end
        
    end % Public methods

    methods (Access = protected)
        
        function S = getSymbols(obj, file) %#ok
        % getSymbolNames returns symbols used in a .mat file.
            tS = {};
            % Known limitations:
            % matinfo only has information about classes. However, unlike
            % the previous implementation here using WHOS, it can see all
            % the classes in the mat file. At some point it would be useful
            % to get information about function handles as well. That is
            % dependent on a new format for mat files.
            try
                matInfoResult = matlab.matfile.internal.matinfo(file);
            catch
                matInfoResult =[];
            end
            
            if ~isempty(matInfoResult)
                % matinfo only returns classes right now
                tS = matInfoResult.classlist';
            end

            S = checkAlias(unique(tS));

        end
        
    end % Protected methods
end


