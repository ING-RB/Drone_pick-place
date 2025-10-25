classdef qe_MessageClient < rptgen.internal.gui.GenerationMessageClient
    %qe_MessageClient Allow tests to access the report generation message stream
    %   Defines a message client used by tests to capture report generation messages.
    
    % Copyright 2020 The MathWorks, Inc.

    
    properties (Access=private)
        FilterLevel double = 2
        
        CurrDoc  {rptgen.internal.validator. ...
            mustBeObjectOrEmpty(CurrDoc, ...
            'matlab.io.xml.dom.Element')} = []
        
        ErrorCount double = 0
        WarningCount double = 0
        MessageContext string = ""
        LastError string = ""
    end
    
    methods
        function obj = qe_MessageClient(varargin)
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here
            if nargin > 0
                obj.CurrDoc = varargin{1};
            end
        end
        
        function clearMessages(obj)
            obj.ErrorCount = 0;
            obj.WarningCount =0;
            obj.LastError = "";
        end
        
        function setMessageContext(obj,mContext)
            obj.MessageContext = mContext;
        end
        
        function addMessage(obj,message,priority)
            
            if priority == 1
                obj.ErrorCount = obj.ErrorCount+1;
                obj.LastError = message;
            elseif priority == 2
                obj.WarningCount = obj.WarningCount+1;
            end
            
            if priority <= obj.FilterLevel
                disp("qe> " + message);
                if ~isempty(obj.CurrDoc)
                    fpNode = createElement(obj.CurrDoc,"formalpara");
                    tNode  = createElement(obj.CurrDoc,"title");
                    appendChild(tNode,createTextNode(obj.CurrDoc,"(Status " + num2str(priority) + ")"));
                    pNode  = createElement(obj.CurrDoc,"para");
                    if ~isempty(obj.MessageContext) && strlength(obj.MessageContext) > 0
                        appendChild(pNode,createTextNode(obj.CurrDoc," [ " + obj.MessageContext + " ] "));
                    end
                    appendChild(pNode,createTextNode(obj.CurrDoc,message));
                    appendChild(fpNode,tNode);
                    appendChild(fpNode,pNode);
                    appendChild(getDocumentElement(obj.CurrDoc),fpNode);
                end
            end
        end
        
        function setPriorityFilter(obj,priority)
            obj.FilterLevel = priority;
        end
        
        function priority = getPriorityFilter(obj)
            priority = obj.FilterLevel;
        end
        
        function numErrors = getNumErrors(obj)
            
            numErrors = obj.ErrorCount;
        end
        
        function error = getLastError(obj)
            error = obj.LastError;
        end
        
        function warningCount = getNumWarnings(obj)
            warningCount = obj.WarningCount;
        end

        function enableFilterList(obj) %#ok<MANU>
        end

        function disableFilterList(obj) %#ok<MANU>
        end
        
    end
end

