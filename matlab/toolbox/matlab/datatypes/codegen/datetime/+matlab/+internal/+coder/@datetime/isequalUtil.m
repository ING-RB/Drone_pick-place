function [processedArgs,validComparison] = isequalUtil(args) %#codegen
%ISEQUALUTIL Convert datetimes into doubledouble values that can be compared directly with isequal.
%   PROCESSEDARGS = ISEQUALUTIL(ARGS) returns a cell array of doubledouble
%   values PROCESSEDARGS corresponding to the datetimes in cell array ARGS.
%
%   [PROCESSEDARGS,VALIDCOMPARISON] = ISEQUALUTIL(ARGS) sets
%   VALIDCOMPARISON to true in any case where isequal(ARGS{:}) is a valid
%   comparison and false otherwise (e.g in instances where
%   MATLAB:datetime:InvalidComparison would be thrown in MATLAB).

%   Copyright 2019-2022 The MathWorks, Inc.

validComparison = true;
arg = args{1};
processedArgs = cell(size(args));
if isa(arg,'datetime')
    % Strings will be converted to be "like" the first datetime.
    prototype = arg;
else
    % Find the first "real" datetime as a prototype for converting strings.
    prototype = args{find(cellfun(@(x)isa(x,'datetime'),args),1,'first')};
end
unzoned = isempty(prototype.tz);
leapSecs = strcmp(prototype.tz,datetime.UTCLeapSecsZoneID);
coder.unroll()
for i = 1:length(args)
    coder.internal.errorIf(matlab.internal.coder.datatypes.isText(args{i}),'MATLAB:datetime:TextConstructionCodegen');
    if (~isa(args{i},'datetime') && ~isequal(args{i},[]))
        validComparison = false;
   
    end
    if isa(args{i},'datetime')
        validComparison = checkCompatibleTZ(args{i}.tz,unzoned,leapSecs);
    elseif isequal(args{i},[])
        processedArgs{i} = [];
        continue % leave the data as just []
    end
    if validComparison
        processedArgs{i} = args{i}.data;
    else
        processedArgs{i} = nan;
    end
end

