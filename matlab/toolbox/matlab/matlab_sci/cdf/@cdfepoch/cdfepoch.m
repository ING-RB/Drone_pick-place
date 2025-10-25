function epochObj = cdfepoch(x)
%CDFEPOCH Construct epoch object for CDF export.
%    CDFEPOCH is not recommended. Use CDFLIB instead.
%
%    E = CDFEPOCH(DATE) constructs a cdfepoch object where DATE is a valid
%    character vector or a string (datestr) or a number (datenum)
%    representing a date.  DATE may also be a cdfepoch object.
%
%    CDFEPOCH objects should be constructed to create EPOCH data in CDF's.
%    using CDFWRITE.  Note that a CDF epoch is the number of milliseconds
%    since 1-Jan-0000 and that MATLAB datenums are the number of days
%    since 0-Jan-0000.
%
%    See also CDFWRITE, DATENUM, CDFREAD, CDFINFO.

%    Copyright 2001-2023 The MathWorks, Inc.

if nargin > 0
    x = convertStringsToChars(x);
end

if (nargin == 0)
    s.date = [];  %#ok<I18N_Dir_Date>
    epochObj = class(s, 'cdfepoch');
    return;
else
    input = x;
end

if isa(input,'cdfepoch')
    epochObj = input;
    return;
end

if iscellstr(input)
    input = char(input);
end

validateattributes(input,{'numeric','char','string'},{},'','DATE');


if ischar(input) || isstring(input)
    % If the input is a string, then you have to convert

    % Convert to MATLAB dass= "/mathworks/devel/sbs/50/ugoswami.StringAdoptionFinal.pdb/matlab/toolbox/matlab/imagesci/@cdfepochtenum.  If this bombs out, an invalid
    % datestr was passed to datenum.
    n = datenum(input);
else
    % It's numeric, so if it's a matrix, go element by element
    % and convert each and then reshape.
    n = input(:);
end

s = struct('date',num2cell((n - 1) * 24 * 3600000)');
s = s';

if isnumeric(input) && ~isempty(input)
    s = reshape(s, size(input));
end


epochObj = class(s, 'cdfepoch');


