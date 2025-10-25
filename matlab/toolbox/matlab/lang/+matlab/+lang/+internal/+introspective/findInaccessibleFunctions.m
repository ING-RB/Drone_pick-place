function inaccessibleMessage = findInaccessibleFunctions(funcName)
    
    % Copyright 2018-2024 The MathWorks, Inc.

    inaccessibleMessage = message.empty;
    try        
        lines = [];
        messageID = "";
        
        disabled = matlab.internal.addons.findDisabledAddons(funcName);
        if ~isempty(disabled)
            callback = 'matlab.internal.addons.enableDisabledAddOn';
            if isscalar(disabled)
                messageID = 'matlab_addons:enableDisableManagement:FunctionInSingleDisabledAddon';

                % Create line with link text to be appended to the message
                disabledMessageLinkText = message('matlab_addons:enableDisableManagement:FunctionInSingleDisabledAddonLinkText', disabled.name, disabled.version).getString;
                lines = string(message('matlab_addons:enableDisableManagement:FunctionInSingleDisabledAddonMsgSuffix', disabled.name, disabled.version, string(genLinks(callback, disabledMessageLinkText, disabled.addonUID, disabled.addonName))).getString);
            else                
                messageID = 'matlab_addons:enableDisableManagement:FunctionInMultipleDisabledAddons';
                % Create line with link text to be appended to the message
                lines = arrayfun(@(func)generateAddOnInfoWithLink(callback, func.name, func.version, func.addonUID, func.addonName ), disabled);
            end
        end

        examples = matlab.internal.examples.findExamples(funcName);
        if ~isempty(examples)
            if messageID ~= ""
                messageID = 'MATLAB:ErrorRecovery:UnlicensedFunctionInMultipleProducts';
            elseif isscalar(examples)
                messageID = 'MATLAB:examples:FunctionInSingleExample';
            else
                messageID = 'MATLAB:examples:FunctionInMultipleExamples';
            end
            callBack = 'matlab.internal.examples.openExample';
            lines = [lines; arrayfun(@(example)genLinks(callBack, example.exampleTitle, example.exampleId), examples)];
        end
        
        if ~isempty(lines)
            inaccessibleMessage = matlab.lang.internal.introspective.createInaccessibleMessage(messageID, funcName, lines);
        end
    catch
    end
end

function productLink = genLinks(callBack, displayName, varargin)
    productLink = matlab.lang.internal.introspective.generateErrorRecoveryLine(callBack, displayName, varargin{:});
end

% Get message with link text for each add-on
function addOnInfoWithLink = generateAddOnInfoWithLink(callback, name, addOnVersion, addonUID, addonName)                
    disabledMessageLinkText = message('matlab_addons:enableDisableManagement:FunctionInMultipleDisabledAddonsLinkText').getString;
    addOnInfoWithLink = string(message('matlab_addons:enableDisableManagement:FunctionInMultipleDisabledAddonsMsgSuffix', name, addOnVersion, genLinks(callback, disabledMessageLinkText, addonUID, addonName)).getString);
end
