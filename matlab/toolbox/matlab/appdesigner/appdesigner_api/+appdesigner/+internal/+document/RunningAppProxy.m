classdef RunningAppProxy < handle
    % RunningAppProxy Called by appdesigner.internal.document.AppDocument
    % to access and assess the running app

    % Copyright 2022 - 2024 The MathWorks, Inc.

    properties(Access = private)
        RunningApp
    end

    methods
        function obj = RunningAppProxy(runningApp)
            obj.RunningApp = runningApp;
        end

        function closeApp(obj)
            % Closes running instance of app
            obj.RunningApp.delete();
        end

        function executeCallback(obj, componentCodeName, callbackPropertyName, eventData)
            arguments
                obj
                componentCodeName string
                callbackPropertyName string
                eventData = []
            end

            if (isprop(obj.RunningApp, componentCodeName) ...
                    && isprop(obj.RunningApp.(componentCodeName), callbackPropertyName))
                component = obj.RunningApp.(componentCodeName);
                callback = component.(callbackPropertyName);

                if ~isempty(callback)
                    callback(component, eventData);
                end
            end
        end

        function executeButtonPushedFcn(obj, buttonCodeName)
            % Executes ButtonPushedFcn callback in running app

            obj.executeCallback(buttonCodeName, 'ButtonPushedFcn');
        end

        function executeValueChangedFcn(obj, componentCodeName)
            % Executes ValueChangedFcn callback in running app

            obj.executeCallback(componentCodeName, 'ValueChangedFcn');
        end

        function value = getPropertyValue(obj, propertyName)
            % Returns property value in running app (public or private)

            % Exposing private properties
            warning off MATLAB:structOnObject;
            runningApp = struct(obj.RunningApp);

            % Turn warnings back on on cleanup
            function restoreFcn()
                warning on MATLAB:structOnObject;
            end
            oc = onCleanup(@()restoreFcn());

            % Check if propertyName exists within runningApp
            if isfield(runningApp, propertyName)
                value = runningApp.(propertyName);
            else
                error(message('MATLAB:appdesigner:runningappproxy:InvalidProperty'));
            end
        end

        function value = getComponentPropertyValue(obj, componentCodeName, propertyName)
            % Gets component property value in running app instance

            % Check is componentCodeName and propertyName are valid
            if(isprop(obj.RunningApp, componentCodeName) && isprop(obj.RunningApp.(componentCodeName), propertyName))
                value = obj.RunningApp.(componentCodeName).(propertyName);
            else
                error(message('MATLAB:appdesigner:runningappproxy:InvalidComponentOrProperty'));
            end
        end

        function setComponentPropertyValue(obj, componentCodeName, propertyName, value)
            % Sets component property value in running app instance
            if(isprop(obj.RunningApp, componentCodeName) && isprop(obj.RunningApp.(componentCodeName), propertyName))
                obj.RunningApp.(componentCodeName).(propertyName) = value;
            end
        end
    end

    methods(Access = {?tRunningAppProxy}, Hidden = true)
        function runningApp = getRunningApp(obj)
            runningApp = obj.RunningApp;
        end
    end
end
