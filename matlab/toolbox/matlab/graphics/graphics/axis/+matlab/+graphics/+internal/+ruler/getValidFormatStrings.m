function fmts = getValidFormatStrings(rulerType)
% This function is undocumented and may change in a future release.

% Function returns a cell array of valid formats for the xticklabelformat 
% function (and the y, z, theta, and r versions of that function) based on
% the type of ruler used for that axis. This helper is used by 
% graph3d/functionSignatures.json to determine formats to make available 
% for function hints.

% Copyright 2021 The MathWorks, Inc.

arguments
    rulerType (1,1) string {mustBeMember(rulerType,["numeric","datetime","duration"])}
end

switch rulerType
    case "numeric"
        % Valid formats for Numeric Ruler. This list represents the valid
        % format shortcuts for numeric ruler, though users can also specify
        % any sprintf style format string for this ruler type, e.g. '$%,.2f'
        fmts = {'usd','eur','gbp','jpy','degrees','percentage','auto'};
    case "datetime"
        % Valid formats for DatetimeRuler. This is a non-comprehensive, but
        % representative, list of common formats available for datetime
        % ruler pulled from the documentation.
        fmts = {'MM/dd/yyyy HH:mm:ss','dd-MMM-yyyy HH:mm:ss',...
                'yyyy-MM-dd HH:mm:ss','MM/dd/yyyy','dd-MMM-yyyy',...
                'yyyy-MM-dd','HH:mm:ss','dd-MMM-uuuu HH:mm:ss',...
                'dd-MMM-uuuu','auto'};
    case "duration"
        % Valid formats for DurationRuler. This is a non-comprehensive, but
        % representative, list of common formats available for duration
        % ruler pulled from the documentation. Note that 'auto' is not a 
        % valid format for duration ruler.
        fmts = {'y','d','h','m','s','dd:hh:mm:ss','hh:mm:ss','mm:ss',...
                'hh:mm','hh:mm.ss.SSS'};

end

end

