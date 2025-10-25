function y = bitconcat(varargin)

%#codegen


fivarargin = cellfun(@fi, varargin, 'UniformOutput',false);
y = bitconcat(fivarargin{:});

end