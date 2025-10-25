function outputString = formattedDisplayText(ary, nvPairs)
%formattedDisplayText Capture output of displaying an array

% Copyright 2020-2024 The MathWorks, Inc.

   arguments
       ary
       nvPairs.NumericFormat string {mustBeScalarOrEmpty, validateNumericFormat(nvPairs.NumericFormat)} =  string.empty
       nvPairs.LineSpacing string {mustBeScalarOrEmpty, validateLineSpacing(nvPairs.LineSpacing)} = string.empty;
       nvPairs.UseTrueFalseForLogical (1,1) logical = false
       nvPairs.SuppressMarkup (1,1) logical = false
   end
   
   %% Process the inputs that are controlled by settings 
   
   % NumericFormat and LineSpacing are stored as settings.  If any of these
   % options are provided and the provided value differs from the current 
   % setting, then use the specified value.  Otherwise display will use 
   % the current (active) value.
   
   persistent cwnode;
   if isempty(cwnode)
         s = settings;
         cwnode = s.matlab.commandwindow;
   end
   
   if ~isempty(nvPairs.NumericFormat)
       currentFormat = cwnode.NumericFormat.ActiveValue;
       nvPairs.NumericFormat = cleanFormatValue(nvPairs.NumericFormat);
       if currentFormat ~= nvPairs.NumericFormat
           oc1 = updateSettingAndCreateCleanupFunction(cwnode,'NumericFormat',nvPairs.NumericFormat); %#ok<NASGU>
       end
   end
   
   if ~isempty(nvPairs.LineSpacing)
       currentSpacing = cwnode.DisplayLineSpacing.ActiveValue;
       nvPairs.LineSpacing = lower(nvPairs.LineSpacing);
       if currentSpacing ~= nvPairs.LineSpacing
           oc2 = updateSettingAndCreateCleanupFunction(cwnode,'DisplayLineSpacing',nvPairs.LineSpacing); %#ok<NASGU>
       end
   end
   
   %% If using true and false for logicals, convert to correct format
   if nvPairs.UseTrueFalseForLogical
       currentUseLogical = cwnode.UseTrueFalseForLogical.ActiveValue;
       if currentUseLogical ~= nvPairs.UseTrueFalseForLogical
           oc3 = updateSettingAndCreateCleanupFunction(cwnode, 'UseTrueFalseForLogical',nvPairs.UseTrueFalseForLogical); %#ok<NASGU>
       end
       if isa(ary, "logical")
           ary = matlab.display.internal.Logical(ary); %#ok<NASGU>
       end
   end
   
   %% Display the array
   
   % evalc has its own context for feature values.  If SuppressMarkup is true,
   % turn off the hotlinks flag inside the evalc call.  Changing the hotlinks
   % flag inside the context of evalc only impacts the evalc context, so we 
   % don't have to worry about the current value.  
   %
   % Turning off hotlinks tells display code not to inject hyperlinks and 
   % markup, but this does not disable the command window's ability to 
   % display markup and hyperlinks.  It is therefore possible that some 
   % hyperlinks will still be shown, for example if they appear in data.
   
   
   if nvPairs.SuppressMarkup
       outputString = string(evalc('feature(''hotlinks'', ''off'');disp(ary)'));
   else
       outputString = string(evalc('disp(ary)'));
   end
   
   %% If format is loose, strip off last newline
   if cwnode.DisplayLineSpacing.ActiveValue == "loose"
       tmp = char(outputString);
       outputString = string(tmp(1:end-1));
   end
   
end  %[formattedDisplayText]

%% Validation Functions
function validateNumericFormat(str)
% Validate that the numeric display format is valid
   if ~isempty(str)
       % Format argument is case-insensitive, but cannot have spaces
       mustBeMember(lower(str), [...
           "short", ...
           "long", ...
           "shorte", ...
           "longe", ...
           "shortg", ...
           "longg", ...
           "shorteng", ...
           "longeng", ...
           "+", ...
           "bank", ...
           "hex", ...
           "rational"]);
   end
end

function validateLineSpacing(str)
% Make sure that the line spacing option is valid.  
    if ~isempty(str)
        mustBeMember(lower(str),["loose","compact"]);
    end
end
        
%% Ensure that the state of the settings tree is property restored

function oc = updateSettingAndCreateCleanupFunction(cwnode, settingName, requestedValue)
 % The function obtains the active value for the setting specified by
 % settingName and creates the correct cleanup function depending on whether
 % the active value comes from the Temporary level or not. It then updates
 % the Temporary level in the settings tree with the specified value  
 % provided by the caller.
 %
 % NOTE that this function makes two assumptions:
 %    1.  The caller has explicitly provided a value for this setting, and
 %    2.  The specified value differs from the current active value.
 
    settingnode = cwnode.(settingName);
    currentValue = settingnode.ActiveValue;
    
    if hasTemporaryValue(settingnode)
        oc = onCleanup(@()resetTemporaryValue(settingnode, currentValue));
    else
        oc = onCleanup(@()clearTemporaryValue(settingnode));
    end
    settingnode.TemporaryValue  = requestedValue;
end

function resetTemporaryValue(node, originalValue)
    node.TemporaryValue = originalValue;
end



%% Clean the format value so it can be assigned into the settings tree

function cleanedFormat = cleanFormatValue(specifiedFormat)
    cleanedFormat = lower(specifiedFormat);
    switch cleanedFormat
        case "shorte"
            cleanedFormat = "shortE";
        case "longe"
            cleanedFormat = "longE";
        case "shortg"
            cleanedFormat = "shortG";
        case "longg"
            cleanedFormat = "longG";
        case "shorteng"
            cleanedFormat = "shortEng";
        case "longeng"
            cleanedFormat = "longEng";
    end
end

