classdef MotionModelChoices < int8
%   This class is for internal use only. It may be removed in the future.
%MOTIONMODELCHOICES Motion model choices during parsing

%   Copyright 2021 The MathWorks, Inc.

%#codegen   


enumeration
    supplied(0)      % Customer brought their own
    orientation(1)   % use insMotionOrientation
    pose(2)          % use insMotionPose
end
end