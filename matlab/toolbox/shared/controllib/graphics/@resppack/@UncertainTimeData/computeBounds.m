function computeBounds(this)
%getBounds  Data update method for bounds

%   Author(s): Craig Buhr
%   Copyright 1986-2010 The MathWorks, Inc.



RespData = this.Data;

if localHasCommonTimeVector(this);   
    % assume common time vector
    AmplitudeBoundData = cat(4,RespData(1,:).Amplitude);
    this.Bounds.UpperAmplitudeBound = max(AmplitudeBoundData,[],4);
    this.Bounds.LowerAmplitudeBound = min(AmplitudeBoundData,[],4);
    this.Bounds.Time = RespData(1).Time;
else
    [UpperBound, LowerBound , Time] = localInterpolateBounds(this);
    this.Bounds.UpperAmplitudeBound = UpperBound;
    this.Bounds.LowerAmplitudeBound = LowerBound;
    this.Bounds.Time = Time;
end

function b = localHasCommonTimeVector(this)

RespData = this.Data;
b = true;
for ct = 1:length(RespData)-1
    if ~isequal(RespData(ct).Time,RespData(ct+1).Time)
        b = false;
        break
    end
end

function [UpperBound, LowerBound , Time] = localInterpolateBounds(this)

RespData = this.Data;
Time = [];
for ct = 1:length(RespData)
    Time = [Time; RespData(ct).Time(:)];
end

Time = unique(Time);
[~,Ny,Nu] = size(RespData(1,ct).Amplitude);


for ct = 1:length(RespData)
    Amplitude = zeros(length(Time),Ny,Nu);
    for ct1 = 1:Ny*Nu
    Amplitude(:,ct1) = ...
        utInterp1(RespData(1,ct).Time,RespData(1,ct).Amplitude(:,ct1),Time);
    end
    RespData(1,ct).Amplitude = Amplitude;
end    

AmplitudeBoundData = cat(4,RespData(1,:).Amplitude);
UpperBound = max(AmplitudeBoundData,[],4);
LowerBound = min(AmplitudeBoundData,[],4);
