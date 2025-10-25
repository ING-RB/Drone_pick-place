function success = helpwin(topic, varargin)
    %helpwin MATLAB file help displayed in a window
    %   MATLAB.INTERNAL.HELP.HELPWIN.HELPWIN TOPIC displays the help text
    %   for the specified TOPIC inside a window.  Links are created to
    %   functions referenced in the 'See Also' line of the help text.
    %
    %   HELPWIN displays the default topic list in a window.
    %
    %   HELPWIN will be removed in a future release. Use DOC instead. 
    %
    %   See also HELP, DOC.
    
    %   Copyright 2020-2021 The MathWorks, Inc.
    
    if nargout
        success = true;
    end
    
   
    % This function provides for one case.
    % HELPWIN TOPIC, to display function or topic help (same as HELP function).
    
    [topic, helpCommandOption] = examineInputs(topic, varargin);
    
    if isempty(topic)
        doc;
        return;
    end
    
    % Make sure we'll be able to find help for the topic.
    % The doc command will fallback to docsearch. If helpwin was NOT called 
    % from the doc command, we do want the round to the browser and back so 
    % that we can format the 'no help found' message in the helpwin content.
    if ~strcmp(helpCommandOption,char('helpwin')) && ~matlab.internal.help.helpwin.isHelpAvailable(topic, helpCommandOption)
        if nargout
            success = false;
        end
        return;
    end
    
    docPage = matlab.internal.help.helpwin.helpwinDocPage(topic, helpCommandOption);
    
    % Use the appropriate viewer, based on the DocPage content type.    
    launcher = matlab.internal.doc.ui.DocPageLauncher.getLauncherForDocPage(docPage);
    launcher.openDocPage();
end

%------------------------------------------
% Helper function to parse the input arguments.
function [topic, helpCommandOption] = examineInputs(topic, originalInputs)
    % Init parameters.
    helpCommandOption = 'helpwin';    
    
    if iscell(topic)
        if (size(topic,1) > 1)
            error(message('MATLAB:helpwin:TopicMustBeScalar'));
        else
            topic = char(topic);
        end
    end 
    
    if isstring(topic)
        topic = char(topic);
    end
    
    if ~isempty(topic)
        topic = strtrim(topic);
    end
        
    i = 1;
    while i <= length(originalInputs)  
        switch char(originalInputs{i})
            case 'helpCommandOption' 
                i = i + 1;
                if i <= length(originalInputs)
                    helpCommandOption = char(originalInputs{i});
                end
        end        
        i = i + 1;
    end
end
