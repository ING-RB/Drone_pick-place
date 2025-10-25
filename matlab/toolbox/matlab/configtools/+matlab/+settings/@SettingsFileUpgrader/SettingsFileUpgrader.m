classdef SettingsFileUpgrader < handle
    % SettingsFileUpgrader Supports backward compatibility of the user
    % settings
    %   This class implements methods necessary for upgrading the user
    %   settings in prefdir, when the factory settings tree undergoes an
    %   incompatible modification from one toolbox version to the next.

%   Copyright 2018-2019 The MathWorks, Inc.
    
    properties (Access = public)
        Version string
    end
    
    properties (Access = private)
        Transformations 
    end
    
    methods (Access = public)
        
        function obj = SettingsFileUpgrader(version)
            %SettingsFileUpgrader class constructor
            
            obj.Version = version;
        end
        
        function move(obj, what, where)
            % Move group/setting from path "what" to path "where".  Used
            % both for moving and renaming groups/settings.
            
            if (ischar(what))
                what = convertCharsToStrings(what);
            elseif (~isstring(what))
                error(message(...
                    'MATLAB:settings:config:PathMustBeStringOrChar', ... 
                    'Source'));
            end

            if (ischar(where))
                where = convertCharsToStrings(where);          
            elseif (~isstring(where))
                error(message(...
                    'MATLAB:settings:config:PathMustBeStringOrChar', ... 
                    'Destination'));
            end
            
            obj.Transformations(end+1).op = "move";
            obj.Transformations(end).what = what;
            obj.Transformations(end).where = where;
        end
        
        function remove(obj, what)
            % Remove group/setting from the factory settings tree.

            if (ischar(what))
                what = convertCharsToStrings(what);
            elseif (~isstring(what))
                error(message(...
                    'MATLAB:settings:config:PathMustBeStringOrChar', ... 
                    'Setting or group'));
            end
            obj.Transformations(end+1).op = "remove";
            obj.Transformations(end).what = what;
            obj.Transformations(end).where = string.empty;
        end
        
        %        function upgradeSetting(obj, what, upgradeFunction)
            % Upgrade setting "what" with the help of "upgradeFunction".
            
        %   if (~isstring(what))
        %       error(message(...
        %           'MATLAB:settings:config:ParameterMustBeString', ... 
        %           'what', 'SettingsFileUpgrader.upgradeSetting'));
        %   end
            
        %   if (~matlab.settings.internal.isValidFunctionHandle(what))
        %       error(message(...
        %           'MATLAB:settings:config:ParameterMustBeFunctionHandle', ... 
        %           'upgradeFunction', 'SettingsFileUpgrader.upgradeSetting'));
        %   end
            
        %   obj.transformations = [obj.transformations, ...
        %       ['upgradeSetting', what, ...
        %       func2str(upgradeFunction)]];
        % end
    end
end

