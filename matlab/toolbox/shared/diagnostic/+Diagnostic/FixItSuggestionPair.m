classdef FixItSuggestionPair
    properties
        fixit
        suggestion
    end
    methods
        function obj = FixItSuggestionPair(varargin)
            switch nargin
                case 0
                    return;
                case 1
                    if isa(varargin{1}, 'message') && isscalar(varargin{1})
                        obj.fixit = varargin{1};
                        return;
                    end
                case 2
                    if isa(varargin{1}, 'message') && ...
                       isa(varargin{2}, 'message')
                            if isscalar(varargin{1}) && isscalar(varargin{2})
                                obj.fixit = varargin{1};
                                obj.suggestion = varargin{2};
                                return;
                            end
                    end
                    if  (isa(varargin{1}, 'char') || isa(varargin{1}, 'string')) && ...
                        isa(varargin{2}, 'message') && isscalar(varargin{2})
                            if strcmp(varargin{1}, 'fixit')
                                obj.fixit = varargin{2};
                                return;
                            elseif strcmp(varargin{1}, 'suggest')
                                obj.suggestion = varargin{2};
                                return;
                            end
                    end
                otherwise
            end
            error('don''t know how to construct FixItSuggestionPair');
        end
    end
        
end
