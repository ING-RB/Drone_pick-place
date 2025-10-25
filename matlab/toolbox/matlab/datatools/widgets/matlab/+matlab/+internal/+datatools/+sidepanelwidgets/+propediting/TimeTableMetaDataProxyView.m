classdef TimeTableMetaDataProxyView < matlab.internal.datatools.sidepanelwidgets.propediting.TableMetaDataProxyView
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Internal class that defines the TimeTableMetaData ProxyView to represent
    % proxy view in displaying timetable properties in Property Inspector
    
    % Copyright 2021 The MathWorks, Inc.

    properties(Description = getString(message('MATLAB:datatools:widgets:datatoolsWidgets:STARTTIME')), ...
            DetailedDescription = getString(message('MATLAB:datatools:widgets:datatoolsWidgets:STARTTIME_DESC'))) %#ok<*ATUNK>
        StartTime internal.matlab.editorconverters.datatype.NonQuotedTextType;
    end

    properties(Description = getString(message('MATLAB:datatools:widgets:datatoolsWidgets:SAMPLE_RATE')), ...
            DetailedDescription = getString(message('MATLAB:datatools:widgets:datatoolsWidgets:SAMPLE_RATE_DESC'))) %#ok<*ATUNK>
        SampleRate (1,1) double;
    end

    properties(Description = getString(message('MATLAB:datatools:widgets:datatoolsWidgets:TIME_STEP')), ...
            DetailedDescription = getString(message('MATLAB:datatools:widgets:datatoolsWidgets:TIME_STEP_DESC'))) %#ok<*ATUNK>
        TimeStep internal.matlab.editorconverters.datatype.NonQuotedTextType;
    end

    methods
       
        function this = TimeTableMetaDataProxyView(tableMetaDataObj)
            this@matlab.internal.datatools.sidepanelwidgets.propediting.TableMetaDataProxyView(tableMetaDataObj);
            this.TablePropsGroup.addProperties('StartTime', 'SampleRate', 'TimeStep')
        end

        function startTime = get.StartTime(obj)
            startTime = char(obj.OriginalObjects.StartTime);
        end

        function set.StartTime(obj, value)
            if isa(value, 'internal.matlab.editorconverters.datatype.NonQuotedTextType')
                val = value.Value;
            else
                val = value;
            end
            obj.OriginalObjects.StartTime = val;
            % Set value could change the format of StartTime, notify metaDataChange to refresh this field.
            obj.notifyMetadataChange('StartTime');
        end

        function sampleRate = get.SampleRate(obj)
            sampleRate = obj.OriginalObjects.SampleRate;
        end

        function set.SampleRate(obj, value)
            obj.OriginalObjects.SampleRate = value;
            % Set value could evaluate (pi -> 3.1416), notify metaDataChange to refresh this field.
            obj.notifyMetadataChange('SampleRate');
        end

        function timeStep = get.TimeStep(obj)
            timeStep = char(obj.OriginalObjects.TimeStep);
        end

        function set.TimeStep(obj, value)
            if isa(value, 'internal.matlab.editorconverters.datatype.NonQuotedTextType')
                val = value.Value;
            else
                val = value;
            end
            obj.OriginalObjects.TimeStep = val;
            % Set value could change the format of TimeStep, notify metaDataChange to refresh this field.
            obj.notifyMetadataChange('TimeStep');
        end
       
    end
end

