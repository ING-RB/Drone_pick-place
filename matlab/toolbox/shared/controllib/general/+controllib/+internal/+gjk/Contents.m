% controllib.internal.gjk package solves collision queries between two
% geometries. These covered queries include checking whether two objects
% overlap in space, computing the minimum Euclidean separation distance
% between their boundaries, and finding the closest point from each other.
% 
% 2D Shape Constructor:
%   <a href="matlab:help controllib.internal.gjk.s2.Rectangle" >rectangle</a>
%   <a href="matlab:help controllib.internal.gjk.s2.Circle"    >circle</a>
%   <a href="matlab:help controllib.internal.gjk.s2.Triangle"  >triangle</a>
%   <a href="matlab:help controllib.internal.gjk.s2.Capsule"   >capsule</a>
%   <a href="matlab:help controllib.internal.gjk.s2.Mesh"      >mesh</a>
% 
% 3D Shape Constructor:
%   <a href="matlab:help controllib.internal.gjk.s3.Box"       >box</a>
%   <a href="matlab:help controllib.internal.gjk.s3.Sphere"    >sphere</a>
%   <a href="matlab:help controllib.internal.gjk.s3.Cone"      >cone</a>
%   <a href="matlab:help controllib.internal.gjk.s3.Cylinder"  >cylinder</a>
%   <a href="matlab:help controllib.internal.gjk.s3.Capsule"   >capsule</a>
%   <a href="matlab:help controllib.internal.gjk.s3.Mesh"      >mesh</a>
% 
% Check collision Methods
%   <a href="matlab:help controllib.internal.gjk.Base2d.checkCollision">checkCollision</a>                   - 2D Shapes
%   <a href="matlab:help controllib.internal.gjk.Base3d.checkCollision">checkCollision</a>                   - 3D Shapes
%
% Check collision Options
%   <a href="matlab:help controllib.internal.gjk.gjkSolverOptions">gjkSolverOptions</a>
%
% Plot shape method
%   <a href="matlab:help controllib.internal.gjk.View"    >view</a>
%
% Contents of controllib.internal.gjk package:
%
% <a   href="matlab:help controllib.internal.gjk.GJK"                               >@GJK</a>                            Base class for Base2d/3D.
%   <a href="matlab:help controllib.internal.gjk.GJK.closestPointOnEdgeToPoint"     >closestPointOnEdgeToPoint</a>      - Solve closest point on edge to point.
%   <a href="matlab:help controllib.internal.gjk.GJK.closestPointOnTriangleToPoint" >closestPointOnTriangleToPoint</a>  - Solve closest point on Triangle to point. 
%   <a href="matlab:help controllib.internal.gjk.GJK.closestPointOnTetraToPoint"    >closestPointOnTetraToPoint</a>     - Solve closest point on Tetrahedron to point.
%   <a href="matlab:help controllib.internal.gjk.GJK.solveDistance"                 >solveDistance</a>                  - Solve Distance
%
% <a   href="matlab:help controllib.internal.gjk.Base2d"               >@Base2d</a>                         Base class for 2D shapes.
%   <a href="matlab:help controllib.internal.gjk.Base2d.testSimplex1"  >testSimplex1</a>                   - Routine for line simplex check. 
%   <a href="matlab:help controllib.internal.gjk.Base2d.testSimplex2"  >testSimplex2</a>                   - Routine for triangle simplex check. 
%   <a href="matlab:help controllib.internal.gjk.Base2d.testSimplex3"  >testSimplex3</a>                   - todo: delete Not needed for 2d shapes
%   <a href="matlab:help controllib.internal.gjk.Base2d.checkCollision">checkCollision</a>                 - Main Gilbert-Johnson-Keerthi algorithm.
%
% <a   href="matlab:help controllib.internal.gjk.Base3d"               >@Base3d</a>                         Base class for 3D shapes.
%   <a href="matlab:help controllib.internal.gjk.Base3d.testSimplex1"  >testSimplex1</a>                   - Routine for line simplex check. 
%   <a href="matlab:help controllib.internal.gjk.Base3d.testSimplex2"  >testSimplex2</a>                   - Routine for triangle simplex check. 
%   <a href="matlab:help controllib.internal.gjk.Base3d.testSimplex3"  >testSimplex3</a>                   - Routine for tetrahedron simplex check. 
%   <a href="matlab:help controllib.internal.gjk.Base3d.checkCollision">checkCollision</a>                 - Main Gilbert-Johnson-Keerthi algorithm.
%
% <a   href="matlab:help controllib.internal.gjk.2d"           >+2d</a>                            Package to store subclasses of <a href="matlab:help controllib.internal.gjk.Base2d">Base2d</a>.
%   <a href="matlab:help controllib.internal.gjk.s2.Rectangle" >rectangle</a>                      - Rectangle class.
%   <a href="matlab:help controllib.internal.gjk.s2.Circle"    >circle</a>                         - Circle class.
%   <a href="matlab:help controllib.internal.gjk.s2.Triangle"  >triangle</a>                       - Triangle class.
%   <a href="matlab:help controllib.internal.gjk.s2.Capsule"   >capsule</a>                        - Capsule class.
%   <a href="matlab:help controllib.internal.gjk.s2.Mesh"      >convex mesh</a>                    - Convex Mesh class.
%   
% <a   href="matlab:help controllib.internal.gjk.3d"           >+3d</a>                            Package to store subclasses of <a href="matlab:help controllib.internal.gjk.Base3d">Base3d</a>.
%   <a href="matlab:help controllib.internal.gjk.s3.Box"       >box</a>                            - Box class.
%   <a href="matlab:help controllib.internal.gjk.s3.Sphere"    >sphere</a>                         - Sphere class.
%   <a href="matlab:help controllib.internal.gjk.s3.Cone"      >cone</a>                           - Cone class.
%   <a href="matlab:help controllib.internal.gjk.s3.Cylinder"  >cylinder</a>                       - Cylinder class.
%   <a href="matlab:help controllib.internal.gjk.s3.Capsule"   >capsule</a>                        - Capsule class.
%   <a href="matlab:help controllib.internal.gjk.s3.Mesh"      >mesh</a>                           - Mesh class.
%
% <a   href="matlab:help controllib.internal.gjk.howto"                         >+howto</a>                         Demonstration usage package
%  <a href="matlab:help controllib.internal.gjk.howto.create2DShapes"           >create2DShapes</a>                 - Creating 2D Shapes
%  <a href="matlab:help controllib.internal.gjk.howto.create3DShapes"           >create3DShapes</a>                 - Creating 3D Shapes
%  <a href="matlab:help controllib.internal.gjk.howto.checkCollisionOf2DShapes" >checkCollisionOf2DShapes</a>       - Check Collision Task for 2D shapes
%  <a href="matlab:help controllib.internal.gjk.howto.checkCollisionOf3DShapes" >checkCollisionOf2DShapes</a>       - Check Collision Task for 3D shapes
%
% Other Files
%   <a href="matlab:help controllib.internal.gjk.View">View</a>                          - View Summary of this class goes here
%   <a href="matlab:help controllib.internal.gjk.gjkSolverOptions">gjkSolverOptions</a>              - Creates a default set of options for GJK algorithm.
%   primitive2Collision           - Create a RT collision geometry
%   updateRTCollision             - Utilities to update collision geometry pose and patch.
%
% delete
%   ViewerBase                    - ViewerBase Base class for Viewer2 and Viewer3
%   Viewer2                       - Viewer2 Summary of this class goes here
%   Viewer3                       - Viewer3 Summary of this class goes here

