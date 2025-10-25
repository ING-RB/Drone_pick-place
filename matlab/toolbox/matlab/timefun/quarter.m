function q = quarter(date, month1, f)
%QUARTER Quarter of date
%   Using MATLAB serial date numbers and date strings to represent dates and times
%   is not recommended. Call QUARTER using a datetime value instead.
%
%   Q = QUARTER(DATE) returns the quarter containing the date number 
%   or date string DATE, assuming that the fiscal year starts on Jan 1.
%
%   Q = QUARTER(DATE,MONTH1) returns the quarter for the date DATE, given
%   that the fiscal year starts on the month indicated by MONTH1. MONTH1 is
%   a numeric value representing the month number (ex. 1 for Jan and 12 for
%   Dec)
%
%   Q = QUARTER(DATE,MONTH1,DATEFORMAT) returns the quarter of one or more 
%   date strings DATE using format string DATEFORMAT. DATE can be a character 
%	array where each row corresponds to one date string, or one dimensional 
%	cell array of strings.
%
%   For example, q = quarter('1/1/2015')
%
%   returns:
%
%   q = 1
%
%   q = quarter('1/1/2015', 10)
%
%   returns:
%
%   q = 2

%   Copyright 2015-2021 The MathWorks, Inc.

% Check inputs and provide defaults
if nargin > 0
    date = convertStringsToChars(date);
end

if nargin > 2
    f = convertStringsToChars(f);
end

if nargin < 1 || isempty(date)
     error(message('MATLAB:quarter:missingInputs'))
end

if nargin < 2 || isempty(month1)
    month1 = 1;
end

if nargin < 3 || isempty(f)
    f = '';
end

validateattributes(date,{'double','char','cell'},{},'quarter','Date')
validateattributes(month1,{'numeric'},{'>=',1,'<=',12},'quarter','Month1')
validateattributes(f,{'char'},{},'quarter','DateFormat')

if ~isa(date,'double')
    date = datenum(date,f);
end

% Get month of dates
[~,m] = datevec(date);

% Check dimensions and resize scalars if necessary
if ~isscalar(m) && ~isscalar(month1) 
    if any(size(m) ~= size(month1))
        error(message('MATLAB:quarter:dimensionMismatch')) ;
    end
elseif ~isscalar(month1)
   m = repmat(m,size(month1));
elseif ~isscalar(m)
  month1 = repmat(month1,size(m));
end

q = zeros(size(m));

% Calculate quarter
Ind = m >= month1;
q(Ind) = ceil((m(Ind)-month1(Ind)+1)/3);
q (~Ind) = ceil((m(~Ind)-month1(~Ind)+13)/3);

end

