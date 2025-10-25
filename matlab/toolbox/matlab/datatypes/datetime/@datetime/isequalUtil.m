function [args,prototype] = isequalUtil(args)
%

%ISEQUALUTIL Convert datetimes into doubledouble values that can be compared directly with isequal.
%   ARGS = ISEQUALUTIL(ARGS) converts datetimes in cell array ARGS into
%   corresponding doubledouble values.
%
%   [ARGS,PROTOTYPE] = ISEQUALUTIL(ARGS) returns a PROTOTYPE datetime,
%   which has the same metadata properties as the first datetime object in
%   ARGS.

%   Copyright 2014-2024 The MathWorks, Inc.
import matlab.internal.datatypes.isText

try
    
    arg = args{1};
    if isa(arg,'datetime')
        % Strings will be converted to be "like" the first datetime.
        prototype = arg;
    else
        % Find the first "real" datetime as a prototype for converting strings.
        prototype = args{find(cellfun(@(x)isa(x,'datetime'),args),1,'first')};
    end
    unzoned = isempty(prototype.tz);
    leapSecs = (prototype.tz == datetime.UTCLeapSecsZoneID);

    for i = 1:length(args)
        arg = args{i};
        if isa(arg,'datetime')
            checkCompatibleTZ(arg.tz,unzoned,leapSecs);
        elseif isText(arg)
            arg = autoConvertStrings(arg,prototype,isstring(arg)); % use first datetime array as a prototype
            if isa(arg,'duration')
                error(message('MATLAB:datetime:InvalidComparison',class(arg),'datetime'));
            end
        elseif isa(arg, 'missing')
            arg = struct('data', nan(size(arg)));
        elseif isequal(arg,[])
            continue % leave the data as just []
        else
            error(message('MATLAB:datetime:InvalidComparison',class(arg),'datetime'));
        end
        args{i} = arg.data;
    end

catch ME
    throwAsCaller(ME);
end
