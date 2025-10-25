function c = copy(filt)
%COPY Deep copy of the filter
%   COPY(FILT) returns a deep copy of the filter and the associated motion
%   and sensor models.
%
%   Example: 
%       filt = insEKF;
%       filt2 = copy(filt);
%
%   See also : insEKF

%   Copyright 2022 The MathWorks, Inc.    
    
%#codegen 

scopy = cell(size(filt.Sensors));
coder.unroll
for ii=1:numel(filt.Sensors)
    scopy{ii} = copy(filt.Sensors{ii});
end

mmcopy = copy(filt.MotionModel);

optcopy = coder.const(positioning.internal.INSOptionsBase.makeConst(...
    filt.Options));

c = insEKF(scopy{:}, mmcopy, optcopy);

% Copy properties
c.State = filt.State;
c.StateCovariance = filt.StateCovariance;
c.AdditiveProcessNoise = filt.AdditiveProcessNoise;
