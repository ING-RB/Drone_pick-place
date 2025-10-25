classdef FrontEndHandler < handle
    %FRONTENDHANDLER base class for all front-end handler.
    %
    %   See also
    %
    %   This is an undocumented class. Its methods and properties are likely to
    %   change without warning from one release to the next.
    
    %   Copyright 2013-2018 The MathWorks, Inc.
    
    methods
        %% Public Method: afterPreprocessing ------------------------------
        %  Abstract:
        %    Method called just after preprocessing finished:
        %
        %        obj.afterPreprocessing(ilPtr, opts, fName, msgs)
        %
        %    where:
        %
        %        ilPtr: structure containing the pointer to the EDG IL header
        %         opts: options passed to the front-end
        %        fName: name of the file
        %         msgs: structure containing the warning/remarks collected
        %
        function afterPreprocessing(~, ~, ~, ~, ~)
        end
        
        %% Public Method: afterParsing ------------------------------------
        %  Abstract:
        %    Method called just after parsing finished:
        %
        %        obj.afterParsing(ilPtr, opts, fName, msgs)
        %
        %    where:
        %
        %        ilPtr: structure containing the pointer to the EDG IL header
        %         opts: options passed to the front-end
        %        fName: name of the file
        %         msgs: structure containing the warning/remarks collected
        %      
        function afterParsing(~, ~, ~, ~, ~)
        end
    end
end

% LocalWords:  il EDG Preprocessing preprocessing
