function [motionmodel, sensors, opts] = parse(varargin)
%PARSE Parse inputs to insEKF
%   This function is for internal use only. It may be removed in the future. 

%   Copyright 2021 The MathWorks, Inc.    


%#codegen   

if nargin <1
    % No argument constructor defaults
    sensors = {insAccelerometer, insGyroscope};
    motionmodel = insMotionOrientation;
    opts = insOptions;
    return;
elseif nargin == 1 && isa(varargin{1}, 'positioning.internal.INSOptionsBase')
    % Only an insOptions supplied
    sensors = {insAccelerometer, insGyroscope};
    motionmodel = insMotionOrientation;
    opts = varargin{1};
    return;
end

% Need to parse. Find the class each input, then verify form.
cls = cell(size(varargin));
coder.unroll
for ii=1:nargin
    cls{ii} = class(varargin{ii});
end
clsc = coder.const(cls);
coder.extrinsic('positioning.internal.insEKFBase.verifyAndDetermineForm');
[useMotion, foundOpts] = coder.const(@positioning.internal.insEKFBase.verifyAndDetermineForm, clsc);

if foundOpts
    opts = varargin{end};
    coder.internal.prefer_const(opts);
    if useMotion == positioning.internal.MotionModelChoices.supplied
        motionmodel = varargin{end-1};
        sensorEnd = nargin - 2;
    else
        sensorEnd = nargin - 1;
    end
else
    opts = insOptions;
    if useMotion == positioning.internal.MotionModelChoices.supplied
        motionmodel = varargin{end};
        sensorEnd = nargin -1;
    else
        sensorEnd = nargin;
    end
end

sensors = {varargin{1:sensorEnd}};
% If the motion model is not supplied, but valid, pick the right one.
if  useMotion ~= positioning.internal.MotionModelChoices.supplied
    if useMotion == positioning.internal.MotionModelChoices.orientation
        motionmodel = insMotionOrientation;
    else
        motionmodel = insMotionPose;
    end
end
end
