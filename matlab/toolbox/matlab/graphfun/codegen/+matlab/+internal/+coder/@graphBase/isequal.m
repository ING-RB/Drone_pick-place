function tf = isequal(g1, g2, varargin)
% 

%   Copyright 2021 The MathWorks, Inc.
%#codegen

if nargin > 2
    % Deal with the (rare) case of more than two inputs by calling
    % this function again with each input separately.
    tf = isequal(g1, g2);
    ii = 1;
    while tf && ii <= nargin-2
        tf = isequal(g1, varargin{ii});
        ii = ii+1;
    end
    return;
end

% Check that both inputs are of type graph
if ~strcmp(class(g1),class(g2))
    tf = false;
    return;
end

% Check underlying
if ~isequal(g1.Underlying, g2.Underlying)
    tf = false;
    return;
end

% Check node properties
if ~isequal(g1.NodeProperties, g2.NodeProperties)
    tf = false;
    return;
end

% Check edge properties
tf = isequal(g1.EdgeProperties, g2.EdgeProperties);
end
