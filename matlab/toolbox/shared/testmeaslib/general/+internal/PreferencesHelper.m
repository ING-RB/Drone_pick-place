classdef PreferencesHelper < handle
    %PREFERENCESHELPER manages the preferences data that is
    %stored and used for creating default implementations.

    % Copyright 2019 The MathWorks, Inc.

    properties(Access = private)
        % GroupName - The group name for the preferences. This should be
        % common for your toolbox.
        GroupName (1, 1) string
        
        % PrefName - The preference name in the Group Name.
        PrefName (1, 1) string
    end
    
    methods
        function obj = PreferencesHelper(groupName, prefName)
            %PREFERENCESHELPER assigns and saves the prefname for the
            %transport.
            try
                obj.GroupName = groupName;
                obj.PrefName = prefName;
            catch ex
                throwAsCaller(ex);
            end
        end
        
        function data = getData(obj)
            % Get the data saved in the preferences. If the prefname or
            % group name is not present, a new one will be created using
            % the given pref name and group name.
            if ispref(obj.GroupName, obj.PrefName)
                data = getpref(obj.GroupName, obj.PrefName);
            else
                % If no data is present, create a new preference with the
                % given PrefName. Return empty data.
                data = [];
                setpref(obj.GroupName, obj.PrefName, data);
            end
        end
        
        function setData(obj, properties)
            % Set the preferences data.
            % Properties - This must be a struct, containing property names
            % and property values.
            validateattributes(properties, {'struct'}, {'nonempty'});
            setpref(obj.GroupName, obj.PrefName, properties);
        end
        
        function addData(obj, propertyName, value)
            % Add a new property value pair to the existing property value
            % pair of preferences.
            validateattributes(propertyName, {'string', 'char'}, {'nonempty'});
            data = obj.getData();
            
            % Data is empty if no preferences already exists.
            if isempty(data)
                data = struct(propertyName, value);
            else
                data.(propertyName) = value;
            end
            setpref(obj.GroupName, obj.PrefName, data);
        end
        
        function delete(obj)
            % Set the GroupName and PrefName to empty
            obj.GroupName = "";
            obj.PrefName = "";
        end
    end
    
    methods(Static, Hidden)
        function flag = removePref(groupName, prefName)
            % Remove a preference from Preferences using groupName and
            % prefName
            if ispref(groupName, prefName)
                rmpref(groupName, prefName);
                flag = true;
            else
                flag = false;
            end
        end
    end
end

