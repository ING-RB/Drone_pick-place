function [state, statecov, imd] = fuseTimetable(filt, params, sensorData)
%   This function is for internal use only. It may be removed in the future.
%FUSETIMETABLE Fuses sensor data in a timetable
%   Fuse data in SENSORDATA with FILT. Measurement noise (and possibly
%   other items) are present in PARAMS structure. The filter FILT should be
%   preconfigured and ready to fuse.
%  
%   STATE is a M-by-Nstates matrix of states over time where SENSORDATA is
%   M-by-N and Nstates is NUMEL(filt.State)
%   STATECOVARIANCE is an Nstates-by-Nstates-by-M array of state covariance
%   matrices over time.
%
%   IMD is a set of intermediate variables used in smoothing.

%   Copyright 2021-2022 The MathWorks, Inc.

%#codegen 


    [numdata, numsensors] = size(sensorData);             
    Nstates = numel(filt.State);
    state = zeros(numdata,Nstates, 'like', filt.State);
    statecov = zeros(Nstates,Nstates,numdata);
    dt = seconds(diff(sensorData.Properties.RowTimes));

    % Setup sensor indices
    vnames = sensorData.Properties.VariableNames;
    snames = filt.SensorNames;
    idx = positioning.internal.memberindex(vnames, snames);
   
    % Save intermediates if smoothing
    saveIntermediates = nargout > 2;

    % Initialize
    if saveIntermediates
        imd.state = state;
        imd.statecov = statecov;
    else
        imd = [];
    end
    
    % Setup measurement noises
    mnoise = cell(1,numsensors);
    
    % The datatype of sensorData is (possibly) repackaged as a cell array
    % depending on mode : sim/codegen. Both cell arrays and timetables use
    % the same indexing {} so the code below this if-else is polymorphic
    % with respect to sensorDataRepackaged.
    if coder.target('MATLAB')
        % In sim, indexing a cell array is faster. Convert to a cell array
        % to use in the loop below.
        sensorDataRepackaged = table2cell(sensorData);
    else
        % In codegen, table2cell generates a lot of code. Codegen is faster
        % if we keep it as a table.
        sensorDataRepackaged = sensorData;
    end

    for ii=1:numsensors
        name = vnames{ii};
        mnoise{ii} = params.(name + "Noise");
    end
    for ii=1:numdata
        if ii ~=1
            predict(filt, dt(ii-1));
        end
        if saveIntermediates
            imd.state(ii,:) = filt.State;
            imd.statecov(:,:,ii) = filt.StateCovariance;
        end

        for s=1:numsensors
            data = sensorDataRepackaged{ii,s}; % polymorphic sim/codegen
            if ~any(isnan(data))
                fuse(filt, filt.Sensors{idx(s)}, data, mnoise{s});
            end
        end
        state(ii,:) = filt.State;
        statecov(:,:,ii) = filt.StateCovariance; 
    end
end




