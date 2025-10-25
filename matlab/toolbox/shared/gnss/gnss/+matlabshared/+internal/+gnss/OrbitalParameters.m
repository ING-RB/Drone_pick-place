classdef (Hidden) OrbitalParameters
%ORBITALPARAMETERS Internal class to report satellite orbital parameters
%
%   This class is for internal use only. It may be removed in the future.
    
%   Copyright 2020-2021 The MathWorks, Inc.

%#codegen

    methods (Static)
        function [e0, i0, OmegaRefDot, ARef, Omega0, omega0, M0] = nominal
            %NOMINAL Orbital parameters from GPS performance standard
            %
            %   Parameters are from Table A.2-2 in 
            %   <a href="matlab:web https://www.gps.gov/technical/ps/2008-SPS-performance-standard.pdf">GPS SPS Performance Standard</a>
            
            numSatellites = 27;
            
            % Eccentricity
            e0 = zeros(numSatellites, 1);
            
            % Inclination (rad)
            % Table A.2-2 lists a delta inclination of 1 degree relative to
            % 54 degrees. So, reference inclination, i0, is 55 degrees.
            i0 = deg2rad(55) * ones(numSatellites, 1); 
            
            % Rate of Right Ascension (rad/sec)
            OmegaRefDot = deg2rad(-4.4874e-7) * ones(numSatellites, 1);
            
            % Semi-major axis (m)
            ARef = 26559710 * ones(numSatellites, 1); 
                            
            % Geographic Longitude of the Ascending Node (rad)
            Omega0 = [   357.734        357.734     357.734 357.734 ...
                      57.734 57.734      57.734      57.734  57.734 ...
                         117.734        117.734     117.734 117.734 ...
                         177.734    177.734 177.734 177.734 177.734 ...
                         237.734        237.734     237.734 237.734 ...
                         297.734    297.734 297.734 297.734 297.734]; 
            Omega0 = deg2rad(Omega0(:));
                             
                             
            % Argument of perigee (rad)
            omega0 = zeros(numSatellites, 1);
            
            % Mean Anomaly (rad)
            M0 = [   268.126        161.786      11.676  41.806 ...
                  94.916 66.356     173.336     309.976 204.376 ...
                     111.876         11.796     339.666 241.556 ...
                     135.226    282.676 257.976  35.156 167.356 ...
                     197.046        302.596      66.066 333.686 ...
                     238.886      0.456 334.016 105.206 135.346];
            M0 = deg2rad(M0(:));
        end
    end
end
