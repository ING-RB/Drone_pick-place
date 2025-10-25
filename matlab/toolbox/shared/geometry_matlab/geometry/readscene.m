function mesh = readscene(filename,varargin)
    p = inputParser;
    addParameter(p,'Material',"",@(x)validateattributes(x, {'string'},{}));
    parse(p,varargin{:});
    
    filename_char = char(filename);
    lastdot_pos = strfind(filename_char, '.');
    if(isempty(lastdot_pos))
        error(message('shared_geometry_matlab:Geometry:InvalidReadFormat'));
    end
    ext = filename_char(lastdot_pos(end)+1:end);
    extlow = lower(ext);
    if(strcmp(extlow, "fbx") | strcmp(extlow,"obj") | strcmp(extlow,"dae"))
        mesh = matlabshared.internal.geometry.fbxsceneread(filename,p.Results.Material);
    elseif(strcmp(extlow, "gltf") | strcmp(extlow,"glb") )
        mesh = matlabshared.internal.geometry.readscene1(filename,p.Results.Material);
    else
        error(message('shared_geometry_matlab:Geometry:InvalidReadFormat'));
    end
end