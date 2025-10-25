function testing = isInUxTesting( varargin )
    persistent isTesting;
    if isempty( isTesting )
        isTesting = false;
    end
    testing = isTesting;
    if nargin > 0
        isTesting = varargin{1};
    end
end