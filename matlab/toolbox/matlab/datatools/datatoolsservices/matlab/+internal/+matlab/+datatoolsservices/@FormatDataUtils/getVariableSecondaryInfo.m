% Determines the underlying type and status for a given variable. Some
% datatypes, like tall or distributed arrays, have an underlying datatype which
% is different than their class name. For example, you could have a distributed
% double array, or a tall duration array.  This function will return the
% secondary type (double or duration), as well as an associated status if
% applicable.  (Tall may be unevaluated).

% Copyright 2015-2024 The MathWorks, Inc.

function [secondaryType, secondaryStatus] = getVariableSecondaryInfo(vardata)
    secondaryType = '';
    secondaryStatus = '';
    classVal = class(vardata);
    if any(strcmp(classVal, ["distributed", "codistributed", "gpuArray", "dlarray"]))
        try
            secondaryType = underlyingType(vardata);
        catch
            % This can error in cases, such as when the distributed pool is
            % shutdown. It can just be ignored.
        end   
    elseif isa(vardata, 'timeseries')
        secondaryType = class(get(vardata, 'Data'));
    elseif isa(vardata, 'timetable')
        props = vardata.Properties;
        if isprop(props, 'Events') && ~isempty(props.Events)
            numOfEvents = height(props.Events);
            if numOfEvents > 1
                secondaryStatus = [' ' getString(message('MATLAB:timetable:UIStringDispHeaderWithNEvents', numOfEvents))];
            else
                secondaryStatus = [' ' getString(message('MATLAB:timetable:UIStringDispHeaderWithOneEvent'))];
            end
        end
    elseif isstruct(vardata)
        fcount = length(fields(vardata));
        if fcount == 0
            return;
        elseif fcount == 1
            msgString = 'MATLAB:codetools:variableeditor:StructHeaderField';
        else
            msgString = 'MATLAB:codetools:variableeditor:StructHeaderFields';
        end
        secondaryStatus = getString(message(msgString, fcount));
     elseif isa(vardata, 'tall')
        [secondaryType, secondaryStatus] = ...
        internal.matlab.datatoolsservices.FormatDataUtils.getTallData(vardata);
        if ~isempty(secondaryStatus)
            secondaryStatus = ['(' secondaryStatus ')'];
        end
    end
end
