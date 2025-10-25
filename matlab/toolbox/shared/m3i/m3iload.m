% Syntax: model = m3iload(filename)
% or model = m3iload(filename, modelIn)
%     to read into the provided model instance
function model = m3iload(varargin)
    filename = varargin{1};
    xf = M3I.XmiReaderFactory;
    xr = xf.createXmiReader;
    if (nargin > 1)
       xr.setInitialModel(varargin{2});
    end
    model = xr.read(filename);
end
