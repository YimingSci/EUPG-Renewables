% -------------------------------------------------------------------------
% This MATLAB code computes the optimal descent path based on heatmap data.
% It interpolates scattered data points representing investment scenarios 
% in system inertia and transmission line upgrades, and their associated 
% frequency deviations. 
%
% The dataset structure (matrix Mk):
%   - Column 1: Investment in inertia upgrade (0 = status quo)
%   - Column 2: Investment in transmission line upgrade (0 = status quo)
%   - Column 3: Frequency deviation values
%
% Main features of this code:
%   - Interpolates irregular data points onto a uniform 2D grid
%   - Performs block-averaging to reduce noise and extract representative values
%   - Implements a steepest-descent search algorithm to trace the optimal path
%     of investment decisions that minimize frequency deviation
%   - Includes curve smoothing with cubic spline (csaps or pchip as fallback)
%   - Outputs a smooth and interpretable optimal gradient path
%
% Applications:
%   - Investment strategy optimization in power system planning
%   - Sensitivity analysis of frequency deviation vs. investment distribution
%   - Visualization of trade-offs between different upgrade options
%
% Please cite this work if you use or adapt this code in your research.
%
% -------------------------------------------------------------------------
% Copyright (C) 2025  
%   Yiming Wang, Arthur N. Montanari & Adilson E. Motter
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
%
%   Last modified by Yiming Wang 
%   on 2025-09-17
% -------------------------------------------------------------------------

%% Clean environment
clear; clc;

%% Load heatmap data (matrix Mk)
% Mk structure:
%   - Column 1: Investment in inertia upgrade (0 = status quo)
%   - Column 2: Investment in transmission line upgrade (0 = status quo)
%   - Column 3: Frequency deviation values
% ----------------------------------------------------------
% Note: Ensure matrix Mk is available in workspace before running

% Raw scatter data
x = Mk(:,1);
y = Mk(:,2);
z = Mk(:,3);
Sto_draw = [x, y, z];  % original triplet data

%% Construct uniform grid (0 ~ 2500)
xr = linspace(0, 2500, 150);
yr = linspace(0, 2500, 150);
[Xg, Yg] = meshgrid(xr, yr);

% Interpolation: map scattered points to regular grid
F  = scatteredInterpolant(x, y, z, 'natural', 'none'); % extrapolation = NaN
Zg = F(Xg, Yg);

%% Block averaging (10×10 blocks)
nb = 10;                       % number of blocks
[nr, nc] = size(Zg);
rows_per = nr / nb;
cols_per = nc / nb;

x2 = zeros(nb, nb);            % block centers (x)
y2 = zeros(nb, nb);            % block centers (y)
z2 = nan(nb, nb);              % block mean values

for i = 1:nb
    r = (rows_per*(i-1)+1) : (rows_per*i);   % row indices
    for j = 1:nb
        c = (cols_per*(j-1)+1) : (cols_per*j); % column indices
        x2(i,j) = mean(xr(c));
        y2(i,j) = mean(yr(r));
        blk = Zg(r, c);
        vals = blk(~isnan(blk));
        if ~isempty(vals)
            z2(i,j) = mean(vals);
        else
            z2(i,j) = NaN;
        end
    end
end
ZZ = [x2(:), y2(:), z2(:)]; 

%% Steepest descent path search
% Start from block closest to (0,0)
dist2 = (x2 - 0).^2 + (y2 - 0).^2; 
dist2(isnan(z2)) = inf; % ignore invalid points

curve_points = []; % initialize path
if ~all(isinf(dist2(:)))
    % Nearest valid block to origin
    [~, linMin] = min(dist2(:));
    [i0, j0] = ind2sub(size(dist2), linMin);

    % Current position
    i = i0; j = j0;
    path_x = []; path_y = [];
    max_steps = nb * nb;  % safety bound

    % Iterative steepest descent
    for step = 1:max_steps
        path_x(end+1,1) = x2(i,j);
        path_y(end+1,1) = y2(i,j);

        % Neighbor search (3×3 window)
        ir = max(1,i-1):min(nb,i+1);
        jr = max(1,j-1):min(nb,j+1);
        [JJ, II] = meshgrid(jr, ir);
        II = II(:); JJ = JJ(:);

        % Remove self
        self = (II==i) & (JJ==j);
        II(self) = []; JJ(self) = [];

        % Keep valid neighbors
        idx_nb = sub2ind([nb, nb], II, JJ);
        valid = ~isnan(z2(idx_nb));
        II = II(valid); JJ = JJ(valid);
        idx_nb = idx_nb(valid);

        if isempty(II), break; end

        % Compute slopes
        z_here = z2(i,j);
        z_nb   = z2(idx_nb);
        dx = x2(idx_nb) - x2(i,j);
        dy = y2(idx_nb) - y2(i,j);
        dist = hypot(dx, dy);
        slope = (z_nb - z_here) ./ dist;

        % Pick steepest descent
        [minSlope, k] = min(slope);
        if ~isfinite(minSlope) || minSlope >= 0, break; end
        i = II(k); j = JJ(k);
    end

    %% Path smoothing
    if numel(path_x) >= 2
        P = [path_x(:), path_y(:)];

        % Force start at origin
        anchor_start = [0, 0];
        P_aug = [anchor_start; P];

        % Arc-length parameterization
        d  = [0; hypot(diff(P_aug(:,1)), diff(P_aug(:,2)))];
        s  = cumsum(d);
        if s(end) > 0
            sN = s / s(end);
            s_fine = linspace(0,1,200)'; % refined sampling

            % Smooth with csaps if available
            use_csaps = exist('csaps','file') == 2;
            if use_csaps
                p = 0.95;                           % smoothness
                w = ones(size(P_aug,1),1);
                w(1)   = 1e6;   % strong weight on origin
                w(end) = 5;     % moderate weight on endpoint
                sx = csaps(sN, P_aug(:,1), p, [], w);
                sy = csaps(sN, P_aug(:,2), p, [], w);
                x_smooth = fnval(sx, s_fine);
                y_smooth = fnval(sy, s_fine);
            else
                % Fallback: piecewise cubic interpolation (guaranteed through origin)
                x_smooth = pchip(sN, P_aug(:,1), s_fine);
                y_smooth = pchip(sN, P_aug(:,2), s_fine);
            end

            curve_points = [x_smooth(:), y_smooth(:)];
        end
    end
end