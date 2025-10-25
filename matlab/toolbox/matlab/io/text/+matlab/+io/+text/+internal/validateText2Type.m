function [args, fmt] = validateText2Type(fcn,validTypes,args)
%VALIDATETEXT2TYPE 

% Copyright 2021-2022 The MathWorks, Inc.

[args{1:2:end-1}] = convertCharsToStrings(args{1:2:end-1});
names = [args{1:2:end-1}];
fmt = validTypes(1);
if numel(names) > 0
    disallowed = ["FileType","Encoding","WriteMode"];
    badParams = matches(disallowed,names(:),"IgnoreCase",true);
    if any(badParams)
        error(message("MATLAB:io:common:text:ParamNotSupported",disallowed(find(badParams,1)),fcn))
    end

    id = 2*find(strlength(names) > 0 ...
        & arrayfun(@(c)startsWith("TextFormat",c,"IgnoreCase",true),names))-1;

    if ~isempty(id)
        try
            fmt = validatestring(args{id(end)+1}, validTypes, '', '"TextFormat"');
            args(id + (0:1)) = [];
        catch ME
            throwAsCaller(ME);
        end
    end
end
end

