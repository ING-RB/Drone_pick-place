classdef SerialportPrefHandler < handle
    %SERIALPORTPREFSHANDLER handles the preferences data for the Serialport
    % object

    %   Copyright 2019-2023 The MathWorks, Inc.

    properties (Hidden, Access = private, Constant)
        % GroupName - The preference group name that saves the serialport
        % properties in the preferences.
        GroupName = "instrument_preferences"

        % PrefsType - The preferences name for serialport that contains the
        % saved serialport properties in the preferences.
        PrefsType = "serialport"
    end

    properties(Hidden, Constant)
        % List of properties that need to be saved in the Instrument
        % Preferences for Serialport.
        PreferencesPropertiesList = {'Port', 'BaudRate', 'ByteOrder', ...
            'FlowControl', 'StopBits', 'DataBits', 'Parity', 'Timeout', 'Terminator', 'Tag'}
    end

    properties (Access = ...
            {?internal.SerialportPrefHandler, ?instrument.internal.ITestable})
        % PreferencesHandler - Handle to the PreferencesHelper utility.
        PreferencesHandler
    end

    methods
        function obj = SerialportPrefHandler(varargin)
            % SERIALPORTPREFSHANDLER constructor instantiates the
            % internal Preferences Helper instance, or assigns the passed
            % in Preferences handler to PreferencesHandler.
            narginchk(0, 1);

            if nargin == 0
                obj.PreferencesHandler = ...
                    internal.PreferencesHelper(obj.GroupName, obj.PrefsType);
            else
                obj.PreferencesHandler = varargin{1};
            end
        end

        function [port, baudrate, terminator, nvPairs] = parsePreferencesHandler(obj)
            % Parse the data received from Preferences Helper,
            % validates the data, and returns it back to Serialport

            try
                % Get the data from the Preferences Meta Data
                serialPrefData = obj.PreferencesHandler.getData();

                % These method names need to be present in the serialport
                % preferences.
                fieldsTocheck = obj.PreferencesPropertiesList;
                
                % If data is empty, this indicateas that no last saved preferences
                % were found. Also, verify that all Preferences properties
                % are present in the data received from Preferences
                % Handler. Throw an error otherwise because all/some properties
                % required to create default serialport object were not
                % found.
                if isempty(serialPrefData) || ...
                        sum(isfield(serialPrefData, fieldsTocheck)) ~= length(fieldsTocheck)
                    throw(MException(message ( ...
                        'serialport:serialport:NoSavedPreferences')));
                end

                % Save the Port and BaudRate
                port = serialPrefData.Port;
                baudrate = serialPrefData.BaudRate;
                terminator = serialPrefData.Terminator;

                % Remove the Port and BaudRate from other properties and keep
                % the other properties as a cell array of NV Pairs.
                serialPrefData = rmfield(serialPrefData, {'Port', 'BaudRate', 'Terminator'});
                propertyNames = fieldnames(serialPrefData);
                nvPairs = {};
                for i = 1 : length(propertyNames)
                    nvPairs{end+1} = propertyNames{i}; %#ok<*AGROW>
                    nvPairs{end+1} = serialPrefData.(propertyNames{i});
                end
            catch ex
                throwAsCaller(ex);
            end
        end

        function updatePreferences(obj, preferencesData)

            % Update the Preferences Handler with the latest properties
            % from serialport.
            obj.PreferencesHandler.setData(preferencesData);
        end

        function delete(obj)
            if ~isempty(obj.PreferencesHandler)
                obj.PreferencesHandler = [];
            end
        end
    end

    methods(Static)
        function result = clearPreferences()
            % Clear the serialport preferences
            result = internal.PreferencesHelper.removePref ...
                (internal.SerialportPrefHandler.GroupName, ...
                internal.SerialportPrefHandler.PrefsType);
        end
    end
end