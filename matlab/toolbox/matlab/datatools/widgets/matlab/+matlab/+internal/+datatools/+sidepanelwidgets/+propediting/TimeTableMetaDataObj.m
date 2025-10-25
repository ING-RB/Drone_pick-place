classdef TimeTableMetaDataObj <  matlab.internal.datatools.sidepanelwidgets.propediting.TableMetaDataObj
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Internal class that defines the TimeTableMetaData Object to represent
    % timetable properties for viewing and editing
    
    % Copyright 2021 The MathWorks, Inc.

    properties
        StartTime
        SampleRate
        TimeStep
    end
    
    methods

        function startTime = get.StartTime(obj)
            tableObj = evalin(obj.Workspace, obj.TableName);
            startTime = tableObj.Properties.StartTime;
        end

        function sampleRate = get.SampleRate(obj)
            tableObj = evalin(obj.Workspace, obj.TableName);
            sampleRate = tableObj.Properties.SampleRate;
        end


        function timeStep = get.TimeStep(obj)
            tableObj = evalin(obj.Workspace, obj.TableName);
            timeStep = tableObj.Properties.TimeStep;
        end

        function set.StartTime(obj, value)
           currentValue = obj.StartTime;
           currentFormat = currentValue.Format;
           if isdatetime(currentValue)
               cmd = sprintf('%s.Properties.StartTime = datetime(''%s'',''Format'', ''%s'');', obj.TableName, value, currentFormat);
           elseif isduration(currentValue)
               [~, durationConstructCmd] = internal.matlab.datatoolsservices.VariableConversionUtils.getDurationFromText(value, currentValue);
               cmd = sprintf('%s.Properties.StartTime = %s;', obj.TableName, durationConstructCmd);
           end
           evalin(obj.Workspace, cmd);
           internal.matlab.desktop.commandwindow.insertCommandIntoHistoryWithNoPrompt(cmd);
           obj.updatePropertiesCache(obj);
        end

        function set.SampleRate(obj, value)
            cmd = sprintf('%s.Properties.SampleRate = %g;', obj.TableName, value);
            evalin(obj.Workspace, cmd);
            internal.matlab.desktop.commandwindow.insertCommandIntoHistoryWithNoPrompt(cmd);
            obj.updatePropertiesCache(obj);
        end

        function set.TimeStep(obj, value)
            ts = obj.TimeStep;
            constructCmd = '';
            if isduration(ts)
                [~, constructCmd] = internal.matlab.datatoolsservices.VariableConversionUtils.getDurationFromText(value, ts);
            elseif iscalendarduration(ts)
                [~, constructCmd] = internal.matlab.datatoolsservices.VariableConversionUtils.getCalendarDurationFromText(value, ts);
            end 
            % If something went wrong, do not generate code
            if ~isempty(constructCmd)
                cmd = sprintf('%s.Properties.TimeStep = %s;', obj.TableName, constructCmd);
                evalin(obj.Workspace, cmd);
                internal.matlab.desktop.commandwindow.insertCommandIntoHistoryWithNoPrompt(cmd);
                obj.updatePropertiesCache(obj);
            end
        end
    end
end

