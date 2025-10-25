function compile(filt, motionModel, sensors, opts)
%

%   Copyright 2021-2022 The MathWorks, Inc.

coder.internal.prefer_const(opts);

%#codegen   

    % Reads properties
    %
    % Writes properties
    %   Sensors
    %   MotionModel
    %   State
    %   StateCovariance
    %   AdditiveProcessNoise
    %   StatInfo
    %   SensorStateInfo
    %   SensorNames
    %   ReferenceFrameObject
    %   AlwaysRepairQuaternion

    % Compiler related properties used for non-tunability
    %   MotionModelStateInfo
    %   SensorStateInfo
    %   NumStates
    %   SensorNames
    %   DefaultNames
    %   StateCovFullInfo - for when a full submatrix needs setting
    %   StateCovDiagInfo - for when only the diagonal needs setting
    %   StateCovDiagIndices - diagonal indices in StateCovariance

    % Note on handling of "one time" states. 
    % There are some states, like a magnetometer's GeomagneticVector, that
    % we only want to track one copy of, regardless of how many
    % magnetometers are in use. These are "once" states. They are listed by
    % the sensors via the commonstates() static method. They are listed in
    % stateinfo as if they are motion model states. But they can be
    % accessed via stateinfo(filt, mag, 'GeomagneticVector'). They do not
    % get the sensor name prepended in the full StateInfo struct.
    %
    % Once states are revealed via the processOnceStates static method. The
    % states are added to the motionmodel structinfo and then checked
    % against during numberStateStruct. The numberStateStruct is careful
    % not to re-enumerate these "once states" since they've already been
    % enumerated by the numberStateStruct call for the motion model.
    % The final makeStateInfo call just skips over the sensors' once states
    % since they area already included in the motionmodel info struct.

    % Find sensor classes. Store as const
    sensorclsc = coder.const(getSensorClasses(sensors));
  
    % Figure out which states should only be listed once across all
    % instances of a give class. Like GeomagneticVector
    coder.extrinsic('positioning.internal.insEKFBase.processOnceStates');
    optConst = coder.const(positioning.internal.INSOptionsBase.makeConst(opts));
    filt.Options = optConst; % Store for later use in reset()
    oncefields = coder.const(@positioning.internal.insEKFBase.processOnceStates, sensorclsc);

    % Make onceStruct - oncefields with their init values
    Nsensors = coder.const(@numel, sensors);
    onceStruct = struct();
    coder.unroll;
    for ii=1:Nsensors
        sensorOnce = oncefields{ii};
        coder.unroll;
        for oo = 1:numel(sensorOnce)
            fld = sensorOnce{oo};
            ss = sensors{ii}.sensorstates(opts);
            onceStruct.(fld) = ss.(fld);
        end
    end
    constOnceStateInfo = coder.const(onceStruct);
    
    % State info starting index
    stateidx = 1;

    % Setup reference frame
    if opts.ReferenceFrame == positioning.internal.ReferenceFrameChoices.NED
        filt.ReferenceFrameObject = fusion.internal.frames.NED;
    else
        filt.ReferenceFrameObject = fusion.internal.frames.ENU;
    end

    % Motion model stateinfo
    motionModelStates = (motionModel.modelstates(opts)); 

    % Check if there is an orientation quaternion being tracked. If so keep
    % it positive.
    if isfield(motionModelStates, 'Orientation') && numel(motionModelStates.Orientation) == 4
        % Likely orientation is a quaternion. 
        filt.AlwaysRepairQuaternion = true;
    else
        filt.AlwaysRepairQuaternion = false;
    end


    % Add onceStruct states to motion model struct
    motionModelStatesConst = coder.const(augmentWithOnceStates(motionModelStates, constOnceStateInfo));

    % Call numberStateStruct with an empty oncefields and modelstateinfo
    % since we don't want to exclude any once states yet.
    [modelstateinfo, stateidx] = numberStateStruct(motionModelStatesConst, stateidx, {}, struct());

    filt.MotionModelStateInfo = modelstateinfo; 

    % Sensor stateinfo
    Nsensors = coder.const(@numel, sensors);
    sensorstateinfo = cell(1,Nsensors);
    coder.unroll;
    for ii=1:Nsensors
        % Call numberStateStruct with oncefields for this sensor so they
        % are included in stateinfo but take their indices from
        % modelstateinfo
        [sensorstateinfo{ii}, stateidx] =  numberStateStruct(sensors{ii}.sensorstates(opts), stateidx, oncefields{ii}, modelstateinfo);
    end
    filt.SensorStateInfo = sensorstateinfo;
    filt.NumStates = stateidx-1;

    % If we need to someday compile the motion model, do it now, prior to adding 
    % it to the nontunable property MotionModel. For example:
    % compile(motionModel); 
    
    filt.MotionModel = motionModel;
    
    % If we need to someday compile each sensor, do it now, prior to
    % adding it to the nontunable property Sensors. For example:    
    coder.unroll;
    for s=1:Nsensors
    %    thisSensor = sensors{s};
    %    compile(thisSensor, filt);  % Someday compile sensors here.
        sensors{s}.ListIndex = s;   % Assign location in Sensors cell array
    end
    filt.Sensors = sensors; 

    % Uniquify names
    coder.extrinsic('matlab.lang.makeUniqueStrings');
     if opts.SensorNamesSource == positioning.internal.SensorNamesSourceChoices.property
         coder.internal.assert(Nsensors == numel(opts.SensorNames),  ...
            'insframework:insEKF:NumSensorAndNamesNotEqual');
         optsNames = opts.SensorNames;
         filt.SensorNames = optsNames; 
     else
        namestmp = cell(1, Nsensors);
        coder.unroll;
        for nn=1:Nsensors
            namestmp{nn} = defaultName(filt.Sensors{nn});
        end
        filt.DefaultNames = namestmp; % store in a nontunable to make const
        filt.SensorNames = coder.const(@matlab.lang.makeUniqueStrings, filt.DefaultNames); % Finalized list of names
     end

    % Make final stateinfo
    coder.extrinsic('positioning.internal.insEKFBase.makeStateInfo');
    filt.StateInfo = coder.const(@positioning.internal.insEKFBase.makeStateInfo, ...
        filt.MotionModelStateInfo, filt.SensorStateInfo, filt.SensorNames, constOnceStateInfo);


    % Make two sets of state covariance info:
    % StateCovFullInfo - for when a full submatrix needs setting
    % StateCovDiagInfo - for when only the diagonal needs setting
    
    filt.StateCovDiagIndices = diag( reshape(1:filt.NumStates^2, filt.NumStates,[]));
    
    m = reshape(1:filt.NumStates^2, filt.NumStates, []); % square matrix 1:N^2
    d = diag(m);
    scFullInfo = structfun(@(idx)d(idx), filt.StateInfo, 'UniformOutput', false);
    filt.StateCovFullInfo = scFullInfo;
    
    fn = fieldnames(filt.StateInfo);
    for ii=1:numel(fn)
        thisf = fn{ii};
        idx = filt.StateInfo.(thisf);
        scDiagInfo.(thisf) = m(idx,idx);
    end
    filt.StateCovDiagInfo = scDiagInfo;

    % Make caches for efficient state info usage.
    makeStateInfoCaches(filt, Nsensors);

    % Make state vector
    filt.State = zeros(filt.NumStates,1, opts.Datatype);
    initializeState(filt);
    initializeStateCovariance(filt);
    filt.AdditiveProcessNoise = eye(filt.NumStates, opts.Datatype);

    filt.ReferenceFrame = char(opts.ReferenceFrame);

    % If the user has not implemented a stateTransition AND not implemented
    % a stateTransitionJacobian method, we don't need to use our numeric
    % Jacobian for stateTransitionJacobian. We can just
    % stateTransitionJacobian to 0s. Figure out which of these we can
    % hot wire now. This is only useful for sensors. For motion models, the
    % user has to implement stateTransition
    coder.extrinsic('positioning.internal.isMethodImplemented');
    stateTransImpl = false(1,Nsensors);
    coder.unroll;
    for ii=1:Nsensors
        stateTransImpl(ii) = coder.const(@positioning.internal.isMethodImplemented, ...
            sensorclsc{ii}, 'stateTransition') || ...
            coder.const(@positioning.internal.isMethodImplemented, ...
            sensorclsc{ii}, 'stateTransitionJacobian');
    end
    filt.SensorImplementsStateTransition = stateTransImpl;

    hotwire = cell(1,Nsensors);
    coder.unroll;
    for ii=1:Nsensors
            si = filt.SensorStateInfo{ii};
            fn = fieldnames(si);
            z = struct;
            coder.unroll;
            for jj=1:numel(fn)
                fld = fn{jj};
                z.(fld) = zeros(numel(si.(fld)),filt.NumStates, opts.Datatype);
            end
            hotwire{ii} =z;
    end
    filt.PrecomputedStateTransitionJacobian = hotwire;

end


function makeStateInfoCaches(filt, Nsensors)
% Setup caches for stateinfo,stateparts, statecovparts. Only used in
% simulation, not codegen. These properties are accessible here because
% they are hidden
if coder.target('MATLAB')
    filt.StatesCacheWithoutHandle = dictionary(string.empty, string.empty);
    [filt.StatesCacheWithHandle{1:Nsensors}]= deal(dictionary(string.empty, string.empty));
end
end

function [infoOut, nextIdx] = numberStateStruct(infoIn, startIdx, once, mmodelInfo)
%NUMBERSTATESTRUCT - create a state info struct
%   Create a new struct infoOut with the same fields as infoIn but fields
%   having integer ordered fields starting at startIdx and ending at
%   nextIdx-1
%
%   Any field appearing in the cell array ONCE, should not be increasingly
%   indexed but instead have its indices taken from mmodelInfo
%
%   infoIn = struct('foo', [10 47], 'bar', 15.1, 'bah', 11), startIdx = 3,
%   once = {'bah'}, mmodelInfo = struct('bah', 24)
%
%   infoOut = struct('foo', [3 4], 'bar', 5, 'bah', 24) nextIdx = 6
%
idx = startIdx;
fn = fieldnames(infoIn);
if isempty(fn)
    infoOut = struct;
else   
    for nn=1:numel(fn)
        thisfield = fn{nn};
        if local_ismember(thisfield, once)
            infoOut.(thisfield) = mmodelInfo.(thisfield);
        else
            sz = numel(infoIn.(thisfield));
            infoOut.(thisfield) = idx:(idx+sz-1);
            idx = idx + sz;
        end
    end
end

nextIdx = idx;
end


function sensorcls = getSensorClasses(sensors)
% Return a cell array of the class of each element of sensors
sensorcls = cell(1,numel(sensors));
coder.unroll
for ii=1:numel(sensors)
    sensorcls{ii} = class(sensors{ii});
end
end

function motionModelStates = augmentWithOnceStates(motionModelStates, onceStates)
% Augment the motionModelStates struct with the fields in onceStates
ofields = fieldnames(onceStates);
for ff=1:numel(ofields)
    motionModelStates.(ofields{ff}) = onceStates.(ofields{ff});
end
end
