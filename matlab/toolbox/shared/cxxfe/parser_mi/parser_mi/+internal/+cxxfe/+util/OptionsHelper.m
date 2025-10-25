%

%   Copyright 2013-2019 The MathWorks, Inc.

classdef OptionsHelper
    
    methods (Static)
        
        %% Public Static Method: deepCopy --------------------------------
        %  Abstract:
        %
        function dst = deepCopy(src)
            clsInfo = metaclass(src);
            dst = feval(clsInfo.Name);
            
            for ii = 1:numel(clsInfo.PropertyList)
                propName = clsInfo.PropertyList(ii).Name;
                if ~strcmpi(clsInfo.PropertyList(ii).GetAccess, 'public') || ...
                        ~strcmpi(clsInfo.PropertyList(ii).SetAccess, 'public')
                    continue
                end
                
                if ~isobject(src.(propName)) || isenum(src.(propName))
                    dst.(propName) = src.(propName);
                else
                    dst.(propName) = internal.cxxfe.util.OptionsHelper.deepCopy(src.(propName));
                end
            end
        end

        %% Public Static Method: toStruct ---------------------------------
        %  Abstract:
        %
        function out = toStruct(src)
            clsInfo = metaclass(src);
            out = struct();
            for ii = 1:numel(clsInfo.PropertyList)
                if ~strcmpi(clsInfo.PropertyList(ii).GetAccess, 'public') || ...
                        ~strcmpi(clsInfo.PropertyList(ii).SetAccess, 'public')
                    continue
                end
                propName = clsInfo.PropertyList(ii).Name;
                if ~isobject(src.(propName))
                    out.(propName) = src.(propName);
                else
                    if isenum(src.(propName))
                        out.(propName) = char(src.(propName));
                    else
                        out.(propName) = internal.cxxfe.util.OptionsHelper.toStruct(src.(propName));
                    end
                end
            end
        end
        
    end
end

