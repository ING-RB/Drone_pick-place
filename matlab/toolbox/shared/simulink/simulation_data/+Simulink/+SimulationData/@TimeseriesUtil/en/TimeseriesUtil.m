classdef TimeseriesUtil
% SIMULINK.SIMULATIONDATA.TIMESERIESUTIL is a utility class used to calculate settings from a timeseries object.

 
% Copyright 2011-2024 The MathWorks, Inc.

    methods
        function out=TimeseriesUtil
        end

        function out=convertSingleColumnTimeTableToTimeSeries(~) %#ok<STOUT>
            % convert a timetable (plus the optional timetable properties) into a timeseries
            % object returns the new timeseries object as well as table
            % properties which would be needed for round trip of table data
        end

        function out=convertTimeSeriesToTimeTable(~) %#ok<STOUT>
            % convert a timeseries (plus the optional timeseries properties) into a
            % timetable. return the timetable as well as the properties of the
            % timeseries, which would be needed for a round trip workflow.
        end

        function out=getSampleDimensions(~) %#ok<STOUT>
            % Given a timeseries object, calculate the dimensions of a single
            % sample.  For external model inputs, this must match the sample
            % dimensions of the inport.
        end

        function out=locConvertTimeSeriesToTimeTable(~) %#ok<STOUT>
            % timeseries.empty converts to {}
        end

        function out=utcreateuniformwithoutcheck(~) %#ok<STOUT>
        end

        function out=utcreatewithoutcheck(~) %#ok<STOUT>
        end

    end
end
