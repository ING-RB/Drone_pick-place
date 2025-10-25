%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Geometry.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef Geometry
    methods    ( Static = true )
        function [libname, libloadername] = Initialize
            if any(computer('arch') == "maca64")
                libname = "geometry_maca64";
                libloadername = "geometry_loaders_maca64";
            else
                libname = "geometry";
                libloadername = "geometry_loaders";
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    Mesh = mesh(var1,material)
            libname = Geometry.Initialize;
            % Check input variables
            switch nargin
            case 0
                Mesh = clib.(libname).MeshLib.Mesh_1;
                return;
            case 1
                material = "";
            end
            % Validate input variables
            validateattributes(material, {'string'},{});
            switch class(var1)
            case 'triangulation'
                Mesh = Geometry.triangulationToMesh(var1,material);
            case 'delaunayTriangulation'
                Mesh = Geometry.triangulationToMesh(var1,material);
            case 'cell'
                if(class(var1{1}) == "triangulation" || class(var1{1}) == "delaunayTriangulation" )
                    Mesh = Geometry.triangulationsToMesh(var1,material);
                else
                    error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'triangulation or delaunayTriangulation'))
                end
            case 'polyshape'
                T = triangulation(var1);
                Mesh = Geometry.triangulationToMesh(T,material);
            otherwise
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput2', 'Triangulation','Polyshape'))
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function Mesh = pointsToMesh(points,triangles,material)
            libname = Geometry.Initialize;
            Mesh = clib.(libname).MeshLib.Mesh_1;
            switch nargin
            case 0
                return;
            case 1
                error(message('shared_geometry_matlab:Geometry:InvalidTriangleSizeInput', 0, 0));
            case 2
                material = "";
            end

            sizeP = size(points);
            sizeT = size(triangles);
            
            validateattributes(material, {'string'},{});
            Mesh.AddMaterial(material);
            [~,c1] = size(points);
            [~,c2] = size(triangles);
            if(c1 ~= 3)
                error(message('shared_geometry_matlab:Geometry:InvalidPointsSizeInput', sizeP(1),sizeP(2)));
            end
            if(c2 ~= 3)
                error(message('shared_geometry_matlab:Geometry:InvalidTriangleSizeInput', sizeT(1),sizeT(2)));
            end
            matIndex = double(Mesh.GetMaterialIndex(material));	
            T1 = [ triangles matIndex*ones(size(triangles,1), 1)];
            T1 = reshape(T1',1,[]);
            P1 = reshape(points',1,[]);
            Mesh.AddVertexInVector(P1);
            Mesh.AddTrianglesInVector(T1);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    verbose(bool)
            libname = Geometry.Initialize;
            validateattributes(bool,{'logical'},{});
            clib.(libname).MeshLib.set_verbose(bool);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    removeVertex(Mesh,vertices)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            validateattributes(vertices,{'numeric'},{'nonnegative','integer'});
            Mesh.RemoveVertex(vertices);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    removeTriangle(Mesh,triangles)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            validateattributes(triangles,{'numeric'},{'nonnegative','integer'});
            if(isscalar(triangles))
                Mesh.RemoveTriangle(triangles);
            else
                Mesh.RemoveTriangles(triangles);
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    removeMaterial(Mesh,material)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            validateattributes(material,{'numeric','string'},{'size',[1,1]});
            Mesh.RemoveMaterial(material);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    removeAttribute(Mesh,material,attribute)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            validateattributes(material,{'numeric','string'},{'size',[1,1]});
            validateattributes(attribute,{'string'},{'size',[1,1]});
            Mesh.RemoveMaterialAttribute(material,attribute);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    flipTriangle(Mesh,triangles)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            validateattributes(triangles,{'numeric'},{'nonnegative','integer'});
            if(length(triangles) == 1)
                Mesh.FlipTriangle(triangles);
            else
                Mesh.FlipTriangles(triangles);
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    addMaterial(Mesh,material)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            validateattributes(material, {'string','cell'},{});
            if(length(material) == 1)
                Mesh.AddMaterial(material);
            else
                str = clib.array.(libname).std.String(0);
                
                for i = 1: length(material)
                    str.append(material{i});
                end
                Mesh.AddMaterials(str);
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    addAttribute(Mesh,material,attribute,value)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            validateattributes(material, {'string'},{});
            validateattributes(attribute, {'string','cell'},{});
            validateattributes(value, {'numeric','string','cell'},{});
            row = length(value);
            attrow = length(attribute);
            
            if(class(attribute) == "cell" && class(value) == "cell")
                if(attrow == 1 && row == 1)
                    if class(value{1}) == "string"
                        Mesh.SetMaterialAttribute(material,string(attribute{1}),string(value{1}));
                        return;
                    else
                        val =  clib.array.(libname).Double(0);              
                        for i =1:length(value{1})
                            val.append(value{1}(1,i));
                        end
                        Mesh.SetMaterialAttribute(material,string(attribute{1}),val)
                    end
                elseif(attrow == row)
                    for i = 1:length(attribute)
                        if class(value{i}) == "string"
                            Mesh.SetMaterialAttribute(material,string(attribute{i}),value{i});
                        else
                            val =  clib.array.(libname).Double(0);
                            for j =1:length(value{i})
                                val.append(value{i}(j));
                            end
                            Mesh.SetMaterialAttribute(material,string(attribute{i}),val)
                        end
                    end
                else
                    error("Attributs and their values should be scalar or a cell array of same size.");
                end
                
            elseif(class(attribute) == "string")
                if class(value) == "string"
                    Mesh.SetMaterialAttribute(material,attribute,string(value{1}));
                    return;
                else
                    val =  clib.array.(libname).Double(0);              
                    for i =1:length(value)
                        val.append(value(1,i));
                    end
                    Mesh.SetMaterialAttribute(material,attribute,val)
                end
            else
                error("Attributs and their values should be scalar or a cell array of same size.");
            end

        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    setAttribute(Mesh,material,attribute,value)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            validateattributes(material, {'string'},{});
            validateattributes(attribute, {'string'},{});
            validateattributes(value, {'numeric','string'},{});
            if class(value) == "string"
                Mesh.SetMaterialAttribute(material,attribute,value);
                return;
            end
            [~,col] = size(value);
            [attrow,~] = size(attribute);
            if(attrow == 1)
                val =  clib.array.(libname).Double(0);
                for i =1:col
                    val.append(value(1,i));
                end
                Mesh.SetMaterialAttribute(material,attribute,val)
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    setMaterial(Mesh,material,triangle)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            switch nargin
            case 1
                material = "";
                triangle = 0:Mesh.GetTriangleCount-1;
            case 2
                triangle = 0:Mesh.GetTriangleCount-1;
            end
            validateattributes(material, {'string'},{});
            validateattributes(triangle,{'numeric'},{'nonnegative','integer','<',Mesh.GetTriangleCount});
            if(length(material) == 1)
                Mesh.SetMaterials(material,triangle)
            end
            if(length(material) == length(triangle))
                for i = 1:length(material)
                    Mesh.SetMaterial(material(i),triangle(i));
                end
            end
            if(length(material) ~= 1 && length(material) ~= length(triangle))
                error('Invalid input')
            end
        end  
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    colors = getColorPerVertex(Mesh)
            if(Mesh.GetVertexColorCount == 0)
                error(message('shared_geometry_matlab:Geometry:InvalidColorCount'));
            end
            libname = Geometry.Initialize;
            col = clib.array.(libname).glm.dvec3(0);
            clib.(libname).MeshLib.MeshQuery.ComputeAverageColorPerVertex(col, Mesh);
            colors = zeros(col.Dimensions, 3);
            for i = 1:col.Dimensions
                colors(i,:) = clib.(libname).MeshLib.MeshQuery.glm3tovec(col(i));
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    normals = getNormalPerVertex(Mesh)
            libname = Geometry.Initialize;
            nor = clib.array.(libname).glm.dvec3(0);
            clib.(libname).MeshLib.MeshQuery.ComputeAverageNormalPerVertex(nor, Mesh);
            normals = zeros(nor.Dimensions, 3);
            for i = 1:nor.Dimensions
                normals(i,:) = clib.(libname).MeshLib.MeshQuery.glm3tovec(nor(i));
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    m = getMaterial(Mesh,material)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            switch nargin
            case 1
                m = Mesh.GetMaterials();
                return;
            end
            validateattributes(material,{'numeric','string'},{});
            m = Mesh.GetMaterial(material);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    m = getMaterialCount(Mesh)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            m = Mesh.GetMaterialCount();
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    m = getMaterialIndex(Mesh,material)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            validateattributes(material,{'string'},{});
            m = Mesh.GetMaterialIndex(material);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    m = getAttributes(Mesh,material)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            validateattributes(material,{'string'},{});
            keys = string(Mesh.GetMaterialAttributes(material));
            values = {};
            for i = 1:length(keys)
                m = Mesh.GetMaterialAttribute(material,keys(i));
                m = double(m);
                if(isempty(m))
                    m = Mesh.GetMaterialAttributeString(material,keys(i));
                    m = string(m);
                end
                values{i} = m;
            end
            m = {keys,values};

        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    m = getAttribute(Mesh,material,attribute)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            validateattributes(material,{'string'},{});
            switch nargin
            case 2
                m = Geometry.getAttributes(Mesh,material);
                return;
            end
            validateattributes(attribute,{'string'},{});

            m = Mesh.GetMaterialAttribute(material,attribute);
            m = double(m);
            if(isempty(m))
                m = Mesh.GetMaterialAttributeString(material,attribute);
                m = string(m);
                return;
            else
                return;
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    Mesh = meshRead(filename,material)
            [libname, libloadername] = Geometry.Initialize;
            switch nargin
            case 1
                material = "";
            end
            validateattributes(material, {'string'},{});
            filename_char = char(filename);
            lastdot_pos = strfind(filename_char, '.');
            ext = filename_char(lastdot_pos(end)+1:end);
            extlow = lower(ext);
            if(strcmp(extlow, "fbx") | strcmp(extlow,"obj") | strcmp(extlow,"dae") | strcmp(extlow,"stp") | strcmp(extlow,"step") | strcmp(extlow,"iges") | strcmp(extlow,"igs"))
                Mesh1 = clib.(libloadername).MeshLib.Mesh_1;
                clib.(libloadername).MeshLib.Loader.LoadMesh(Mesh1,filename,material);
                            
                Mesh = Geometry.mesh;
    
                for i = 1:Mesh1.GetMaterialCount
                    mat1 = Mesh1.GetMaterial(i-1);
                    mat = clib.(libname).MeshLib.MeshMaterial(mat1.GetName);
                                    
                    atts1 = string(mat1.GetAttributes);
                    if(~isempty(atts1))
                        for i = 1:length(atts1)
                            attval =  Mesh1.GetMaterialAttribute(mat1.GetName,atts1(i));
                            if(isstring(attval))
                                mat.SetAttribute(atts1(i),attval);
                            else
                                mat.SetAttribute(atts1(i),double(attval));
                            end
                        end
                    end
                    Mesh.AddMaterial(mat,true);
                end
    
                Mesh.AddTrianglesInVector(double(Mesh1.GetTrianglesInVector));
                a = double(Mesh1.GetVertexInVector);
                Mesh.AddVertexInVector(a);
                if(Mesh1.GetVertexColors.Dimensions ~= 0)
                    Mesh.AddVertexColorsInVector(double(Mesh1.GetVertexColorInVector));
                    Mesh.SetColorIndicesSameAsPositionIndices();
                end
                Mesh.MergeSameMaterials();
                clib.(libname).MeshLib.CleanUp.RemoveInvalidData(Mesh);
                return;
            end
            Mesh = clib.(libname).MeshLib.Mesh_1;
            clib.(libname).MeshLib.LoaderBase.LoadMesh(Mesh,filename,material);
            clib.(libname).MeshLib.CleanUp.RemoveInvalidData(Mesh);
            clib.(libname).MeshLib.CleanUp.RemoveDuplicateVerts(Mesh,1e-17,true);
            clib.(libname).MeshLib.CleanUp.RemoveDuplicateTriangles(Mesh,true,true);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    meshWrite(Mesh, filename)
            [libname, libloadername] = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            clib.(libname).MeshLib.CleanUp.RemoveInvalidData(Mesh);
            clib.(libname).MeshLib.CleanUp.RemoveDuplicateVerts(Mesh,1e-17,true);
            clib.(libname).MeshLib.CleanUp.RemoveDuplicateTriangles(Mesh,true,true);
                        
            filename_char = char(filename);
            lastdot_pos = strfind(filename_char, '.');
            ext = filename_char(lastdot_pos(end)+1:end);
            extlow = lower(ext);

            if(strcmp(extlow, "fbx") | strcmp(extlow,"obj") | strcmp(extlow,"dae"))
                Mesh1 = clib.(libloadername).MeshLib.Mesh_1;
                for i = 1:Mesh.GetMaterialCount
                    mat = Mesh.GetMaterial(i-1);
                    Mesh1.AddMaterial(mat.GetName,true);
                end
                Mesh1.AddTrianglesInVector(double(Mesh.GetTrianglesInVector));
                a = double(Mesh.GetVertexInVector);
                Mesh1.AddVertexInVector(a);
                if(Mesh.GetVertexColorCount ~= 0)
                    Mesh1.AddVertexColorsInVector(double(Mesh.GetVertexColorInVector));
                    Mesh1.SetColorIndicesSameAsPositionIndices();
                end
                clib.(libloadername).MeshLib.Loader.WriteMesh(filename,Mesh1);
                return;
            end
            clib.(libname).MeshLib.LoaderBase.WriteMesh(filename,Mesh);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    Mesh = box(corner1,corner2,material)
            libname = Geometry.Initialize;
            Mesh = Geometry.mesh;
            switch nargin
            case 0
                corner1 = [-1,-1,-1];
                corner2 = [1,1,1];
                material = "";
            case 1
                corner2 = [1,1,1];
                material = "";
            case 2
                material = "";
            end
            validateattributes(corner1,{'numeric'},{'size',[1,3]})
            validateattributes(corner2,{'numeric'},{'size',[1,3]})
            validateattributes(material, {'string'},{});
            clib.(libname).MeshLib.Primitive.MakeBox(Mesh,corner1,corner2,material);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    Mesh = cylinder(height,radius,material,steps,caps)
            libname = Geometry.Initialize;
            Mesh = Geometry.mesh;
            switch nargin
            case 0
                height = 1;
                radius = 1;
                material = "";
                steps = [20 20];
                caps = true;
            case 1
                radius = 1;
                material = "";
                steps = [20 20];
                caps = true;
            case 2
                material = "";
                steps = [20 20];
                caps = true;
            case 3
                steps = [20 20];
                caps = true;
            case 4
                caps = true;
            end
            if(length(steps) == 1)
                steps =  [steps steps];
            end
            validateattributes(material, {'string'},{});
            validateattributes(radius,{'numeric'},{'positive'});
            validateattributes(height,{'numeric'},{'positive','scalar'});
            validateattributes(steps,{'numeric'},{'positive','integer','size',[1,2],'>',3});
            validateattributes(caps,{'logical'},{});

            clib.(libname).MeshLib.Primitive.MakeCylinder(Mesh,height,radius,caps,material,steps);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    Mesh = frustum(height,radius1,radius2,material,steps,caps)
            libname = Geometry.Initialize;
            Mesh = Geometry.mesh;
            switch nargin
            case 0
                height = 1;
                radius1 = 1;
                radius2 = 1;
                material = "";
                steps = [20 20];
                caps = true;
            case 1
                radius1 = 1;
                radius2 = 1;
                material = "";
                steps = [20 20];
                caps = true;
            case 2
                radius2 = 1;
                material = "";
                steps = [20 20];
                caps = true;
            case 3
                material = "";
                steps = [20 20];
                caps = true;
            case 4
                steps = [20 20];
                caps = true;
            case 5
                caps = true;
            end

            if(isscalar(steps))
                steps =  [steps steps];
            end

            validateattributes(material, {'string'},{});
            validateattributes(radius1,{'numeric'},{'positive'});
            validateattributes(radius2,{'numeric'},{'positive'});
            validateattributes(height,{'numeric'},{'positive','scalar'});
            validateattributes(steps,{'numeric'},{'positive','integer','size',[1,2],'>',3});
            validateattributes(caps,{'logical'},{});
            clib.(libname).MeshLib.Primitive.MakeFrustum(Mesh,height,radius1,radius2,caps,material,steps);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    Mesh = cone(height,radius,material,steps,caps)
            libname = Geometry.Initialize;
            Mesh = Geometry.mesh;
            switch nargin
            case 0
                height = 1;
                radius = 1;
                material = "";
                steps = [20 20];
                caps = true;
            case 1
                radius = 1;
                material = "";
                steps = [20 20];
                caps = true;
            case 2
                material = "";
                steps = [20 20];
                caps = true;
            case 3
                steps = [20 20];
                caps = true;
            case 4
                caps = true;
            end

            if(length(steps) == 1)
                steps =  [steps steps];
            end
            validateattributes(material, {'string'},{});
            validateattributes(radius,{'numeric'},{'positive'});
            validateattributes(height,{'numeric'},{'positive','scalar'});
            validateattributes(steps,{'numeric'},{'positive','integer','size',[1,2],'>',3});
            validateattributes(caps,{'logical'},{});
            clib.(libname).MeshLib.Primitive.MakeFrustum(Mesh,height,radius,0,caps,material,steps);

            Mesh = Geometry.meshClean(Mesh);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    Mesh = disk(radius,material,steps)
            libname = Geometry.Initialize;
            Mesh = Geometry.mesh;
            switch nargin
            case 0
                radius = 1;
                material = "";
                steps = 20;
            case 1
                material = "";
                steps = 20;
            case 2
                steps = 20;
            end

            validateattributes(material, {'string'},{});
            validateattributes(radius,{'numeric'},{'positive'});
            validateattributes(steps,{'numeric'},{'positive','integer','scalar','>',3});
            clib.(libname).MeshLib.Primitive.MakeDisk(Mesh, radius, material, steps);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    Mesh = sphere(radius,material,steps)
            libname = Geometry.Initialize;
            Mesh = Geometry.mesh;
            switch nargin
            case 0
                radius = 1;
                material = "";
                steps = 20;
            case 1
                material = "";
                steps = 20;
            case 2
                steps = 20;
            end

            validateattributes(material, {'string'},{});
            validateattributes(radius,{'numeric'},{'positive'});
            validateattributes(steps,{'numeric'},{'positive','integer','scalar','>',3});
            clib.(libname).MeshLib.Primitive.MakeSphere(Mesh,radius,material,steps);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    Mesh = ellipsoid(radius,material,steps)
            libname = Geometry.Initialize;
            Mesh = Geometry.mesh;
            switch nargin
            case 0
                radius = [1 1 1];
                material = "";
                steps = 20;
            case 1
                material = "";
                steps = 20;
            case 2
                steps = 20;
            end

            validateattributes(material, {'string'},{});
            validateattributes(radius,{'numeric'},{'positive','size',[1,3]});
            validateattributes(steps,{'numeric'},{'positive','integer','scalar','>',3});
            clib.(libname).MeshLib.Primitive.MakeEllipsoid(Mesh,radius,material,steps);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    Mesh = torus(majorRadius,minorRadius, material,majorSteps,minorSteps)
            libname = Geometry.Initialize;
            Mesh = Geometry.mesh;
            switch nargin
            case 0
                majorRadius = 1;
                minorRadius = 0.25;
                material = "";
                majorSteps = 20;
                minorSteps = 10;
            case 1
                minorRadius = 0.25;
                material = "";
                majorSteps = 20;
                minorSteps = 10;
            case 2
                material = "";
                majorSteps = 20;
                minorSteps = 10;
            case 3
                majorSteps = 20;
                minorSteps = 10;
            case 4
                minorSteps = 10;
            end

            validateattributes(material, {'string'},{});
            validateattributes(majorRadius,{'numeric'},{'positive'});
            validateattributes(minorRadius,{'numeric'},{'positive'});
            validateattributes(majorSteps,{'numeric'},{'positive','integer','scalar','>',3});
            validateattributes(minorSteps,{'numeric'},{'positive','integer','scalar','>',3});
            clib.(libname).MeshLib.Primitive.MakeTorus(Mesh, majorRadius,minorRadius,majorSteps,minorSteps,material);
            
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    Mesh = geodesicSphere(radius,subdivisions,material)
            libname = Geometry.Initialize;
            Mesh = Geometry.mesh;
            switch nargin
            case 0
                radius = 1;
                subdivisions = 1;
                material = "";
            case 1
                subdivisions = 1;
                material = "";
            case 2
                material = "";
            end

            validateattributes(material, {'string'},{});
            validateattributes(radius,{'numeric'},{'positive'});
            validateattributes(subdivisions,{'numeric'},{'positive','integer','scalar','>',0});
            clib.(libname).MeshLib.Primitive.MakeGeodesicSphere(Mesh, radius, subdivisions, material);
        
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         function    Mesh = tetrahedron(radius,material)
            libname = Geometry.Initialize;
            Mesh = Geometry.mesh;
            switch nargin
            case 0
                radius = 1;
                material = "";
            case 1
                material = "";
            end

            validateattributes(material, {'string'},{});
            validateattributes(radius,{'numeric'},{'positive'});
            clib.(libname).MeshLib.Primitive.MakeTetrahedron(Mesh, radius,material);
            
         end
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         function    Mesh = octahedron(radius,material)
            libname = Geometry.Initialize;
            Mesh = Geometry.mesh;
            switch nargin
            case 0
                radius = 1;
                material = "";
            case 1
                material = "";
            end

            validateattributes(material, {'string'},{});
            validateattributes(radius,{'numeric'},{'positive'});
            clib.(libname).MeshLib.Primitive.MakeOctahedron(Mesh, radius,material);
                        
         end
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         function    Mesh = dodecahedron(material)
            libname = Geometry.Initialize;
            Mesh = Geometry.mesh;
            Radius = 1;
            switch nargin
            case 0
                material = "";
                Radius = 1;
            end

            validateattributes(material, {'string'},{});
            validateattributes(Radius,{'numeric'},{'positive'});
            clib.(libname).MeshLib.Primitive.MakeDodecahedron(Mesh, Radius, material);
            
         end
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         function    Mesh = icosahedron(radius,material)
            libname = Geometry.Initialize;
            Mesh = Geometry.mesh;
            switch nargin
            case 0
                radius = 1;
                material = "";
            case 1
                material = "";
            end

            validateattributes(material, {'string'},{});
            validateattributes(radius,{'numeric'},{'positive'});
            clib.(libname).MeshLib.Primitive.MakeIcosahedron(Mesh, radius,material);
                        
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    Mesh = linearExtrude(polyshape,varargin)
            libname = Geometry.Initialize;
            Mesh = Geometry.mesh;
            Graph = Geometry.planarGraph(polyshape);
            p = inputParser;
            addParameter(p,'Material',"",@(x)validateattributes(x, {'string'},{}));
            addParameter(p,'Height',1,@(x)validateattributes(x,{'numeric'},{'scalar'}));
            addParameter(p,'Caps',false,@islogical);
            addParameter(p,'Steps',1,@(x)validateattributes(x,{'numeric'},{'positive','integer','scalar'}));
            addParameter(p,'Direction',[0 0 1],@(x)validateattributes(x,{'numeric'},{'size',[1,3]}));
            addParameter(p,'EndScale',[1,1],@(x)validateattributes(x,{'numeric'},{}));
            addParameter(p,'EndRotation',0,@(x)validateattributes(x,{'numeric'},{'scalar'}));
            parse(p,varargin{:});
            
            if(length(p.Results.EndScale) >= 2)
                endscale = [p.Results.EndScale(1) p.Results.EndScale(2)];
            else
                endscale = [p.Results.EndScale(1) p.Results.EndScale(1)];
            end

            clib.(libname).MeshLib.Extrude.LinearExtrude(Mesh,Graph,p.Results.Height,p.Results.Direction,p.Results.Material,p.Results.Steps, endscale,p.Results.EndRotation);
            if(p.Results.Caps)
                Geometry.extrudeCaps(polyshape,Mesh,p.Results.Material);
            end
            
            Geometry.removeDuplicates(Mesh);
        end
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    Mesh = circularExtrude(polyshape,varargin)
            libname = Geometry.Initialize;
            Mesh = Geometry.mesh;
            Graph = Geometry.planarGraph(polyshape);
            p = inputParser;
            addParameter(p,'Material',"",@(x)validateattributes(x, {'string'},{}));
            addParameter(p,'Caps',false,@islogical);
            addParameter(p,'Steps',50,@(x)validateattributes(x,{'numeric'},{'positive','integer','scalar','>',0}));
            addParameter(p,'Angle',360,@(x)validateattributes(x,{'numeric'},{'scalar'}));
            addParameter(p,'Pitch',0,@(x)validateattributes(x,{'numeric'},{'scalar'}));
            parse(p,varargin{:});


            if(p.Results.Pitch == 0)
                if (p.Results.Steps == 1)
                    steps = 20;
                else
                    steps = p.Results.Steps;
                end
                clib.(libname).MeshLib.Extrude.CircularExtrude(Mesh,Graph,p.Results.Angle,p.Results.Material,steps);
            else
                if (p.Results.Steps == 1)
                    steps = 0;
                else
                    steps = p.Results.Steps;
                end
                clib.(libname).MeshLib.Extrude.HelicalExtrude(Mesh,Graph,p.Results.Angle,p.Results.Pitch,p.Results.Material,steps);
            end
            if((p.Results.Caps && p.Results.Pitch ~= 0 )|| (p.Results.Caps && p.Results.Angle ~= 360))
                Geometry.circularExtrudeCaps(Graph,polyshape,Mesh,p.Results.Material);
            end

            Geometry.removeDuplicates(Mesh);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    Mesh = pathExtrude(polyshape,points,varargin)
            libname = Geometry.Initialize;
            Mesh = Geometry.mesh;
            graph = Geometry.planarGraph(polyshape);
            sizeP = size(points);
            if (sizeP(2) ~= 3)
                error(message('shared_geometry_matlab:Geometry:InvalidPointsSizeInput', sizeP(1),sizeP(2)))
            end
            p = inputParser;
            addParameter(p,'Material',"",@(x)validateattributes(x, {'string'},{}));
            addParameter(p,'Miter',false,@islogical);
            addParameter(p,'Caps',false,@islogical);
            addParameter(p,'Closed',false,@islogical);
            parse(p,varargin{:});
            path_c = clib.array.(libname).glm.dvec3(0);
                       
            [row,~] = size(points);
            for i = 1:row
                path_c.append(clib.(libname).glm.dvec3(points(i,1),points(i,2),points(i,3)))
            end
            clib.(libname).MeshLib.Extrude.PathExtrude(Mesh,graph,path_c,p.Results.Material,logical(p.Results.Miter),logical(p.Results.Closed));
                        
            if(p.Results.Caps && ((p.Results.Closed == false) && max((points(1,:)~=points(end,:)))))
                Geometry.extrudeCaps(polyshape,Mesh,p.Results.Material);
            end
            Geometry.removeDuplicates(Mesh);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    Mesh = bevelExtrude(poly,varargin)
            libname = Geometry.Initialize;
            Mesh = Geometry.mesh;
            switch class(poly)
            case 'clib.'+libname+'.MeshLib.Polygon_2d_1'
                P1 = poly;
            case 'polyshape'
                P1 = Geometry.polygon1(poly);
            otherwise
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput2','Polygon_2d_1','Polyshape'));
            end
           
            p = inputParser;
            addParameter(p,'Material',"",@(x)validateattributes(x, {'string'},{}));
            addParameter(p,'Horizontal_Offset',0,@(x)validateattributes(x,{'numeric'},{'scalar'}));
            addParameter(p,'Height',1,@(x)validateattributes(x,{'numeric'},{'scalar'}));
            addParameter(p,'Caps',false,@islogical);
            addParameter(p,'Steps',1,@(x)validateattributes(x,{'numeric'},{'positive','integer','scalar'}));
            parse(p,varargin{:});
            clib.(libname).MeshLib.Extrude.BevelExtrude(Mesh,P1,p.Results.Horizontal_Offset,p.Results.Height,logical(p.Results.Caps),p.Results.Material,p.Results.Steps);
            
            Geometry.removeDuplicates(Mesh);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    [outMesh, unorientedTriangles] = orient(Mesh, reverse)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            outMesh = Geometry.mesh;
            outMesh.AddTriangles(Mesh.GetTriangles);
            outMesh.AddVertex(Mesh.GetVertex);
            outMesh.AddMaterials(Mesh.GetMaterials);
            switch nargin
            case 1
                reverse = false;
            end
            
            validateattributes(reverse,{'logical'},{})
            
            edges = clib.(libname).MeshLib.Edgelist(outMesh);
            edgeana = clib.(libname).MeshLib.EdgeAnalysis(outMesh,edges);
            unorientedTriangles =  clib.array.(libname).UnsignedInt(0);
            
            edgeana.Orient(unorientedTriangles,outMesh,edges,reverse);
            unorientedTriangles = uint32(unorientedTriangles) + 1;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    outMesh = subdivide(Mesh, steps, tolerance)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            outMesh = Geometry.mesh;
            switch nargin
            case 1
                steps = 1;
                tolerance = 0;
            case 2
                tolerance = 0;
            end
            validateattributes(tolerance,{'numeric'},{'nonnegative','scalar'})
            clib.(libname).MeshLib.Subdivide.Subdivide(outMesh,Mesh,steps,tolerance);
            
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    outMesh = loopSubdivide(Mesh,steps)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            outMesh = Geometry.mesh;
            switch nargin
            case 1
                steps = 1;
            end
            clib.(libname).MeshLib.Subdivide.LoopSubdivide(outMesh,Mesh,steps);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    outMesh = sqrtSubdivide(Mesh,steps)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            outMesh = Geometry.mesh;
            switch nargin
            case 1
                steps = 1;
            end
            clib.(libname).MeshLib.Subdivide.SqrtSubdivide(outMesh,Mesh,steps);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    outMesh = holeFilling(Mesh,varargin)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            outMesh = Geometry.mesh;
            
            p = inputParser;
            addParameter(p,'Material',"",@(x)validateattributes(x, {'string'},{}));
            addParameter(p,'MaximumEdges',-1,@(x)validateattributes(x,{'numeric'},{'nonnegative','scalar'}));
            addParameter(p,'MaximumDiameter',-1.0,@(x)validateattributes(x,{'numeric'},{'positive','integer','scalar'}));
            addParameter(p,'Refine',false,@islogical);
            parse(p,varargin{:});
            clib.(libname).MeshLib.FillHoles.TriangulateHoles(outMesh,Mesh,p.Results.Material,p.Results.Refine,p.Results.MaximumDiameter,p.Results.MaximumEdges, ...
                clib.(libname).glm.dvec3(0.0), clib.(libname).glm.dvec3(0.0), clib.(libname).glm.dvec2(0.0));
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    outMesh = simplify(Mesh,varargin)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            outMesh = Geometry.mesh;
            
            p = inputParser;
            addParameter(p,'EdgeLength',0,@(x)validateattributes(x,{'numeric'},{'nonnegative','scalar'}));
            addParameter(p,'EdgeRatio',0,@(x)validateattributes(x,{'numeric'},{'nonnegative','scalar','<',1}));
            addParameter(p,'EdgeNumber',0,@(x)validateattributes(x,{'numeric'},{'positive','integer','scalar'}));
            addParameter(p,'Strategy',false,@islogical);
            parse(p,varargin{:});
            
            clib.(libname).MeshLib.Simplify.Simplify(outMesh,Mesh,p.Results.EdgeLength,p.Results.EdgeRatio,p.Results.EdgeNumber,p.Results.Strategy);
            
        end
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function   outMesh = smoothMesh(Mesh,varargin)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            outMesh = Geometry.copymesh(Mesh);

            p = inputParser;
            addParameter(p,'Iterations',1,@(x)validateattributes(x,{'numeric'},{'nonnegative','integer','scalar'}));
            addParameter(p,'SmoothFactor',0.5,@(x)validateattributes(x,{'numeric'},{'nonnegative','scalar'}));
            addParameter(p,'WeightType',1,@(x)validateattributes(x,{'numeric'},{'positive','integer','scalar','<',4}));
            addParameter(p,'ModifyVertexAttributes',true,@islogical);
            parse(p,varargin{:});

            if(p.Results.WeightType == 1)
                clib.(libname).MeshLib.Smoothing.Smoothing(outMesh,p.Results.Iterations,p.Results.SmoothFactor,"linear", p.Results.ModifyVertexAttributes);
            elseif(p.Results.WeightType == 2)
                clib.(libname).MeshLib.Smoothing.Smoothing(outMesh,p.Results.Iterations,p.Results.SmoothFactor,"uniform", p.Results.ModifyVertexAttributes);
            elseif(p.Results.WeightType == 3)
                clib.(libname).MeshLib.Smoothing.Smoothing(outMesh,p.Results.Iterations,p.Results.SmoothFactor,"taubin", p.Results.ModifyVertexAttributes);
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    outMesh = extractMaterialMesh(Mesh,material)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            outMesh = Geometry.mesh;
            validateattributes(material, {'string'},{});
            clib.(libname).MeshLib.GeometryOperations.ExtractMaterialMesh(outMesh,Mesh,material);
             
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	
        function    outMesh = extractMeshFromBox(Mesh,dimensions)	
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            outMesh = Geometry.mesh;	
            validateattributes(dimensions,{'numeric'},{'size',[1,6]});	
            clib.(libname).MeshLib.GeometryOperations.ExtractMeshFromBox(outMesh,Mesh,dimensions)
            
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    outMesh = join(Mesh1,Mesh2)
            libname = Geometry.Initialize;
            if class(Mesh1) ~= "clib."+libname+".MeshLib.Mesh_1" || class(Mesh2) ~= "clib."+libname+".MeshLib.Mesh_1"
                    error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            
            outMesh = Geometry.mesh;
            clib.(libname).MeshLib.GeometryOperations.JoinMesh(outMesh,Mesh1,Mesh2);
                        
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function   [Mesh1,Mesh2] = corefine(Mesh3, Mesh4)
            libname = Geometry.Initialize;
            if class(Mesh3) ~= "clib."+libname+".MeshLib.Mesh_1" || class(Mesh4) ~= "clib."+libname+".MeshLib.Mesh_1"
                    error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            Mesh1 = Geometry.mesh;
            Mesh2 = Geometry.mesh;
            clib.(libname).MeshLib.GeometryOperations.Corefine(Mesh1,Mesh2,Mesh3,Mesh4);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function   outMesh = union(Mesh1, Mesh2)
            libname = Geometry.Initialize;
            if class(Mesh1) ~= "clib."+libname+".MeshLib.Mesh_1" || class(Mesh2) ~= "clib."+libname+".MeshLib.Mesh_1"
                    error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            outMesh = Geometry.mesh;
            Geometry.removeDuplicates(Mesh1);
            Geometry.removeDuplicates(Mesh2);

            clib.(libname).MeshLib.GeometryOperations.Union(outMesh,Mesh1,Mesh2);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function  outMesh =  intersect( Mesh1, Mesh2)
            libname = Geometry.Initialize;
            if class(Mesh1) ~= "clib."+libname+".MeshLib.Mesh_1" || class(Mesh2) ~= "clib."+libname+".MeshLib.Mesh_1"
                    error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            outMesh = Geometry.mesh;
            Geometry.removeDuplicates(Mesh1);
            Geometry.removeDuplicates(Mesh2);
            clib.(libname).MeshLib.GeometryOperations.Intersect(outMesh,Mesh1,Mesh2); 
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    outMesh = subtract(Mesh1, Mesh2)
            libname = Geometry.Initialize;
            if class(Mesh1) ~= "clib."+libname+".MeshLib.Mesh_1" || class(Mesh2) ~= "clib."+libname+".MeshLib.Mesh_1"
                    error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            outMesh = Geometry.mesh;
            Geometry.removeDuplicates(Mesh1);
            Geometry.removeDuplicates(Mesh2);
            clib.(libname).MeshLib.GeometryOperations.Subtract(outMesh,Mesh1,Mesh2);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    outMesh = translate(Mesh,translate_x,y,z)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            translate_mesh = [];
            switch nargin
            case 2
                if length(translate_x) == 3
                    translate_mesh = translate_x;
                elseif length(translate_x) == 2
                    translate_mesh = [translate_x,0];
                elseif length(translate_x) == 1
                    translate_mesh = [translate_x,0,0];
                else 
                    translate_mesh = translate_x;
                end
            case 3
                translate_mesh = [translate_x,y,0];
            case 4
                translate_mesh = [translate_x,y,z];
            end
            validateattributes(translate_mesh,{'numeric'},{'size',[1,3]});
            outMesh = clib.(libname).MeshLib.Meshtools.TranslateMesh(Mesh,translate_mesh);
                        
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    outMesh = rotate(Mesh,axisvector,theta,origin)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            switch nargin
            case 3
                origin = [0,0,0];
            end
            validateattributes(origin,{'numeric'},{'size',[1,3]});
            validateattributes(axisvector,{'numeric'},{'size',[1,3]});
            validateattributes(theta,{'numeric'},{'scalar'});
            outMesh = clib.(libname).MeshLib.Meshtools.RotateMesh(Mesh,axisvector,theta,origin);
            
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        function    outMesh = scale(Mesh,scale,origin)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            scale_mesh = [];
            switch nargin
            case 2
                if(length(scale) == 1)
                    scale_mesh = [scale,scale,scale];
                elseif (length(scale) == 3)
                    scale_mesh = scale;
                elseif (length(scale) == 2)
                    scale_mesh = [scale,1];
                end
                origin = [0,0,0];
            case 3
                if(length(scale) == 1)
                    scale_mesh = [scale,scale,scale];
                elseif (length(scale) == 3)
                    scale_mesh = scale;
                elseif (length(scale) == 2)
                    scale_mesh = [scale,1];
                end
            end
            validateattributes(origin,{'numeric'},{'size',[1,3]});
            validateattributes(scale_mesh,{'numeric'},{'size',[1,3]});
            outMesh = clib.(libname).MeshLib.Meshtools.ScaleMesh(Mesh,scale_mesh,origin);
            
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    outMesh = applyTransform(Mesh,T)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            validateattributes(T,{'numeric'},{'size',[3,4]});
            T(4,:) = [0 0 0 1];
            T = reshape(T,1,16);
            outMesh = clib.(libname).MeshLib.Meshtools.TransformMesh(Mesh,T);
            
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    vol = volume(Mesh)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            vol = 0;
            vol = clib.(libname).MeshLib.MeshQuery.Volume(vol,Mesh);  
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    boundingBox = boundingBox(Mesh)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            boundingBox =  clib.array.(libname).Double(0);
            clib.(libname).MeshLib.MeshQuery.BoundingBox(boundingBox,Mesh);
                        
            boundingBox = double(boundingBox);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    Areas = areas(Mesh)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            Areas =  clib.array.(libname).Double(0);
            clib.(libname).MeshLib.MeshQuery.FaceArea(Areas,Mesh);
                       
            Areas = double(Areas);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    FaceNormals = faceNormals(Mesh)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end

            FaceNormals =  clib.array.(libname).Double(0);
            clib.(libname).MeshLib.MeshQuery.FaceNormals(FaceNormals,Mesh);
                        
            FaceNormals = double(FaceNormals);
            FaceNormals = reshape(FaceNormals,3,[]);
            FaceNormals = FaceNormals';
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    VertexNormals = vertexNormals(Mesh)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            VertexNormals =  clib.array.(libname).Double(0);
            clib.(libname).MeshLib.MeshQuery.VertexNormals(VertexNormals,Mesh);
                        
            VertexNormals = double(VertexNormals);
            VertexNormals = reshape(VertexNormals,3,[]);
            VertexNormals = VertexNormals';
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    [FaceNormals,VertexNormals] = computeNormals(Mesh)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
             
            FaceNormals =  clib.array.(libname).Double(0);
            VertexNormals =  clib.array.(libname).Double(0);
            clib.(libname).MeshLib.MeshQuery.ComputeNormals(FaceNormals,VertexNormals,Mesh);
                        
            FaceNormals = double(FaceNormals);
            FaceNormals = reshape(FaceNormals,3,[]);
            FaceNormals = FaceNormals';
            
            VertexNormals = double(VertexNormals);
            VertexNormals = reshape(VertexNormals,3,[]);
            VertexNormals = VertexNormals';
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    Triangle = findTriangle(Mesh,normal,tolerance)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            switch nargin
            case 2
                tolerance = 0.1;
            end
            Triangle =  clib.array.(libname).UnsignedInt(0);
            normal = clib.(libname).glm.dvec3(normal(1),normal(2),normal(3));
            clib.(libname).MeshLib.MeshQuery.TrianglesWithGivenNormals(Triangle,Mesh,normal,tolerance);
                        
            Triangle = uint32(Triangle);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    verts = sharpCorner(Mesh,angle,numedges)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            switch nargin
            case 1
                angle = pi - deg2rad(2);
                numedges = 3;
            case 2
                numedges = 3;
            end
            angle = deg2rad(angle);
            Geometry.removeDuplicates(Mesh);

            verts =  clib.array.(libname).UnsignedInt(0);
            edge = clib.(libname).MeshLib.Edgelist(Mesh,true);
            clib.(libname).MeshLib.MeshAnalysis.CornerDetection(verts,edge,Mesh,angle,numedges);
            
            verts = uint32(verts);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    COG = centerOfMass(Mesh)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
             
            COG = clib.(libname).glm.dvec3;
            clib.(libname).MeshLib.MeshQuery.COG(COG,Mesh);
            COG = clib.(libname).MeshLib.MeshQuery.glm3tovec(COG);
                       
            COG = double(COG);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function   outMesh = meshClean(Mesh,varargin)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            outMesh = Geometry.mesh;
            outMesh.AddTriangles(Mesh.GetTriangles);
            outMesh.AddVertex(Mesh.GetVertex);
            outMesh.AddMaterials(Mesh.GetMaterials);

            p = inputParser;
            addParameter(p,'Tolerance',1e-17,@(x)validateattributes(x,{'numeric'},{'nonnegative','scalar','<',1e-1}));
            addParameter(p,'RemoveDuplicateVerts',true,@islogical);
            addParameter(p,'RemoveDuplicateTriangles',true,@islogical);
            addParameter(p,'RemoveUnreferencedVerts',true,@islogical);
            addParameter(p,'RemoveDegenerateTriangles',true,@islogical);
            addParameter(p,'RemoveSameMaterialTriangles',true,@islogical);
            addParameter(p,'RemoveFlippedTriangles',true,@islogical);
            parse(p,varargin{:});

            if(p.Results.RemoveDuplicateVerts)
                clib.(libname).MeshLib.CleanUp.RemoveDuplicateVerts(outMesh,p.Results.Tolerance,true);
            end
            if(p.Results.RemoveDegenerateTriangles)
                clib.(libname).MeshLib.CleanUp.RemoveSmallTriangles(outMesh,0);
            end
            if(p.Results.RemoveDuplicateTriangles)
                clib.(libname).MeshLib.CleanUp.RemoveDuplicateTriangles(outMesh,p.Results.RemoveFlippedTriangles,p.Results.RemoveSameMaterialTriangles);
            end
            if(p.Results.RemoveUnreferencedVerts)
                clib.(libname).MeshLib.CleanUp.RemoveIsolatedVerts(outMesh);
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function TR = meshToTriangulation(Mesh)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            [P,T] = Geometry.extractMesh(Mesh);
            if isempty(P) || isempty(T)
                error(message('shared_geometry_matlab:Geometry:EmptyMesh'))
            end
            Face = T(:,1:3)+1;
            TR = triangulation(Face,P);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [P,T,M] = extractMesh(Mesh)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            numver = Mesh.GetVertexCount;
            numtri = Mesh.GetTriangleCount;
            mtlcount = double(Mesh.GetMaterialCount);
            for i = 0:mtlcount-1
                M(i+1) = Mesh.GetMaterial(i).GetName;
            end
            
            % P = [];
            % T = [];
            % if (numver  == 0) || (numtri == 0)
            %     return;
            % end
            tris = Mesh.GetTrianglesInVector;
            tris = double(tris);
            T = reshape(tris,[4,numtri])';

            verts = Mesh.GetVertexInVector;
            verts = double(verts);
            P = reshape(verts,[3,numver])';
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function T = RemoveTrianglesWithMaterial(Mesh, material)
            libname = Geometry.Initialize;
            if class(Mesh) ~= ("clib."+libname+".MeshLib.Mesh_1")
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
            end
            validateattributes(material,{'string'},{});
            m = Mesh.GetMaterialIndex(material);
            
            numtri = Mesh.GetTriangleCount;
            tris = Mesh.GetTrianglesInVector;
            tris = double(tris);
            Faces = reshape(tris,[4,numtri])';

            % Find the indices of the rows where the 4th column is equal to 1
            T = find(Faces(:, 4) == m);

            Mesh.RemoveTriangles((T-1)');
            Mesh.RemoveMaterial(material);
            clib.(libname).MeshLib.CleanUp.RemoveIsolatedVerts(Mesh);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function figHandle = plot(Mesh,varargin)
            libname = Geometry.Initialize;
            if class(Mesh) ~= "cell"
                Mesh = {Mesh};
            end
            % Parse inputs
            p = inputParser;
            addParameter(p,'FeatureEdges',nan,@(x)validateattributes(x,{'numeric'},{'nonnegative','scalar'}));
            addParameter(p,'Normals',0,@(x)validateattributes(x,{'numeric'},{'nonnegative','scalar'}));
            addParameter(p,'Color',[0,0,0],@(x)validateattributes(x,{'numeric'},{'size',[1,3]}));
            addParameter(p,'SharpCorners',[]);
            addParameter(p,'Edges',true,@islogical);
            addParameter(p,'ManifoldEdges',false,@islogical);
            addParameter(p,'BoundaryEdges',false,@islogical);
            addParameter(p,'UnorientedEdges',false,@islogical);
            addParameter(p,'NonManifoldEdges',false,@islogical);
            parse(p,varargin{:});
            
            MeshLen = length(Mesh);
            figHandle = figure;
            TotalMatCount = 0;
            for nummesh = 1:MeshLen
                if class(Mesh{nummesh}) ~= ( "clib."+libname+".MeshLib.Mesh_1")
                    error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1', 'Mesh'))
                end
                % Extract mesh vertices and triangles from the mesh
                [P,T] = Geometry.extractMesh(Mesh{nummesh});
    
                % Check if the mesh is empty
                if isempty(P) || isempty(T)
                    fprintf('Input mesh is empty\n')
                    return;
                end
                
    
                % Build edges if needed
                if(p.Results.ManifoldEdges || p.Results.BoundaryEdges || p.Results.NonManifoldEdges || p.Results.UnorientedEdges)
                    edges = clib.(libname).MeshLib.Edgelist;
                    
                    edges.Build(Mesh{nummesh});
                    numedge = edges.GetEdgeCount;
                    E = zeros(numedge,2);
                    P1= zeros(numedge,4);
                    P2= zeros(numedge,4);
                    
                    for i = 0:numedge-1
                        edge = edges.GetEdge(i);
                        E(i+1,:) = [edge.Index(1) edge.Index(2)];
                        P1(i+1,:) = [P(edge.Index(1)+1,1) P(edge.Index(1)+1,2) P(edge.Index(1)+1,3) 1];
                        P2(i+1,:) = [P(edge.Index(2)+1,1) P(edge.Index(2)+1,2) P(edge.Index(2)+1,3) 1];
                        if(edge.Edgetype == clib.(libname).MeshLib.MeshEdge.Classification.boundary)
                            P1(i+1,4) =  2;
                            P2(i+1,4) =  2;
                        end
                        if(edge.Edgetype == clib.(libname).MeshLib.MeshEdge.Classification.unoriented)
                            P1(i+1,4) =  3;
                            P2(i+1,4) =  3;
                        end
                        if(edge.Edgetype == clib.(libname).MeshLib.MeshEdge.Classification.nonmanifold)
                            P1(i+1,4) =  4;
                            P2(i+1,4) =  4;
                        end
                    end
                end
    
                % plot triangles with material
                Face = T(:,1:3)+1;
                edgecolor = 'none';
                if(isnan(p.Results.FeatureEdges) && p.Results.Edges && ~p.Results.ManifoldEdges && ~p.Results.BoundaryEdges && ~p.Results.NonManifoldEdges && ~p.Results.UnorientedEdges)
                    edgecolor = 'k';
                end
                
                mat = T(:,4);
                if(min(p.Results.Color == 0) == 0)
                    plotcolor = p.Results.Color;
                else
                    color = 0.5*(1+hsv(1000));
                    numcol = round(mod((TotalMatCount+mat) * 0.6180339887, 1)*1000 +1);
                    plotcolor = color(numcol,:);
                end
                
                figHandle(end+1) = trisurf(Face,P(:,1),P(:,2),P(:,3),'EdgeColor',edgecolor,'FaceVertexCData',plotcolor);
                hold on;
                % Plot normals
                if(p.Results.Normals)
                    TR = triangulation(Face,P);
                    facenormals = TR.faceNormal;
                    center =TR.incenter;
                    hold on
                    quiver3(center(:,1),center(:,2),center(:,3),facenormals(:,1),facenormals(:,2),facenormals(:,3),p.Results.Normals,'Color','b');
                end
    
                % plot feature edges
                if(~isnan(p.Results.FeatureEdges))
                    TR = Geometry.meshToTriangulation(Mesh{nummesh});
                    F = featureEdges(TR,p.Results.FeatureEdges)';
                    x = P(:,1);
                    y = P(:,2);
                    z = P(:,3);
                    hold on;
                    plot3(x(F),y(F),z(F),'k');
                end
    
                % plot edges
                if(p.Results.ManifoldEdges || p.Results.BoundaryEdges || p.Results.NonManifoldEdges || p.Results.UnorientedEdges)
                    for e = 1:length(P1)
                        if (P1(e,4) == 1 && p.Results.ManifoldEdges) 
                            color = 'k';
                        elseif (P1(e,4) == 2 && p.Results.BoundaryEdges) 
                            color = 'k';
                        elseif (P1(e,4) == 3 && p.Results.UnorientedEdges) 
                            color = 'k';
                        elseif (P1(e,4) == 4 && p.Results.NonManifoldEdges)
                            color = 'k';
                        else
                            continue;
                        end
                        plot3([P1(e,1),P2(e,1)],[P1(e,2),P2(e,2)],[P1(e,3),P2(e,3)],'Color',color);
                        hold on;
                    end
                end
    
                % plot sharp corners
                for sc = 1:length(p.Results.SharpCorners)
                    len = size(P);
                    if(p.Results.SharpCorners(sc)+1 > len(1))
                        error('Value of SharpCorners exceeds the number of vertices');
                    end
                    hold on
                    plot3(P(p.Results.SharpCorners(sc)+1,1),P(p.Results.SharpCorners(sc)+1,2),P(p.Results.SharpCorners(sc)+1,3),'.','Color','b','MarkerSize',20)
                end
                %hold off;
                % label axis and set the aspect ratio
                xlabel('x-axis')
                ylabel('y-axis')
                zlabel('z-axis')
                set(gca,'DataAspectRatio',[1 1 1])
     
                mtlcount = double(Mesh{nummesh}.GetMaterialCount);
                if(min(p.Results.Color == 0) ~= 0)
                    for i = 0:mtlcount-1
                        j = (TotalMatCount+i);
                        numcol = round(mod(j * 0.6180339887, 1)*1000 +1);
                        Color = color(numcol,:);
                        att = double(Mesh{nummesh}.GetMaterialAttribute(Mesh{nummesh}.GetMaterial(i).GetName,"Color"));
                        att1 = double(Mesh{nummesh}.GetMaterialAttribute(Mesh{nummesh}.GetMaterial(i).GetName,"color"));
                        if(length(att) == 3)
                            Color = att/norm(att);
                        elseif (length(att1) == 3)
                            Color = att1/norm(att1);
                        end
                        if(j < 17)
                            name  = Mesh{nummesh}.GetMaterial(i).GetName;
                            if(i == 0)
                                %name = "Default";
                                continue;
                            end
                            annotation('textbox',[.9 .9-(0.05*(j-1)) .10 .05],'FontSize', 8,'FontWeight','bold','LineWidth',1.0,'String',name,'Color',Color,'EdgeColor','none','BackgroundColor',[0 0 0])
                        end
                    end
                end
                TotalMatCount = TotalMatCount + mtlcount - 1;
            end
            hold off;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    Poly = polygon(x,y)
            libname = Geometry.Initialize;
            [row,col] = size(x);
            Poly = clib.(libname).MeshLib.Polygon_2d_1;
            for i = 1:row
                poly1 =  clib.array.(libname).glm.dvec2(0);
                for j = 1:col
                    poly1.append(clib.(libname).glm.dvec2(x(i,j),y(i,j)))
                end
                Poly.AddBoundaryPolygon(poly1);
            end
            
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    Pgon = poly2polyshape(poly)
            Pgon = polyshape;
            switch nargin
            case 0
                return;
            end
            if(poly.GetNumberOfPolygons == 0)
                return;
            end
            numboundaries = poly.GetNumberOfPolygons;
            for i = 0:numboundaries-1
                dim = poly.GetBoundaryPolygon(i).Dimensions;
                x = zeros(1,dim);
                y = zeros(1,dim);
                for j = 0:(dim-1)
                    pt = poly.GetPolygonPointVector(i,j);
                    x(j+1) = pt(1);
                    y(j+1) = pt(2);
                end
                Pgon = addboundary(Pgon,x,y); 
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    Mesh = triangulationsToMesh(T,material)
            Mesh = Geometry.mesh;
            Big_P = [];
            Big_K = [];
            vercount = 0;
            for i = 1:length(T)
                switch nargin
                case 1
                    material = "";
                end
                if ~isa(T{i},'triangulation')
                    error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1','Triangulation'))
                end
                validateattributes(material, {'string'},{});
                Mesh.AddMaterial(material);
                P = T{i}.Points;
                [~,len] = size(P);
                [~,trilen] =size(T{i}.ConnectivityList);
                if(len == 2)
                    P = [ P zeros(size(P,1),1)];
                    K = T{i}.ConnectivityList - 1 + vercount;
                elseif(trilen == 4)
                    K = (convhull(T{i}.Points)-1) + vercount;
                else
                    K = T{i}.ConnectivityList - 1 + vercount;
                end
                [n, ~] = size(P);
                matIndex = double(Mesh.GetMaterialIndex(material));	
                K = [ K matIndex*ones(size(K,1),1)];
                K = reshape(K',1,[]);
                P = reshape(P',1,[]);
                Big_P = [Big_P P];
                Big_K = [Big_K K];
                vercount = vercount + n;
            end

            Mesh.AddVertexInVector(Big_P);
            Mesh.AddTrianglesInVector(Big_K);
        end
    end
    

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private, Static = true)
        function outMesh = copymesh(mesh)
            outMesh = Geometry.mesh;
            outMesh.AddTriangles(mesh.GetTriangles());
            outMesh.AddVertex(mesh.GetVertex);
            outMesh.AddVertexColorsInVector(mesh.GetVertexColorInVector);
            outMesh.AddMaterials(mesh.GetMaterials);
        end
        function extrudeCaps(polyshape,Mesh,material)
            T1 = triangulation(polyshape);
            [numtris,~] = size(T1.ConnectivityList);
            [numpoints,~] = size(T1.Points);
            endcapnumtris = Mesh.GetVertexCount - numpoints;
            for i = 1:numtris
                Mesh.AddTriangle(T1.ConnectivityList(i,3)-1,T1.ConnectivityList(i,2)-1,T1.ConnectivityList(i,1)-1,material);
                Mesh.AddTriangle(endcapnumtris+T1.ConnectivityList(i,1)-1,endcapnumtris+T1.ConnectivityList(i,2)-1,endcapnumtris+T1.ConnectivityList(i,3)-1,material);
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function circularExtrudeCaps(graph,polyshape,Mesh,material)
            T1 = triangulation(polyshape);
            [numtris,~] = size(T1.ConnectivityList);
            numpoints = graph.GetVertexCount;
            endcapnumtris = Mesh.GetVertexCount - numpoints;
            for i = 1:numtris
                Mesh.AddTriangle(T1.ConnectivityList(i,1)-1,T1.ConnectivityList(i,2)-1,T1.ConnectivityList(i,3)-1,material);
                Mesh.AddTriangle(endcapnumtris+T1.ConnectivityList(i,3)-1,endcapnumtris+T1.ConnectivityList(i,2)-1,endcapnumtris+T1.ConnectivityList(i,1)-1,material);
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function removeDuplicates(Mesh)
            libname = Geometry.Initialize;
            clib.(libname).MeshLib.CleanUp.RemoveInvalidData(Mesh);
            clib.(libname).MeshLib.CleanUp.RemoveSmallTriangles(Mesh,0);
            clib.(libname).MeshLib.CleanUp.RemoveInvalidTriangles(Mesh);
            clib.(libname).MeshLib.CleanUp.RemoveDuplicateVerts(Mesh);
            clib.(libname).MeshLib.CleanUp.RemoveDuplicateTriangles(Mesh,true,true);
            clib.(libname).MeshLib.CleanUp.RemoveIsolatedVerts(Mesh);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    Graph = planarGraph(pgon)
            libname = Geometry.Initialize;
            switch nargin
            case 0
                Graph = clib.(libname).MeshLib.PlanarGraph;
                return;
            end

            P1 = clib.(libname).MeshLib.Polygon_2d_1;
            [x,y] = pgon.boundary;
            numboundaries = pgon.numboundaries;
            poly1 = clib.array.(libname).glm.dvec2(0);
            for i = 1:length(x)
                if(isnan(x(i)))
                    poly1.removeLast;
                    P1.AddBoundaryPolygon(poly1);
                    poly1 = clib.array.(libname).glm.dvec2(0);
                else
                    poly1.append(clib.(libname).glm.dvec2(x(i),y(i)))
                end
                if(i == length(x))
                    poly1.removeLast;
                    P1.AddBoundaryPolygon(poly1);
                end
            end
            if(P1.GetNumberOfPolygons ~= numboundaries)
                error(message('shared_geometry_matlab:Geometry:InvalidGraph', 'Polyshape'));
            else
                Graph = clib.(libname).MeshLib.PlanarGraph(P1);
            end
            
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    Poly = polygon1(pgon)
            libname = Geometry.Initialize;
            switch nargin
            case 0
                Poly = clib.(libname).MeshLib.Polygon_2d_1;
                return;
            end
            Poly = clib.(libname).MeshLib.Polygon_2d_1;
            [x,y] = pgon.boundary;
            numboundaries = pgon.numboundaries;
            poly1 = clib.array.(libname).glm.dvec2(0);
            for i = 1:length(x)
                if(isnan(x(i)))
                    poly1.removeLast;
                    Poly.AddBoundaryPolygon(poly1,true);
                    poly1 =clib.array.(libname).glm.dvec2(0);
                else
                    poly1.append(clib.(libname).glm.dvec2(double(x(i)),double(y(i))))
                end
                if(i == length(x))
                    poly1.removeLast;
                    Poly.AddBoundaryPolygon(poly1,true);
                end
            end
            if(Poly.GetNumberOfPolygons ~= numboundaries)
                error(message('shared_geometry_matlab:Geometry:InvalidGraph', 'Polyshape'));
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function    Mesh = triangulationToMesh(T,material)
            Mesh = Geometry.mesh;
            switch nargin
            case 1
                material = "";
            end
            if ~isa(T,'triangulation')
                error(message('shared_geometry_matlab:Geometry:InvalidObjectInput1','Triangulation'));
            end
            validateattributes(material, {'string'},{});
            Mesh.AddMaterial(material);
            P = T.Points;
            [~,len] = size(P);
            [~,trilen] =size(T.ConnectivityList);
            if(len == 2)
                P = [ P zeros(size(P,1),1)];
                K = T.ConnectivityList - 1;
            elseif(trilen == 4)
                K = (convhull(T.Points)-1);
            else
                K = T.ConnectivityList - 1;
            end
            Mesh.AddMaterial(material);
            matIndex = double(Mesh.GetMaterialIndex(material));
            K = [ K matIndex*ones(size(K,1),1)];
            K = reshape(K',1,[]);
            P = reshape(P',1,[]);
            Mesh.AddVertexInVector(P);
            Mesh.AddTrianglesInVector(K);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end
end