%EXTRACTTIMETABLE Extracts timetable from a Simulink.SimulationData.Dataset
% or a Simulink.SimulationData.Signal.
%   TT = EXTRACTTIMETABLE(DS) Extracts the timetable TT containing the
%   timeseries and timetable data from all signals found in the
%   Simulink.SimulationData.Dataset DS or a single
%   Simulink.SimulationDataset S. If the data in the signals are
%   differently sized or have different sample times/timesteps, the
%   synchronized union padded with missing values will be returned in a
%   single timetable TT.
%
%   TT = EXTRACTTIMETABLE(DS, Name, Value) specifies additional parameters
%   using one or more name-value pair arguments.
%
%   Name-Value Pairs to specify TimeSeries and Name-Value Pairs to specify
%   Timetables may be used together to extract data from both timeseries
%   data and timetable data contained in the input respectively.
%
%   Name-Value Pairs for all Simulink.SimulationData.Dataset or Simulink.SimulationData.Signal inputs:
%   --------------------------------------------------------------------------------------------------
%
%   "OutputFormat"         - The datatype and grouping of the output.
%                            - "timetable" (default): The output will be a
%                              timetable containing the synchronized union of
%                              all signal data padded with missing values.
%                            - "cell-by-signal": The output will be a cell
%                              array containing a single-variable timetable
%                              for each timeseries or timetable
%                              found in the input.
%                            - "cell-by-sampletime" or "cell-by-timestep":
%                              The output will be a cell
%                              array containing one timetable per sample
%                              time found in the input.
%
%   "SignalNames"          - Specify the names of the signals or dataset elements to be
%                            extracted into a timetable as a character vector,
%                            string array, or cell array of character vectors
%                            or a <a href="matlab: help pattern">pattern</a>.
%                          - SignalNames may be combined with all other
%                            methods of specifying data to be extracted.
%
%   "Template"             - Extracts the timetable containing data from all
%                            the signals with the same time properties as
%                            the provided template which may be a:
%                               * timeseries
%                               * timetable
%                               * Simulink.SimulationData.Signal
%                               * Name of a Signal in DS.
%                          - Template may not be combined with other
%                            methods of specifying TimeSeries or Timetables
%                            contained in the input.
%
%
%   Name-Value Pairs to specify TimeSeries contained in Input:
%   ----------------------------------------------------------------------------------------------------
%
%   "SampleTime"           - Extracts the timetable containing data from all
%                            timeseries objects in the input with the
%                            specified sample time. If multiple sample
%                            times are provided in a vector, then the
%                            output will be a synchronized timetable,
%                            unless an 'OutputFormat' is provided.
%                            The sample time must be specified as positive
%                            numeric values.
%
%   "TimeVector"           - Extracts the timetable containing data from all
%                            the timeseries objects in the input with the
%                            time vector matching the provided time vector.
%                            "TimeVector" must be specified as a double
%                            vector.
%
%
%   Name-Value Pairs to specify Timetables contained in Input:
%   ----------------------------------------------------------------------------------------------------
%
%   "SampleRate"           - Extracts the timetable containing data from all
%                            timetables in the input with the specified
%                            sample rate. If multiple sample rates are
%                            provided in a vector, then the output will be
%                            a synchronized timetable, unless an
%                            'OutputFormat' is provided. The sample rate
%                            must be specified in Hz.
%
%   "TimeStep"             - Extracts the timetable containing data from all
%                            timetables in the input with the specified
%                            time step. If multiple time steps are provided
%                            in a vector, then the output will be a
%                            synchronized timetable, unless an
%                            'OutputFormat' is provided. The time step must
%                            be duration values.
%
%   "RowTimes"             - Extracts the timetable containing data from all
%                            the timetables contained in the input with the
%                            RowTimes matching the provided datetime or
%                            duration vector.
%
%   "StartTime"            - Extracts the timetable containing data from
%                            all the timetables contained in the
%                            input with a matching StartTime. The start time
%                            must be a scalar datetime or duration value.
%                          - StartTime may be combined with either
%                            SampleRate or TimeStep. The extracted
%                            timetable will contain data from all the
%                            timetables contained in the input with both a
%                            matching StartTime value and a matching
%                            TimeStep/SampleRate.
%
%
%   See also TIMETABLE, TIMESERIES2TIMETABLE

%   Copyright 2021 The MathWorks, Inc.