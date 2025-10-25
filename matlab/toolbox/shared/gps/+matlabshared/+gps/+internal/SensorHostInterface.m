classdef (Hidden) SensorHostInterface < matlabshared.gps.internal.SensorConnectivityBase & matlab.mixin.CustomDisplay
%SENSORHOSTINTERFACE is the parent class for sensors connected directly to
% host

% Copyright 2020 The MathWorks, Inc.

    properties(Nontunable, AbortSet)
        % SamplesPerRead Number of samples to be read in a single 'read'
        % operation.
        SamplesPerRead = 1;
        % ReadMode Specify whether to read 'latest' or 'oldest' data from
        % the sensor.
        % 'latest' mode (default) gets the latest data from the sensor. The
        % number of samples trashed is given by 'overrun'.
        % 'oldest' mode will retain samples collected from the beginning
        % without trashing any sample.Number of data points left can be read
        % using SamplesAvailable
        ReadMode = matlabshared.gps.internal.enumTypes.ReadMode.latest;
    end

    properties(AbortSet)
        % OutputFormat Format of the 'read' function output.
        % Output data can be 'timetable' or 'matrix' format. 'timetable'
        % data format has 'Time' and the physical quantities that the sensor
        % measures as timetable fields. 'matrix' format provides separate
        % matrices for acceleration, angular velocity and magnetic field,
        % each of size N x 3, where N is the 'SamplesPerRead'. Time is
        % returned as a column matrix of size N x 1.
        OutputFormat = matlabshared.gps.internal.enumTypes.OutputFormat.timetable;
        % TimeFormat Format of the time stamps returned by the 'read'
        % function.
        % Time stamps can be 'datetime' or 'duration' format.
        TimeFormat = matlabshared.gps.internal.enumTypes.TimeFormat.datetime;
    end
    
    properties(SetAccess = protected, GetAccess = public)
        % SamplesRead Number of samples already read.
        SamplesRead = 0;
        % SamplesAvailable Number of samples waiting in the buffer to be
        % read.
        SamplesAvailable = 0;
    end

    properties(Access = protected, Hidden)
        timeTableOutput;
        connectionObj;
    end

    methods(Abstract, Access = protected)
        % Even though most of these methods are abstract in matlab.system,
        % here it is specifically given to show that these system object methods
        % are being used in this architecture
        setupImpl(obj);
        data = stepImpl(obj);
        resetImpl(obj);
        releaseImpl(obj);
        s = infoImpl(obj);
        getSamplesAvailableImpl(obj)
        createTimeTableImpl(obj)
    end

    methods(Abstract, Access = public)
        data = read(obj);
        flush(obj);
    end

    methods
        function set.SamplesPerRead(obj, value)
            validateattributes(value,{'numeric'}, ...
                               {'real','positive','scalar','integer' ...
                                '>=',1,'<=',10},'','SamplesPerRead');
            obj.SamplesPerRead = value;
            % create the timetable when SamplesPerRead is set.This property
            % determines the number of rows required.
            createTimeTableImpl(obj);
        end

        function set.ReadMode(obj, value)
            validReadMode = ["latest", "oldest"];
            obj.ReadMode = matlabshared.gps.internal.enumTypes.ReadMode(validatestring(value,validReadMode));
        end

        function set.OutputFormat(obj, value)
            validOutputFormat = ["timetable","matrix"];
            obj.OutputFormat = matlabshared.gps.internal.enumTypes.OutputFormat(validatestring(value,validOutputFormat));
        end

        function set.TimeFormat(obj, value)
            validTimeFormat = ["duration","datetime"];
            obj.TimeFormat= matlabshared.gps.internal.enumTypes.TimeFormat(validatestring(value,validTimeFormat));
        end

        function value = get.SamplesAvailable(obj)
            value = getSamplesAvailableImpl(obj);
        end
    end

    methods(Sealed, Hidden, Access = protected)
        function obj = cloneImpl(obj)  %#ok<MANU>
            try
                error(message('shared_gps:general:UnsupportedFunction','clone'));
            catch ME
                throwAsCaller(ME);
            end
        end
    end
end
