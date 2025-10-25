function text = type2text(data, opts, args)    
%

% Copyright 2020-2022 The MathWorks, Inc.

import matlab.io.text.internal.validateText2Type;
import matlab.io.text.internal.TempTextFile;

[args,fmt] = validateText2Type(opts.ThisFcn,[opts.AllowedTypes,"auto"],args);

[args{1:2:end}] = convertCharsToStrings(args{1:2:end});
badParams = ["Encoding","FileType","WriteMode"];

names = [args{1:2:end}];
if numel(names) > 0
    len = strlength(names);
        
    hasEncoding = len > 0 & startsWith(badParams(1),names,'IgnoreCase',true);
    hasFileType = len > 0 & startsWith(badParams(2),names,'IgnoreCase',true);
    % WriteMode has competition for partial matching with WriteRowNames when
    % less than 5 characters
    hasWriteMode = len > 5 & startsWith(badParams(3),names,'IgnoreCase',true);
    
    if any(hasEncoding | hasFileType | hasWriteMode)
        badParamsName = badParams(find(any([hasEncoding' hasFileType' hasWriteMode']),1));
        error(message("MATLAB:io:common:text:ParamNotSupported",...
                badParamsName,...
                opts.ThisFcn))
    end
end

if fmt == "xml"
    encoding = "UTF-16";
else
    encoding = "UTF-8";
end

tempFileObj = TempTextFile("txt",opts.ThisFcn,encoding);

opts.WriteAsFcn(data,tempFileObj.Filename,...
    "FileType",fmt,...
    args{:},...
    "Encoding",encoding);

text = tempFileObj.getTextFromFile();
end