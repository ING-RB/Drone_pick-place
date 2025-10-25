function DateNumber = x2mdate(ExcelDateNumber, Convention, outType)
%X2MDATE Excel Serial Date Number Form to MATLAB Serial Date Number or DateTime Form
%   X2MDATE is not recommended. Call datetime(ExcelDateNumber,"ConvertFrom","excel")
%   instead.
%
%   DateNumber = x2mdate(ExcelDateNumber, Convention)
%
%   DateNumber = x2mdate(ExcelDateNumber, Convention, outType)
%
%   Summary: This function converts serial date numbers from the Excel
%      serial date number format to the MATLAB serial date number format.
%
%   Inputs: ExcelDateNumber - Array of serial date numbers in Excel serial
%              date number form.
%
%           Convention - Scalar or an array of flags indicating which date
%              convention was used in Excel to convert the date strings to
%              serial date numbers; possible values are:
%                 a) 0 : 1900 date system in which a serial date number of
%                        one corresponds to the date 1-Jan-1900 {default}.
%                 b) 1 : 1904 date system in which a serial date number of
%                        zero corresponds to the date 1-Jan-1904.
%              Convention must be either a scalar or else must be the same
%                 size as ExcelDateNumber.
%
%           outType - (Optional) String which, if specified, determines the
%                      format of the output. If outType is 'datenum', then 
%                      output date is a serial date number. However if outType 
%                      is 'datetime', then the output date is in datetime
%                      format.
%                       
%
%   Outputs: Array of dates in MATLAB serial date number or datetime form.
%
%   Example: StartDate = 35746
%            Convention = 0;
%
%            EndDate = x2mdate(StartDate, Convention);
%
%            returns:
%
%            EndDate = 729706
%
%   See also M2XDATE.

%   Copyright 1995-2021 The MathWorks, Inc.

% Return empty if empty date input
if nargin > 2
    outType = convertStringsToChars(outType);
end

if isempty(ExcelDateNumber)
    DateNumber = ExcelDateNumber;
    return
end

% Excel date number must be numeric.
if ~all(isnumeric(ExcelDateNumber(:)))
    error(message('MATLAB:x2mdate:nonNumericInput'));
end

% Check the number of arguments in and set defaults
if nargin < 2 || isempty(Convention)
    Convention = zeros(size(ExcelDateNumber));
end

if nargin <3 || isempty(outType)
    outType = 'datenum';
end

% Make sure input date numbers are positive
if any(ExcelDateNumber(:) <= 0)
    error(message('MATLAB:x2mdate:invalidInputs'));
end

% Do any needed scalar expansion on the convention flag and parse
if isscalar(Convention)
    Convention = Convention * ones(size(ExcelDateNumber));
elseif ~isequal(size(Convention),size(ExcelDateNumber))
    error(message('MATLAB:x2mdate:invalidConventionFlagSize'))
end

invalidConvention = (Convention ~= 0 & Convention ~= 1);
if any(invalidConvention(:))
    error(message('MATLAB:x2mdate:invalidConventionFlag'));
end

switch outType
    case 'datenum'
        DateTimeFlag = false;
    case 'datetime'
        DateTimeFlag = true;
    otherwise
        error(message('MATLAB:x2mdate:invalidOutputType'));
end

% Initialize all as NaN.  NaN dates should fall through as NaNs.
origSize = size(ExcelDateNumber);
DateNumber = nan(origSize);

% Set conversion factor for both (1900 & 1904) date systems
X2MATLAB1900 = 693961;
X2MATLAB1904 = 695422;

% Convert to the MATLAB serial date number
actual1900Idx = (Convention == 0 & ExcelDateNumber < 61);
if any(actual1900Idx(:))
    DateNumber(actual1900Idx) = ExcelDateNumber(actual1900Idx) + X2MATLAB1900;
end

% Excel erroneously believes 1900 was a leap year, so after February 28,
% 1900, we adjust to account for this.
corrected1900Idx = (Convention == 0 & ExcelDateNumber >= 61);
if any(corrected1900Idx(:))
    DateNumber(corrected1900Idx) = ExcelDateNumber(corrected1900Idx) + X2MATLAB1900 - 1;
end

% Using the 1904 convention there is no issue with the incorrect leap year.
y1904Idx = (Convention == 1);
if any(y1904Idx(:))
    DateNumber(y1904Idx) = ExcelDateNumber(y1904Idx) + X2MATLAB1904;
end

if DateTimeFlag
    DateNumber = matlab.datetime.compatibility.convertDatenum(DateNumber);
end

