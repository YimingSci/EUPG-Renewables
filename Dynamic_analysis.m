%% European Power Grid Model with High Wind and Solar Penetration
%
% This code implements a dynamic model of the European transmission grid,
% focusing on high renewable energy integration in Portugal, Spain, and France.
% It includes all available utility-scale wind and solar generation units 
% across these three countries.
%
% The renewable energy dataset includes:
%   - 2,423 solar photovoltaic (PV) units
%   - 32,644 individual wind turbines
%   - These are aggregated into 470 equivalent generator models
%
% The aggregation preserves the spatial distribution and capacity profile 
% of real-world assets, enabling realistic dynamic simulations and power flow analysis.
% The model supports studies on system stability, cross-border coupling,
% and virtual inertia deployment strategies.
%
% For detailed application, analysis, and conclusions, please refer to:
%   * "Rethinking the Green Power Grid"  
%     Yiming Wang, Arthur N. Montanari, and Adilson E. Motter  
%     (July 2025)
%
% Please cite the above article if you use this code in your research.
%
% -------------------------------------------------------------------------
% Copyright (C) 2025  Yiming Wang, Arthur N. Montanari & Adilson E. Motter
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
%   Last modified by Yiming Wang on 2025-07-13


clear;
load('PSF_Renewable.mat');
Sb = pant.baseMVA;
N_bus = length(pant.bus); N_line = length(pant.branch);
dt = 1E-3;  Ndt = 5000;



% %% Add new cross-border lines at the ES-FR border, corresponding to Fig. 1B in [1]
% Add = [1813 771;
%        2072 1044;
%        1179 1042;
%        2070 777;
%        2207 1043;
%        2360 1178;
%        1449 1174;
%        1678 1177;
%        1935 644;
%        1815 912];
% 
% template_line = pant.branch(118, :);
% num_add = size(Add, 1);
% new_branch = repmat(template_line, num_add, 1);
% new_branch(:, 1:2) = Add;
% pant.branch = [pant.branch; new_branch];
 
% %% Equip Iberian Peninsula wind and PV units with virtual inertia, corresponding to Fig. 1C in [1]
% ID_iberia = find(strcmp(pant.bus_country, 'ES') | strcmp(pant.bus_country, 'PT'));
% ID_renewable = pant.gen(619:end, 1);
% ID_iberia_renewable = intersect(ID_renewable, ID_iberia);
% 
% [~, Gen_iberia_renewable] = ismember(ID_iberia_renewable, pant.gen(:, 1));
% Gen_iberia_renewable = Gen_iberia_renewable(Gen_iberia_renewable > 0);
% 
% pant.gen_inertia(Gen_iberia_renewable) = 30 * pant.gen_inertia(Gen_iberia_renewable);



% Fault Initialization
id_fault1 = 3335;
dP_real1 = 355;

id_fault2 = 3159;
dP_real2 = 917;

id_fault3 = 3324;
dP_real3 = 550;

id_fault4 = 3036;
dP_real4 = 23;

id_fault5 = 3704;
dP_real5 = 34;

id_fault6 = 2537;
dP_real6 = 37.5;

% Parameter Initialization
L = pant.bus(:,3)/Sb; 
G = zeros(N_bus,1);

is_producing = pant.gen(:,2) > 0;
id_gen = pant.gen(is_producing,1);
id_load = setdiff(1:length(L), id_gen)';

N_gen = length(id_gen);
N_load = length(id_load);

G(id_gen) = pant.gen(is_producing,2)/Sb; 
P = -L + G;
P = P - mean(P);


A = sparse([pant.branch(:,1); pant.branch(:,2)], [1:N_line 1:N_line], [ones(N_line,1); -ones(N_line,1)]);
b = -1i ./ pant.branch(:,4);
Ybus = conj(A * sparse(1:N_line,1:N_line,b) * A');
Q = zeros(N_bus,1);
V = ones(N_bus,1);
theta = zeros(N_bus,1);
[~,theta,~,~] = NRsolver(Ybus, V, theta, -P, Q, [], 9, 1E-11, 1000);
P_gen = P(id_gen);
P_load = P(id_load);

egdes = zeros(N_line,2);
line_start = pant.branch(:,1);
line_end = pant.branch(:,2);
for i=1:N_gen
    egdes(line_start == id_gen(i),1) = i;
    egdes(line_end == id_gen(i),2) = i;
end
for i=1:N_load
    egdes(line_start == id_load(i),1) = i + N_gen;
    egdes(line_end == id_load(i),2) = i + N_gen;
end
line_susceptance = 1 ./ pant.branch(:,4);

dP1 = -dP_real1 / Sb;
row_idx1 = find(id_gen == id_fault1);
P_gen(row_idx1) = P_gen(row_idx1) + dP1;

dP2 = -dP_real2 / Sb;
row_idx2 = find(id_gen == id_fault2);
P_gen(row_idx2) = P_gen(row_idx2) + dP2;

dP3 = -dP_real3 / Sb;
row_idx3 = find(id_gen == id_fault3);
P_gen(row_idx3) = P_gen(row_idx3) + dP3;

dP4 = -dP_real4 / Sb;
row_idx4 = find(id_gen == id_fault4);
P_gen(row_idx4) = P_gen(row_idx4) + dP4;

dP5 = -dP_real5 / Sb;
row_idx5 = find(id_gen == id_fault5);
P_gen(row_idx5) = P_gen(row_idx5) + dP5;

dP6 = -dP_real6 / Sb;
row_idx6 = find(id_gen == id_fault6);
P_gen(row_idx6) = P_gen(row_idx6) + dP6;

M_gen_orig = pant.gen_inertia(is_producing);
D_gen_orig = pant.gen_prim_ctrl(is_producing) + pant.load_freq_coef(id_gen);
D_load = pant.load_freq_coef(id_load);

% State Initialization
omega_gen_init = zeros(N_gen,1);
theta_gen_init = theta(id_gen);
theta_load_init = theta(id_load);

incidence_mat = sparse([egdes(:,1); egdes(:,2)], [1:N_line 1:N_line], [ones(N_line,1); -ones(N_line,1)]);
G_graph = graph(pant.branch(:,1), pant.branch(:,2));
A_adj = adjacency(G_graph);
deg = sum(A_adj, 2);
D_inv = spdiags(1./deg, 0, N_bus, N_bus);
W = D_inv * A_adj;

n_colors = 100;
blue = [1, 1, 1];
red = [1, 0, 0];
r = linspace(blue(1), red(1), n_colors)';
g = linspace(blue(2), red(2), n_colors)';
b = linspace(blue(3), red(3), n_colors)';
cmap = [r, g, b];

sizes = ones(N_bus,1)*15;
sizes(id_gen) = 30;

M_gen =  M_gen_orig;
D_gen =  D_gen_orig;

omega_gen = omega_gen_init;
theta_gen = theta_gen_init;
theta_load = theta_load_init;

m = 10;
omega_t = zeros(N_gen, floor(Ndt/m));
delta_t = zeros(N_gen, floor(Ndt/m));
k = 1;

% Time-domain Simulation
for i = 1:Ndt
    y = Radau5(omega_gen, theta_gen, theta_load, ...
        M_gen, D_gen, D_load, P_gen, P_load, incidence_mat, line_susceptance, dt, 14, 1E-6);

    if mod(i, 200) == 0
        fprintf('Completed %d iterations...\n', i);
    end

    if mod(i,m) == 0
        omega_t(:,k) = y(1:N_gen);
        delta_t(:,k) = y(N_gen+1:2*N_gen);
        k = k + 1;
    end

    omega_gen = y(1:N_gen);
    theta_gen = y(N_gen+1:2*N_gen);
    theta_load = y(2*N_gen+1:end);
end
