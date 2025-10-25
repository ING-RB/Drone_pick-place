classdef AddonVersion
    %ADDONVERSIONUTILITIES utility to compare version strings of add-ons
    properties
        version
        numbers
    end
    
    properties (GetAccess = protected, Constant)
        %string values for open ended ranges
        Latest = "latest";
        Earliest = "earliest";
    end
    
    methods
        function obj = AddonVersion(version)
            if ~isstring(version) && ~ischar(version)
                error(message('matlab_addons:install:invalidAddonVersionInputType'));
            end  
            
            % Convert version to string to be consistent
            version = convertCharsToStrings(version);
            obj.version = version;
               
            if strcmp(version, obj.Latest)
                obj.numbers = inf;
            elseif strcmp(version, obj.Earliest)
            	obj.numbers = -inf;
            else
                isValidVersion = regexp(version, '^\d+(\.\d+){0,}$', "once");
                
                % Error out if Add-on version format is invalid
                if isempty(isValidVersion)
                    error(message('matlab_addons:install:invalidAddonVersionFormat'));
                end  
                obj.numbers = matlab.internal.addons.AddonVersion.splitVersionNumber(version);
            end
        end
        
        function versionString = getVersionString(obj)
           versionString =obj.version; 
        end
        
        function numbers = getNumbers(obj)
            numbers = obj.numbers;
        end
        
        function tf = lt(version1,version2)
            tf = compare(version1,version2)==-1;
        end
        
        function tf = gt(version1,version2)
            tf = compare(version1,version2)==1;
        end
        
        function tf = le(version1,version2)
            tf = compare(version1,version2)<=0;
        end
        
        function tf = ge(version1,version2)
            tf = compare(version1,version2)>=0;
        end
        
        function tf = eq(version1,version2)
            tf = compare(version1,version2)==0;
        end
        
        function inRange = isInRange(obj, earliest, latest)
            inRange = earliest<=obj && latest>=obj;
        end
    end
    
    methods( Access=private, Static)
        
        function compareValue = compareNumbers(a,b)
            if a > b
                compareValue = 1;
            elseif a < b
                compareValue = -1;
            else
                compareValue = 0;
            end
        end
        
        function numbers = splitVersionNumber(version)
            splitVersion = strsplit(version, '.');
            S = sprintf('%s ', splitVersion{:});
            numbers = sscanf(S, '%f');
            numbers = (numbers');
        end
        
        function [n1, n2, maxLength] = normalizeData(version1, version2)
            n1 = version1.getNumbers();
            n2 = version2.getNumbers();
            maxLength = max([length(n1), length(n2)]);
            n1(length(n1)+1:maxLength) = 0;
            n2(length(n2)+1:maxLength) = 0;
        end
    end
    
    methods(Access = private)
       function comparison = compare(obj, version2)
            [n1, n2, numSegments] = matlab.internal.addons.AddonVersion.normalizeData(obj, version2);
          
            comparison = 0; i = 1;
            while(comparison == 0 && i<(numSegments + 1))
                comparison = matlab.internal.addons.AddonVersion.compareNumbers(n1(i), n2(i));
                i = i + 1;
            end
        end 
    end
end