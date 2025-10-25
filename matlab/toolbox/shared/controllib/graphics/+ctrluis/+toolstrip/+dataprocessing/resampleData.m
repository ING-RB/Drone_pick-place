function y = resampleData(u,Ts,method)
%RESAMPLEDATA Resample timeseries data
%
%    y = resampleData(u,Ts,[method])
%
%    Inputs:
%      u      - timeseries to re-sample 
%      Ts     - Sampling period to use for re-sampling, must be >0 
%      method - optional flag indicating method to use when re-sampling, 
%               valid values are {'ZOH','Linear'}. If omitted the 
%               default 'ZOH' is used
%
%    Outputs:
%       y - re-sampled timeseries
%

% Copyright 2013-2014 The MathWorks, Inc.

%Parse inputs
if nargin < 3, method = 'zoh'; end
if nargin < 2 || ...
        ~isa(u,'timeseries') || ...
        ~isnumeric(Ts) || ~isscalar(Ts) || ~isreal(Ts) || Ts <=0
    error(message('Controllib:dataprocessing:errResampleData_Inputs'))
end
if ~any(strcmpi(method,{'ZOH','Linear'}))
    error(message('Controllib:dataprocessing:errResampleData_Method'))
end

%Resample data
tVec = u.TimeInfo.Start:Ts:u.TimeInfo.End;
y    = resample(u,tVec,method);
y    = setuniformtime(y,'StartTime',tVec(1),'Interval',Ts);
end