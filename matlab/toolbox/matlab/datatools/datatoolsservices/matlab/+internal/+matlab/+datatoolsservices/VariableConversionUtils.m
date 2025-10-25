classdef VariableConversionUtils
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Internal class use for variable conversion tools for the Data Tools
    % UIs.
    
    % Copyright 2017-2021 The MathWorks, Inc.
    
    methods(Static)
        function [d, cmd] = getDurationFromText(text, varargin)
            % Returns a duration from the given text.  This is needed
            % because duration objects do not have a constructor which
            % accepts text.
            % Also returns a char containing the command used to construct
            % the duration object.
            %
            % If no additional arguments are given, the text is assumed to
            % be in the default duration display format.
            %
            % The second argument can optionally be the display format to
            % use (as text), or a duration object, which will provide the
            % format to use.
            cmd = '';

            if nargin == 1
                % Use the default duration display format
                curFmt = duration.DefaultDisplayFormat;
            else
                if isduration(varargin{1})
                    % Use the format of the given duration
                    curFmt = varargin{1}.Format;
                else
                    % Use the format which was passed in as an argument
                    curFmt = varargin{1};
                end
            end

            % Handle missing values, does a textcompare of missing to
            % return back missing duration.
            missingChar = char(duration(missing));
            if strcmp(missingChar, text)
                d = duration(missing);
                cmd = sprintf('duration(missing)');
                return;
            end

            try
                if length(curFmt) == 1
                    % special 1 character formats
                    num = textscan(text, '%f');
                    num = num{:};
                    
                    if isempty(num)
                        error(['invalid value for format: ' curFmt]);
                    end
                    
                    if strcmp(curFmt, 'y')
                        % Take user input as number of years - convert to hours
                        % for duration constructor
                        dNum = num*365.2425*24;
                        d = duration(dNum, 0, 0, 'Format', curFmt);
                        cmd = sprintf('duration(%g, 0, 0, "Format", "%s")', dNum, curFmt);
                    elseif strcmp(curFmt, 'd')
                        % Take user input as number of days - convert to hours
                        % for duration constructor
                        dNum = num*24;
                        d = duration(dNum, 0, 0, 'Format', curFmt);
                        cmd = sprintf('duration(%g, 0, 0, "Format", "%s")', dNum, curFmt);
                    elseif strcmp(curFmt, 'h')
                        % Take user input as number of hours
                        d = duration(num, 0, 0, 'Format', curFmt);
                        cmd = sprintf('duration(%g, 0, 0, "Format", "%s")', num, curFmt);
                    elseif strcmp(curFmt, 'm')
                        % Take user input as number of minutes
                        d = duration(0, num, 0, 'Format', curFmt);
                        cmd = sprintf('duration(0, %g, 0, "Format", "%s")', num, curFmt);
                    elseif strcmp(curFmt, 's')
                        % Take user input as number of seconds
                        d = duration(0, 0, num, 'Format', curFmt);
                        cmd = sprintf('duration(0, 0, %g, "Format", "%s")', num, curFmt);
                    end
                % If format includes S, check for exact match or fractional seconds match.
                elseif strcmp(curFmt, 'dd:hh:mm:ss') || contains(curFmt, 'dd:hh:mm:ss.S')
                    % User input must include dd:hh:mm:ss
                    ddhhmmss = textscan(text, '%f:%f:%f:%f');
                    if isempty(ddhhmmss{1}) || isempty(ddhhmmss{2}) || ...
                            isempty(ddhhmmss{3}) || isempty(ddhhmmss{4})
                        error(['invalid value for format: ' curFmt]);
                    end
                    dNum1 = ddhhmmss{1}*24 + ddhhmmss{2};
                    dNum2 = ddhhmmss{3};
                    dNum3 = ddhhmmss{4};
                    d = duration(dNum1, dNum2, dNum3, 'Format', curFmt);
                    cmd = sprintf('duration(%g, %g, %g, "Format", "%s")', dNum1, dNum2, dNum3, curFmt);
                elseif strcmp(curFmt, 'hh:mm:ss') || contains(curFmt, 'hh:mm:ss.S')
                    % User input must include hh:mm:ss
                    hhmmss = textscan(text, '%f:%f:%f');
                    if isempty(hhmmss{1}) || isempty(hhmmss{2}) || isempty(hhmmss{3})
                        error(['invalid value for format: ' curFmt]);
                    end
                    d = duration(hhmmss{1}, hhmmss{2}, hhmmss{3}, 'Format', curFmt);
                    cmd = sprintf('duration(%g, %g, %g, "Format", "%s")', hhmmss{1}, hhmmss{2}, hhmmss{3}, curFmt);
                elseif strcmp(curFmt, 'mm:ss') || contains(curFmt, 'mm:ss.S')
                    % User input must include mm:ss
                    mmss = textscan(text, '%f:%f');
                    if isempty(mmss{1}) || isempty(mmss{2})
                        error(['invalid value for format: ' curFmt]);
                    end
                    d = duration(0, mmss{1}, mmss{2}, 'Format', curFmt);
                    cmd = sprintf('duration(0, %g, %g, "Format", "%s")', mmss{1}, mmss{2}, curFmt);
                elseif strcmp(curFmt, 'hh:mm')
                    % User input must include hh:mm
                    hhmm = textscan(text, '%f:%f');
                    if isempty(hhmm{1}) || isempty(hhmm{2})
                        error(['invalid value for format: ' curFmt]);
                    end   
                    d = duration(hhmm{1}, hhmm{2}, 0, 'Format', curFmt);
                    cmd = sprintf('duration(%g, %g, 0, "Format", "%s")', hhmm{1}, hhmm{2}, curFmt);
                end
            catch
                d = [];
            end
        end

        function [d, cmd] = getCalendarDurationFromText(text, cdObj)
            % Returns a calendarduration from the given text.  This is needed
            % because calendarduration objects do not have a constructor which
            % accepts text.
            % Also returns a char containing the command used to construct
            % the calendarduration object.
            %
            % If no additional arguments are given, the text is assumed to
            % be in the default duration display format.
            %
            % The second argument can optionally be the display format to
            % use (as text), or a calendarduration object, which will provide the
            % format to use.
            arguments
                text
                cdObj = [];
            end
            import internal.matlab.datatoolsservices.VariableConversionUtils;
            cmd = '';
            curFmt = calendarDuration.DefaultDisplayFormat;
            if ~isempty(cdObj)
                if iscalendarduration(cdObj)
                    % Use the format of the given duration
                    curFmt = cdObj.Format; 
                else
                    curFmt = cdObj;
                end
            end

            % Handle missing values, does a textcompare of missing to
            % return back missing duration.
            missingChar = char(calendarDuration(missing));
            if strcmp(missingChar, text)
                d = calendarDuration(missing);
                cmd = sprintf('calendarDuration(missing)');
                return;
            end
            
            try
                dParts = strsplit(text, " ");
                % mdt is mandatory, check for their values.
                year = VariableConversionUtils.getUnitFromString(dParts, "y");
                quarter = VariableConversionUtils.getUnitFromString(dParts, "q");
                month = VariableConversionUtils.getUnitFromString(dParts, "mo"); 
                day = VariableConversionUtils.getUnitFromString(dParts, "d"); 
                hour = VariableConversionUtils.getUnitFromString(dParts, "h"); 
                min = VariableConversionUtils.getUnitFromString(dParts, "m"); 
                seconds = VariableConversionUtils.getUnitFromString(dParts, "s"); 

                if any(strcmp(curFmt, ["mdt", "ymdt", "yqmdt"]))
                    if month
                        ym = string(calmonths(month));
                        ymParts = strsplit(ym, ' ');
                        year = year + VariableConversionUtils.getUnitFromString(ymParts, "y");
                        month = VariableConversionUtils.getUnitFromString(ymParts, "mo");
                    end                     
                    if strcmp(curFmt, 'yqmdt') && quarter
                        month = (quarter*3) + month;
                    end
                    if ~hour && ~min && ~seconds
                        d = calendarDuration(year, month, day, 'Format', curFmt);
                        cmd = sprintf('calendarDuration(%d, %d, %d, "Format", "%s")', year, month, day, curFmt);
                    else
                        d = calendarDuration(year, month, day, hour, min, seconds, 'Format', curFmt);
                        cmd = sprintf('calendarDuration(%d, %d, %d, %d, %d, %g, "Format", "%s")', year, month, day, hour, min, seconds, curFmt);
                    end
                end
            catch
                d = [];
            end
        end
    end

    methods(Static,Access='private')
        function m = getUnitFromString(strArray, unit)            
            match = strArray(endsWith(strArray, unit));
            if isempty(match)
                m = 0;
            else
                m = str2double(erase(match(end), unit));
            end
        end
    end
end