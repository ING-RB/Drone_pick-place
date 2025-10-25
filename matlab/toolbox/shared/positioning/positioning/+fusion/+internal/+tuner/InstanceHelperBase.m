classdef (Hidden, HandleCompatible) InstanceHelperBase
%INSTANCEHELPERBASE Collection of helper methods for filters which tune()

%   Copyright 2021 The MathWorks, Inc.      

%#codegen 

    methods (Static, Hidden) 
        function ttbl = coerceRowTimes(ttbl)
            % COERCEROWTIMES force the timetable to use durations, not
            % datetimes. 
            %
            % This will also coerce the row times to be explicit not
            % implicit. This has no MATLAB user visible impact but allows
            % us to only generate mex for timetables with explicit row
            % times, instead of both implicit and explicit. Implicit row times
            % come about by generating a timetable using the 'SampleTime'
            % version of the timetable constructor.
            %
            % Renames the time variable (column) to be 'Time'.
            %
            tm = ttbl.Properties.RowTimes;
            if isa(tm, 'datetime')
                ttbl.Properties.RowTimes = seconds(second(tm));
            else
                ttbl.Properties.RowTimes = tm;
            end
            % time variable is always first in the DimensionNames cell
            % array.
            ttbl.Properties.DimensionNames{1} = 'Time';
        end
        function cost = rmsStateErr(states, groundTruth, sinfo)
            % states is N-by-numstates where N is the number of samples.

            % It is guaranteed by processGroundTruth that the Orientation is stored
            % as a quaternion and that all table variables correspond to a state.
            % It is also guaranteed that the times in the groundTruth timetable are
            % aligned with the states times.
            
            % Delete the times. We know they are okay at this point.
            gtable = timetable2table(groundTruth, 'ConvertRowTimes', false);
            vars = gtable.Properties.VariableNames;
            % Fix orientation. Compact the quaternions
            if any(contains(vars, "Orientation"))
                gtable.Orientation = compact(gtable.Orientation);
            end
            garr = table2array(gtable);

            % create a subset struct of just the needed fields
            for v=1:numel(vars)
                thisvar = vars{v};
                subsi.(thisvar) = sinfo.(thisvar);
            end
            % Extract the field values into an array
            subsicell = struct2cell(subsi);
            statesidx = [subsicell{:}];

            sarr = states(:, statesidx);

            % We are doing an RMS difference between two multivariable timeseries.
            % Using the approach defined in 
            % Abbeel, et al. "Discriminative Training of Kalman Filters." Section
            % IV, equation on page 6.
            d = (garr - sarr).';
            cost = sqrt(mean(vecnorm(d).^2));
            
        end

        function validateSameTimetableTimes(sensorData, groundTruth)
            % Ensure that number of rows are the same and the sample times
            % are the same. The RowTimes are durations. Convert back to doubles using seconds().
            stimes = seconds(sensorData.Properties.RowTimes);
            gtimes = seconds(groundTruth.Properties.RowTimes);
            assert(numel(stimes) == numel(gtimes), ...
                message('shared_positioning:tuner:InputTableLength'));
            assert(~any(stimes - gtimes), ...
                message('shared_positioning:tuner:TimetableSampleTimes'));
        end

        function groundTruth = validateAndFixGroundTruthTimeTable(groundTruth, stateinfo)
            % Ensure:
            % 1. input is timetable
            % 2. Variables present are all states. No variables allowed
            % that are not states, but not all states need to be present.
            % 3. If Orientation is present, validate and convert it to a
            % quaternion.
            
            % Input is timetable
            assert(istimetable(groundTruth), ...
                message('shared_positioning:tuner:InputMustBeTimetable', ...
                'groundTruth', 4));
            assert(~isempty(groundTruth), message('shared_positioning:tuner:InputMustBeNonempty'));
 
            % Variables are states
            vn = groundTruth.Properties.VariableNames;
            sfn = fieldnames(stateinfo);  
            assert( all(matches(vn, sfn, 'IgnoreCase', false)), ...
                message('shared_positioning:tuner:ExpectedOnlyVars', ...
                strjoin(sfn,', ') ));

            % Force RowTimes to be explicit, durations and named 'Time'
            groundTruth = fusion.internal.tuner.insfilterAsync.coerceRowTimes(groundTruth);
            
            % Fix orientation
            if any(matches(vn, 'Orientation'))
                o = fusion.internal.tuner.FilterTuner.validateAndConvertOrientation(...
                    groundTruth, 'groundTruth',  'Orientation');
                groundTruth.Orientation = o;
            end
        end
        
    end
end
