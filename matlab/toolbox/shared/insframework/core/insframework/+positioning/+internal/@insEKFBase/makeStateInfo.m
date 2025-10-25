function si = makeStateInfo(motioninfo, sensorinfo, sensornames, onceStruct)
%   This function is for internal use only. It may be removed in the future.
%MAKESTATEINFO - extrinsic function to build stateinfo struct

%   Copyright 2021 The MathWorks, Inc.    

    % Once fields
    once = fieldnames(onceStruct);

    % Add motion model to the struct
    si = motioninfo;
    % Add sensors to the struct
    
    for nn = 1:numel(sensornames)
        thissensor = sensornames{nn};
        thisstateinfo = sensorinfo{nn};
        fn = fieldnames(thisstateinfo);
        for ff=1:numel(fn)
            thisfield = fn{ff};
            % If this field is in the once list, skip it. It's already been
            % included via motioninfo.
            if ~local_ismember(thisfield, once)
                thisval = thisstateinfo.(thisfield);
                si.([thissensor '_' thisfield]) = thisval;
            end
        end
    end

end


