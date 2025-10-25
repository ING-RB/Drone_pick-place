function [Q,R] = qrinsert(Q,R,j,x,orient)
%QRINSERT Insert a column or row into QR factorization.
%   [Q1,R1] = QRINSERT(Q,R,J,X) returns the QR factorization of the matrix A1,
%   where A1 is A=Q*R with an extra column, X, inserted before A(:,J). If A has
%   N columns and J = N+1, then X is inserted after the last column of A.
%
%   QRINSERT(Q,R,J,X,'col') is the same as QRINSERT(Q,R,J,X).
%
%   [Q1,R1] = QRINSERT(Q,R,J,X,'row') returns the QR factorization of the matrix
%   A1, where A1 is A=Q*R with an extra row, X, inserted before A(J,:).
%
%   Example:
%      A = magic(5);  [Q,R] = qr(A);
%      j = 3; x = 1:5;
%      [Q1,R1] = qrinsert(Q,R,j,x,'row');
%   returns a valid QR factorization, although possibly different from
%      A2 = [A(1:j-1,:); x; A(j:end,:)];
%      [Q2,R2] = qr(A2);
%
%   Class support for inputs Q,R,X:
%      float: double, single
%
%   See also QR, QRDELETE, PLANEROT.

%   Copyright 1984-2024 The MathWorks, Inc.

if nargin < 5
    if nargin < 4
        error(message('MATLAB:qrinsert:NotEnoughInputs'))
    end
    orient = 'col';
end
if ~isnumeric(j)||~isscalar(j)||~isfinite(j)||~isreal(j) || floor(j)~=j
    error(message('MATLAB:qrinsert:InvalidJ'));
end
% This comparison handles strings and partial matching
if isstring(orient) || iscellstr(orient)
    if matlab.internal.math.checkInputName(orient,'col',1)
        orient = 'col';
    elseif matlab.internal.math.checkInputName(orient,'row',1)
        orient = 'row';
    end
end

% Cast x to the class of Q*R
x = cast(x, superiorfloat(Q, R));
R = triu(R);

[mx,nx] = size(x);
[mq,nq] = size(Q);
[mr,nr] = size(R);

if (isequal(orient,'col') && (nr==0)) || (isequal(orient,'row') && (mr==0))
    [Q,R] = qr(x);
    return;
end

% Error checking
if  mq ~= nq % Econ QR is not supported
    error(message('MATLAB:qrinsert:QNotSquare'))
elseif nq ~= mr
    error(message('MATLAB:qrinsert:InnerDimQRfactors'))
elseif j <= 0
    error(message('MATLAB:qrinsert:NegInsertionIndex'))
end

% Check if Q and R are non-sparse float arrays before invoking the
% built-in function
isBuiltinCompatible = @(Q,R,j)(~isobject(Q) && isfloat(Q) && ~issparse(Q)) && ...
    (~isobject(R) && isfloat(R) && ~issparse(R))&&~isobject(j);

switch orient
    case 'col'

        if (j > nr+1)
            error(message('MATLAB:qrinsert:InvalidInsertionIndex'))
        elseif (mx ~= mq) || (nx ~= 1)
            error(message('MATLAB:qrinsert:WrongSizeInsertedCol'))
        end

        % Make room and insert x before j-th column.
        R(:,j+1:nr+1) = R(:,j:nr);
        R(:,j) = Q'*x;
        nr = nr+1;

        % Now R has nonzeros below the diagonal in the j-th column,
        % and "extra" zeros on the diagonal in later columns.
        %    R = [x x x x x         [x x x x x
        %         0 x x x x    G     0 x x x x
        %         0 0 + x x   --->   0 0 * * *
        %         0 0 + 0 x          0 0 0 * *
        %         0 0 + 0 0]         0 0 0 0 *]
        % Use Givens rotations to zero the +'s, one at a time, from bottom to top.
        %
        % Q is treated to (the transpose of) the same rotations.
        %    Q = [x x x x x    G'   [x x * * *
        %         x x x x x   --->   x x * * *
        %         x x x x x          x x * * *
        %         x x x x x          x x * * *
        %         x x x x x]         x x * * *]

        if isBuiltinCompatible(Q,R,j)
            [Q,R] = matlab.internal.math.insertCol(Q,R,j);
        else
            for k = mr-1:-1:j
                p = k:k+1;
                [G,R(p,j)] = planerot(R(p,j));
                if k < nr
                    R(p,k+1:nr) = G*R(p,k+1:nr);
                end
                Q(:,p) = Q(:,p)*G';
            end
        end

    case 'row'

        if (j > mr+1)
            error(message('MATLAB:qrinsert:InvalidInsertionIndex'))
        elseif (mx ~= 1) || (nx ~= nr)
            error(message('MATLAB:qrinsert:WrongSizeInsertedRow'))
        end

        R = [x; R];

        % Let Q1=Q[1:j-1,:], Q2=Q[j:end,:]. Modify Q such that
        % Q =[0 Q1;
        %     1 0;
        %     0 Q2];
        Qold = Q;
        Q = zeros(mq+1, nq+1, "like", Qold);
        Q(1:j-1, 2:end) = Qold(1:j-1, :);
        Q(j+1:end, 2:end) = Qold(j:end, :);
        Q(j,1) = 1;

        % Now R is upper Hessenberg.
        %    R = [x x x x         [* * * *
        %         + x x x    G       * * *
        %           + x x   --->       * *
        %             + x                *
        %               +          0 0 0 0
        %         0 0 0 0          0 0 0 0
        %         0 0 0 0]         0 0 0 0]
        % Use Givens rotations to zero the +'s, one at a time, from top to bottom.
        %
        % Q is treated to (the transpose of) the same rotations
        %        [0 | x x x x x         [* * * * * *
        %         0 | x x x x x          * * * * * *
        %         --|----------          -----------
        %    Q =  1 | 0 0 0 0 0          # # # # # #
        %         --|----------    G'    -----------
        %         0 | x x x x x   --->   * * * * * *
        %         0 | x x x x x          * * * * * *
        %         0 | x x x x x          * * * * * *
        %         0 | x x x x x]         * * * * * *]

        if isBuiltinCompatible(Q,R,j)
            [Q,R] = matlab.internal.math.insertRow(Q,R,1);
        else
            for i = 1 : min(mr,nr)
                p = i : i+1;
                [G,R(p,i)] = planerot(R(p,i));
                R(p,i+1:nr) = G * R(p,i+1:nr);
                Q(:,p) = Q(:,p) * G';
            end
        end

    otherwise
        error(message('MATLAB:qrinsert:InvalidInput5'));
end
