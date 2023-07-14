%% Reset MATLAB
clear;
clc;
close all;

%% Run simulation

model_init;

modelName = 'mvdr_4x4_partial_systolic';
simout = sim_with_progress(modelName);

%% Extract simulation signals

% Indices where covariance matrix is sampled
matrix_in_latch_idx = find(simout.matrix_in_latch);
Ecx_latch_idx = matrix_in_latch_idx - 2;
Ecx_diag_latch_idx = matrix_in_latch_idx;
latch_offsets = diff(matrix_in_latch_idx);
num_solve_iterations = numel(matrix_in_latch_idx);

% Covariance matrix
sim_Ecx = simout.Ecx(Ecx_latch_idx,:);
sim_Ecx_scaled = simout.Ecx_scaled(Ecx_latch_idx,:);
sim_Ecx_loaded = simout.Ecx_loaded(Ecx_diag_latch_idx,:);

% Matrix solve input/output
sim_A_in = simout.matrix_solve_A_in(simout.matrix_solve_valid_in,:);
sim_B_in = simout.matrix_solve_B_in(simout.matrix_solve_valid_in,:);
sim_X_out = simout.matrix_solve_X_out(simout.matrix_solve_valid_out);

% Weight vector and normalization
sim_wp = simout.wp(simout.wp_valid,:);
sim_norm_mag = simout.norm_mag(simout.norm_mag_valid);
sim_norm_mag_inv = simout.norm_mag_inv(simout.norm_mag_inv_valid);
sim_w = simout.w(simout.w_valid,:);

% Output
sim_Y = simout.data_out(simout.valid_out);

% Received constellation
sim_constellation = qpsk_receive(sim_Y,testSrc1);

%% Run MATLAB reference

mvdr_reference;

%% Compare simulation to MATLAB reference

fignum=100;

ref = permute(datalog.Ecx, [2 3 1]);
ref = ref(:);
cmp = reshape(sim_Ecx.',[],1);
compareData(ref,cmp,fignum,'Covariance matrix');
fignum=fignum+1;

ref = permute(datalog.Ecx_scaled, [2 3 1]);
ref = ref(:);
cmp = reshape(sim_Ecx_scaled.',[],1);
compareData(ref,cmp,fignum,'Covariance matrix scaled');
fignum=fignum+1;

ref = permute(datalog.Ecx_loaded, [2 3 1]);
ref = ref(:);
cmp = reshape(sim_Ecx_loaded.',[],1);
compareData(ref,cmp,fignum,'Covariance matrix with diagonal loading');
fignum=fignum+1;

% ref = permute(datalog.Ecx_scaled, [3 2 1]);
% ref = ref(:);
% cmp = reshape(sim_A_in.',[],1);
% compareData(ref,cmp,fignum,'Matrix solve A in');
% fignum=fignum+1;

% ref = repmat(sv,num_solve_iterations,1);
% cmp = sim_B_in;
% compareData(ref,cmp,fignum,'Matrix solve B in');
% fignum=fignum+1;

% ref = reshape(datalog.wp.',[],1);
% cmp = reshape(sim_X_out.',[],1);
% compareData(ref,cmp,fignum,'Matrix solve X out');
% fignum=fignum+1;

ref = datalog.wp(1:size(sim_wp,1),:);
ref = reshape(ref.',[],1);
cmp = reshape(sim_wp.',[],1);
compareData(ref,cmp,fignum,'Matrix solve output');
fignum=fignum+1;

ref = datalog.norm_mag(1:numel(sim_norm_mag));
cmp = sim_norm_mag;
compareData(ref,cmp,fignum,'Normalization magnitude');
fignum=fignum+1;

ref = datalog.norm_mag_inv(1:numel(sim_norm_mag_inv));
cmp = sim_norm_mag_inv;
compareData(ref,cmp,fignum,'Normalization magnitude inverted');
fignum=fignum+1;

ref = datalog.w(1:size(sim_w,1),:);
ref = reshape(ref.',[],1);
cmp = reshape(sim_w.',[],1);
compareData(ref,cmp,fignum,'Normalized weight vector');
fignum=fignum+1;

figure(fignum);
plot(real(sim_Y)); hold on; plot(imag(sim_Y)); hold off;
title('Beamformed output signal');
fignum=fignum+1;

figure(fignum);
plot(real(sim_constellation), imag(sim_constellation), 'bx');
title('Received constellation');
fignum=fignum+1;

%% Plot beam pattern

hBeamFig = figure(fignum);
hBeamAxes = axes(hBeamFig);

mvdrResponse=pattern(sensorArray,fc,-90:90,0,'Weights',sim_w(1,:).');
phaseShiftResponse=pattern(sensorArray,fc,-90:90,0,'Weights',sv);

plot_beam_patterns(hBeamAxes,mvdrResponse,phaseShiftResponse,signalAngle,interfererAngle);
