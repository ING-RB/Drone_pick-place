%class Action
%           represents action metadata that can be attached to MSLException
%
%   See also: MSLException
classdef Action
    properties(Hidden=true, Access = protected)
        m_suppression
        m_fixit_suggestions
    end
    
    methods
    function value = suppression(obj)
            value = obj.m_suppression;
        end

    function value = fixit_suggestions(obj)
            value = obj.m_fixit_suggestions;
        end
    end
    
    methods
        function obj = Action(varargin)
            switch nargin
                case 0
                    return;
                case 1
                    if isa(varargin{1}, 'Diagnostic.FixItSuggestionPair')
                        obj.m_fixit_suggestions = varargin{1};
                        return;
                    end
                    if isa(varargin{1}, 'message') && isscalar(varargin{1})
                        obj.m_suppression = varargin{1};
                        return;
                    end
                case 2
                    if isa(varargin{1}, 'Diagnostic.FixItSuggestionPair') && ...
                            isa(varargin{2}, 'message') && isscalar(varargin{2})
                        obj.m_suppression = varargin{2};
                        obj.m_fixit_suggestions = varargin{1};
                        return;
                    end
                    if isa(varargin{2}, 'Diagnostic.FixItSuggestionPair') && ...
                            isa(varargin{1}, 'message') && isscalar(varargin{1})
                        obj.m_suppression = varargin{1};
                        obj.m_fixit_suggestions = varargin{2};
                        return;
                    end
                otherwise
            end
            error('don''t know how to construct DiagnosticAction');
        end
        function obj = set.m_suppression(obj, value)
            if isa(value, 'message') && isscalar(value)
                obj.m_suppression = value;
            else
                error('can''t set m_suppression property');
            end
        end
        
        function obj = setSuppression(obj, value)
            obj.m_suppression = value;
        end
        
        function obj = set.m_fixit_suggestions(obj, value)
            el = value;
            value_is_cell = false;
            if iscell(value) && (numel(value) == 1)
                el = value{1};
                value_is_cell = true;
            end
            if isa(el, 'Diagnostic.FixItSuggestionPair')
                if value_is_cell
                    obj.m_fixit_suggestions = [obj.m_fixit_suggestions el];
                else
                    obj.m_fixit_suggestions = el;
                end
            else
                error('can''t set m_suppression property');
            end
        end
        function obj = addFixIt(obj, value)
            if isa(value, 'message')
                fp = Diagnostic.FixItSuggestionPair(value);
                obj.m_fixit_suggestions = [obj.m_fixit_suggestions fp];
            else
                error('can''t addFixIt');
            end
        end
        function obj = addSuggestion(obj, value)
            if isa(value, 'message')
                fp = Diagnostic.FixItSuggestionPair('suggest', value);
                obj.m_fixit_suggestions = [obj.m_fixit_suggestions fp];
            else
                error('can''t addFixIt');
            end
        end
        
        function obj = addFixItPair(obj, varargin)
            fs = Diagnostic.FixItSuggestionPair(varargin{:});
          	obj.m_fixit_suggestions = [obj.m_fixit_suggestions fs];
        end

        function report = getReport(obj)
            report = slsvInternal('slsvGetActionReport' , obj);
        end
       
    end
        
    methods(Static)
        function action = fromMessage(msg)
            if ~isa(msg, 'message')
                 action = Action;
                return;
            end
            msld = MSLDiagnostic(msg);
            action = msld.action;
        end
    end

end
