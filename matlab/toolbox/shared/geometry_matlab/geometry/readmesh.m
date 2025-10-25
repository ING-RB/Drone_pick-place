function mesh = readmesh(filename,varargin)
    % Material = "";
    % FrontAxis = "-Y";
    % UpAxis = "+Z";

    p = inputParser;
    addParameter(p,'Materials',"",@(x)validateattributes(x, {'string'},{}));
    addParameter(p,'FrontAxis',"-Y",@(x)validateattributes(x, {'string'},{}));
    addParameter(p,'UpAxis',"+Z",@(x)validateattributes(x, {'string'},{}));
    parse(p,varargin{:});
    
    filename_char = char(filename);
    lastdot_pos = strfind(filename_char, '.');
    if(isempty(lastdot_pos))
        error(message('shared_geometry_matlab:Geometry:InvalidReadFormat'));
    end
    ext = filename_char(lastdot_pos(end)+1:end);
    extlow = lower(ext);
    if(strcmp(extlow, "fbx") | strcmp(extlow,"obj") | strcmp(extlow,"dae") | strcmp(extlow,"stp") | strcmp(extlow,"step") | strcmp(extlow,"iges") | strcmp(extlow,"igs"))
        mesh = matlabshared.internal.geometry.meshRead2(filename,"Materials",p.Results.Materials, "FrontAxis", p.Results.FrontAxis, "UpAxis", p.Results.UpAxis);
    elseif(strcmp(extlow, "gltf") | strcmp(extlow,"glb") | strcmp(extlow,"stl") | strcmp(extlow,"off") )
        mesh = matlabshared.internal.geometry.meshRead1(filename,"Materials",p.Results.Materials, "FrontAxis", p.Results.FrontAxis, "UpAxis", p.Results.UpAxis);
    else
        error(message('shared_geometry_matlab:Geometry:InvalidReadFormat'));
    end
    mesh = geometry.meshClean(mesh);
end