%#codegen
function [S] = cholUpdateFactor(S,U,c)
    %-----------------------------------------------
    % Author(s): Debraj Bhattacharjee

    % Copyright 2020 The MathWorks, Inc.
    %
    % Inputs:
    %     S  -  Sqrt of any Positive Semi-Definite Matrix
    %           S needs to be upper triangular.
    %     U  -  Any matrix whose columns are successively 
    %           used for the Rank-1 Cholesky update
    %
    % Outputs:
    %     S  -  Sqrt of Positive Semi-Definite Matrix after
    %           successive Rank-1 Cholesky update/downdate such that
    %           S*S.' = S*S.' +- u*u.' (where u is a column of U)
    %------------------------------------------------

    for i = 1:size(U,2)
        % Get particular column of U
        u = U(:,i);

        % Update the Sqrt Covariance
        if (c == '+')
            S = cholupdate(S,u,'+');
        else
            if coder.target('MATLAB')
                [S,p] = cholupdate(S,u,'-');
            else
                [S,p] = coder.internal.cholupdate(S,u,'-');
            end
            
            if (p ~= 0)                
                S = (matlabshared.tracking.internal.svdPSD(S.'*S - u*u.')).';
            
                % Need to have S in Upper Triangular form
                if ~istriu(S)
                    [~,S] = qr(S);
                end
            end
        end        
    end
	S = S.';
end
