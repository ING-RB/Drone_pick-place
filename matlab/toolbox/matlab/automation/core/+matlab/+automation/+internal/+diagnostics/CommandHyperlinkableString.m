classdef CommandHyperlinkableString < matlab.automation.internal.diagnostics.LeafFormattableString
    %

    % Copyright 2016-2022 The MathWorks, Inc.
    
    properties (SetAccess=private)
        Text string;
    end
    
    properties (SetAccess=private)
        LinkText (1,1) string;
        CommandToExecute (1,1) string;
        BoldHandlingRequired = false;
    end
    
    methods
        function str = CommandHyperlinkableString(linkText, commandToExecute, namedargs)
            arguments
                linkText {mustBeNonzeroLengthText};
                commandToExecute;
                namedargs.PlainText (1,1) string = linkText; % Text to display in unenriched environments
            end
            
            str.LinkText = linkText;
            str.CommandToExecute = commandToExecute;
            str.Text = namedargs.PlainText;
        end
        
        function str = enrich(str)
            import matlab.automation.internal.diagnostics.CommandHyperlinkedString;            
            
            % since the command is placed inside '<a href="%s">', return as  
            % is if the command contains any '"' characters. This means
            % that the string will not be converted to a hyperlink, but will
            % be displayed as plain text.
            if contains(str.CommandToExecute,'"')
                return;
            end            
            
            str = CommandHyperlinkedString(str);
        end
    end
    
    methods (Access=protected)
        function str = applyBoldHandling(str)
            str.BoldHandlingRequired = true;
        end
    end
end

% LocalWords:  Formattable namedargs unenriched
