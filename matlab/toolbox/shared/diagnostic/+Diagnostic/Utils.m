classdef Utils
    properties(Constant, Hidden=true, Access = protected)
        m_pattern = slsvInternal('slsvGetRemoveHotLinksRegexpPattern');
        m_replace = Diagnostic.Utils.get_replace_string()
    end

    methods(Static, Hidden=true, Access = protected)
        function r = get_replace_string
            [~, r] = slsvInternal('slsvGetRemoveHotLinksRegexpPattern');
        end
    end
    methods(Static)
        function b = isInterrupt(obj)
            b = slsvInternal('IsObjectInterruptError', obj);
        end
        function s = remove_links(str)
            s = regexprep(str,Diagnostic.Utils.m_pattern,Diagnostic.Utils.m_replace);
        end
        function c = lastCallback(str)
            t = regexp(str,Diagnostic.Utils.m_pattern,'tokens');
            if isempty(t)
                c = '';
            else
                c = t{length(t)}{1};
            end
            if isequal(c,'matlab:') == 1
                c = '';
            end
        end
        function c = callbacks_from_string(str)
            t = regexp(str,Diagnostic.Utils.m_pattern,'tokens');
            c = cell(1, length(t));
            for k = 1:length(t)
                c{k} = t{k}{1};
                if isequal(c{k},'matlab:') == 1
                    c{k} = '';
                end
            end
        end
        function u = user_from_string(str)
            t = regexp(str,Diagnostic.Utils.m_pattern,'tokens');
            u = cell(1, length(t));
            for k = 1:length(t)
                u{k} = t{k}{2};
            end
        end

        %obj should be instance of either 'message' or 'MSLException' or 'MSLDiagnostic'
        function b = hasSuggestion(obj)
            b = slsvInternal('slsvTestForSuggestion',obj);
        end
        
        %obj should be instance of either 'message' or 'MSLException' or 'MSLDiagnostic'
        function b = hasSuppression(obj)
            b = slsvInternal('slsvTestForSuppression',obj);
        end
        
        %obj should be instance of either 'message' or 'MSLException' or 'MSLDiagnostic'
        function b = hasFixIt(obj)
            b = slsvInternal('slsvTestForFixIt',obj);
        end

        function validateActionInMessage(obj)
            slsvInternal('slsvValidateActionInMessage',obj);
        end

        function out_msg = createMessageForActions(callback, user_string)
            out_msg = message('SL_SERVICES:utils:EMBEDDED____ACTION____WRAPPER',...
                callback, user_string);
        end
    end
end

