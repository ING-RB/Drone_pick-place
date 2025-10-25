classdef HexBinaryType < matlab.io.internal.FunctionInterface
    % HEXBINARYTYPE Set ImportOptions to the appropriate Type & NumberSystem for Hex & Binary variables
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    methods (Access = {?matlab.io.internal.functions.DetectImportOptionsText,?matlab.io.internal.functions.DetectImportOptionsXML,?matlab.io.internal.functions.DetectImportOptionsHTML,?matlab.io.internal.functions.DetectImportOptionsWordDocument})
        function opts = setHexOrBinaryType(func,supplied,opts,hexMode)
            if(hexMode)
                type = "hexadecimal";
                numsys = 'hex';
            else
                type = "binary";
                numsys = 'binary';
            end
            
            types_fvo = opts.fast_var_opts.Types;
            hexBinVarIdx = find(types_fvo == type);
            numHexBinVar = length(hexBinVarIdx);
            numberSystem = repmat({numsys}, numHexBinVar, 1);
            hexBinType = 'auto';
            
            if supplied.HexType && hexMode
                hexBinType = func.HexType;
            end
            
            if supplied.BinaryType && ~hexMode
                hexBinType = func.BinaryType;
            end
            
            hexBinType = repmat({hexBinType}, numHexBinVar, 1);
            
            % sets properties in options struct without validation
            opts.fast_var_opts = opts.fast_var_opts.setVarOpts(hexBinVarIdx,...
                repmat({'NumberSystem'}, numHexBinVar, 1), numberSystem);
            opts.fast_var_opts = opts.fast_var_opts.setTypes(hexBinVarIdx, hexBinType, true);
        end
    end
end

