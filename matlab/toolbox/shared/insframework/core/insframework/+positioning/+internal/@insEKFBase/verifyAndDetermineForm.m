function [useMotion, foundOpts] = verifyAndDetermineForm(cls)
%VERIFYANDDETERMINEFORM insEKF input validation
%   This function is for internal use only. It may be removed in the future. 

%   Copyright 2021 The MathWorks, Inc.    

%#codegen   


% Check for insOptions %
earlyOpts = false;
Nin = numel(cls);
for ii=1:Nin-1
    if metaIsa(cls{ii}, 'positioning.internal.INSOptionsBase')
       earlyOpts = true; 
    end
end
coder.internal.assert(~earlyOpts, 'insframework:insEKF:OneOpts');

if metaIsa(cls{end}, 'positioning.internal.INSOptionsBase')
    foundOpts = true;
    pluginsEnd = Nin - 1;
else
    foundOpts = false;
    pluginsEnd = Nin;
end
%%%%%%%%%%%%%%%%%%
% Check for motion model %
earlyMotion = false;
for ii=1:pluginsEnd-1
    if metaIsa(cls{ii}, 'positioning.INSMotionModel')
       earlyMotion = true; 
    end
end
coder.internal.assert(~earlyMotion, 'insframework:insEKF:MotionLast');
if metaIsa(cls{pluginsEnd}, 'positioning.INSMotionModel')
    foundMotion = true;
    sensorsEnd = pluginsEnd -1;
else
    foundMotion = false;
    sensorsEnd = pluginsEnd;
end
%%%%%%%%%%%%%%%%%%
% Check for sensors%
foundOthers = false;
for ii=1:sensorsEnd
    if ~metaIsa(cls{ii}, 'positioning.INSSensorModel')
        foundOthers = true;
    end
end
coder.internal.assert(~foundOthers, 'insframework:insEKF:OtherInputs');

useMotion = determineMotion(foundMotion, cls(1:sensorsEnd));

end
function useMotion = determineMotion(foundMotion, sensorInputs)
% Determine which motion model to use if foundMotion = false
if foundMotion
    useMotion = positioning.internal.MotionModelChoices.supplied;
else
    % Are all sensors TMW supplied? 
    tmwSensors = positioning.internal.tmwSuppliedSensors.fullList; 
    ours = ismember(sensorInputs, tmwSensors);
    if ~all(ours)
        error(message('insframework:insEKF:MotionModelRequired'));
    else
        % which one to choose? If only using insAccel, insGyro or insMag,
        % then use insMotionOrientation
        imuOnly = ismember(sensorInputs, positioning.internal.tmwSuppliedSensors.orientation);
        if all(imuOnly)
            useMotion = positioning.internal.MotionModelChoices.orientation;
        else
            useMotion = positioning.internal.MotionModelChoices.pose;
        end
    end
end
end


function tf = metaIsa(cname, base)
    s = [superclasses(cname); cname];
    tf = any(strcmpi(s, base));
end
