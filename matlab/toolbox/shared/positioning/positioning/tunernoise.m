function measNoise = tunernoise(x)
%TUNERNOISE Noise structure exemplar for the tune function
%   TUNERNOISE(FILTCLS) produces a struct with appropriate field names to
%   be used as input to the TUNE function. The struct field values should
%   be changed to match the specific sensors in use. The input FILTCLS is a
%   filter class name.
%
%   TUNERNOISE(FILTOBJ) creates a struct based on the class of the filter
%   FILTEROBJ. FILTEROBJ is the handle to a filter class.
%
%   Example:
%       tn1 = tunernoise('insfilterAsync');
%       tn2 = tunernoise(insfilterAsync);
%
%   See also TUNERCONFIG    

%   Copyright 2020-2021 The MathWorks, Inc.    


if isStringScalar(x) || ischar(x)
    fusion.internal.tuner.validateClassName(x, 'shared_positioning:tuner:TunerNoiseClassInput');

    % If we've made it this far, then x inherits from
    % fusion.internal.tuner.FilterTuner.  Presume we can safely call static methods.
    hasMeasNoise = feval(x  + ".hasMeasNoise");
    assert(hasMeasNoise, message('shared_positioning:tuner:NoMeasNoise', x));
    measNoise = feval(x + ".getMeasNoiseExemplar");
elseif isa(x, 'fusion.internal.tuner.FilterTuner')
    % x is the object handle
    
    hasMeasNoise = x.hasMeasNoise;
    assert(hasMeasNoise, message('shared_positioning:tuner:NoMeasNoise', class(x)));
    measNoise =  x.getMeasNoiseExemplarFromInst;
else
    error(message('shared_positioning:tuner:TunerNoiseClassInput'));
end
