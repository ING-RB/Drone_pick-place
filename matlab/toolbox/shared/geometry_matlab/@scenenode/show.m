function figHandle = show(MeshNode, varargin)
    p = inputParser;
    addParameter(p,'FeatureEdgeAngle',nan,@(x)validateattributes(x,{'numeric'},{'nonnegative','scalar'}));
    addParameter(p,'NormalLength',0,@(x)validateattributes(x,{'numeric'},{'nonnegative','scalar'}));
    addParameter(p,'Color',[0,0,0],@(x)validateattributes(x,{'numeric'},{'size',[1,3]}));
    addParameter(p,'SharpCorners',[]);
    addParameter(p,'ShowEdges',true,@islogical);
    parse(p,varargin{:});

    if(isempty(MeshNode))
        error('Input meshnode is empty')
    end
    figHandle = show(polymesh(MeshNode), 'FeatureEdgeAngle', p.Results.FeatureEdgeAngle, ...
        'NormalLength', p.Results.NormalLength, 'Color', p.Results.Color, ...
        'SharpCorners', p.Results.SharpCorners, 'ShowEdges', p.Results.ShowEdges);
end