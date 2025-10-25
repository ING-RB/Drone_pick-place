classdef StylesheetCache
    %STYLESHEETCACHE Cache a style sheet
    
    %   Copyright 2020-2022 The MathWorks, Inc.

    methods (Static,Access=private)
        
        function v = CachedID(varargin)
            % MATLAB implementation of a Java static field
            persistent ID
            if nargin > 0
                ID = varargin{1};
            end
            v = ID;
        end
        
        function v = CachedStylesheet(varargin)
            persistent CachedStylesheet
            if nargin > 0
                CachedStylesheet = varargin{1};
            end
            v = CachedStylesheet;
        end
        
    end
    
    methods (Static)
        
        function ss = getCachedStylesheet(varargin)
            % Return the cached stylesheet if its id is equal to the input ID
            import rptgen.internal.output.StylesheetCache
            if nargin < 1
                ss = StylesheetCache.CachedStylesheet;
            else
                id = varargin{1};
                if ~isempty(StylesheetCache.CachedID) && ...
                        StylesheetCache.CachedID == string(id)
                    ss = StylesheetCache.getCachedStylesheet();
                else
                    ss = [];
                end
            end
        end
        
        function clearCachedStylesheet(varargin)
            % clear the cached stylesheet if its id is equal to the
            % input ID
            import rptgen.internal.output.StylesheetCache
            if nargin < 1
                StylesheetCache.CachedID([]);
                StylesheetCache.CachedStylesheet([]);
            else
                clearID = varargin{1};
                if ~isempty(StylesheetCache.CachedID) && ...
                        StylesheetCache.CachedID == clearID
                    StylesheetCache.CashedID([]);
                    StylesheetCache.CachedStylesheet([]);
                end
            end
        end
        
        function setCachedStylesheet(newID,newStylesheet)
            import rptgen.internal.output.StylesheetCache
            StylesheetCache.CachedID(newID);
            StylesheetCache.CachedStylesheet(newStylesheet);
        end
        
    end
    
end



