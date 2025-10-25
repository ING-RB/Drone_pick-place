function out = text2type(text,opts,args)
%TEXT2TYPE proccess inputs for text2type functions

% Copyright 2020-2022 The MathWorks, Inc.
import matlab.io.text.internal.validateText2Type;
import matlab.io.text.internal.captureTempFileErrors;

text = convertCharsToStrings(text);
if ~isstring(text)
    error(message("MATLAB:textio:textio:InvalidStringOrCellStringProperty","TEXT"))
end

% If the second arg is import options, it's not an NV-pair, and the reader
% function changes.
usingImportOptions = false;
if numel(args)>0  && isa(args{1},"matlab.io.ImportOptions")
    usingImportOptions = true;
    opts.ReadAsFcn = opts.ReadAsFcn + "WithImportOptions";
end
firstNV = 1+usingImportOptions;

% Check for TextFormat, validate it, and remove that arg.
tempArgs = args(firstNV:end);
[tempArgs, filetype] = validateText2Type(opts.ThisFcn,[opts.AllowedTypes "auto"],tempArgs);
args = [args(usingImportOptions) tempArgs];

encoding = either(filetype == "xml","UTF-16","UTF-8");

% Get the reader function
func = matlab.io.internal.functions.FunctionStore.getFunctionByName(opts.ReadAsFcn);

matlab.io.internal.validators.validateNVPairs(args{firstNV:end});
[paramStruct,supplied] = func.parseNVPairs(args(firstNV:end));

if numel(fieldnames(paramStruct)) > 0
    checkDisallowed(supplied,opts.ThisFcn)
end

% Join the elements of the text with the custom LineEnding if supplied
lend = newline;
if ~usingImportOptions && isfield(supplied,'LineEnding') && supplied.LineEnding
    func.LineEnding = paramStruct.LineEnding; % for validation
    lend = sprintf(func.LineEnding{1});
elseif usingImportOptions && isprop(args{1},'LineEnding')
    lend = sprintf(args{1}.LineEnding{1});
end
text = join(text(:),lend);

tempFileObj = createFile(text,opts,filetype,encoding);

[func,supplied] = func.validate(tempFileObj.Filename, args{:});

if ~usingImportOptions 
    func.FileType = filetype;
    if filetype ~= "xml"
        % Not available on XML
        func.Encoding = encoding;
    end
end

out = captureTempFileErrors(@()func.execute(supplied),text);
end

%% 
function tempFileObj = createFile(text,opts,filetype,encoding)
import matlab.io.text.internal.TempTextFile;
tempFileObj = TempTextFile(opts.DefaultExt,opts.ThisFcn,encoding);

if filetype == "xml"
    % Remove UTF-16 BOM
    if startsWith(text,char(65279))
        text = strip(text,"left",char(65279));
    end
    % Add required XML header for XML snippits
    if ~startsWith(strip(text,"left"),"<?xml")
        text = "<?xml version=""1.0"" encoding=""UTF-16""?>" + newline + text;
    end
end

tempFileObj.writeTextToFile(text);
end

%%
function checkDisallowed(supplied,fcn)
    disallowed = ["Encoding","FileType","WebOptions"];
    for kk = 1:numel(disallowed)
        if isfield(supplied,disallowed(kk)) && supplied.(disallowed(kk))
            error(message("MATLAB:io:common:text:ParamNotSupported",disallowed(kk),fcn))
        end
    end
end

%%
function c = either(tf,a,b)
if tf,c = a;else,c = b;end
end