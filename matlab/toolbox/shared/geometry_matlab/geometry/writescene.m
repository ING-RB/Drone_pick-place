function writescene(mesh, filename)
    filename_char = char(filename);
    lastdot_pos = strfind(filename_char, '.');
    ext = filename_char(lastdot_pos(end)+1:end);
    extlow = lower(ext);
    if(strcmp(extlow, "fbx") | strcmp(extlow,"obj") | strcmp(extlow,"dae"))
        matlabshared.internal.geometry.fbxscenewrite(mesh, filename);
    elseif(strcmp(extlow, "gltf") | strcmp(extlow,"glb") )
        matlabshared.internal.geometry.writescene1(mesh, filename);
    else
        error(message('shared_geometry_matlab:Geometry:InvalidReadFile'));
    end
end