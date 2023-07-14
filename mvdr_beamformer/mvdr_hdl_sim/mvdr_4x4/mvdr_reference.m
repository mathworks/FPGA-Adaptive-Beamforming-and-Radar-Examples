% mvdr_reference Compute MATLAB floating point reference data for
% comparison to MVDR HDL simulation model.
% Run simulation before calling this script.

offset = 1;
it = 1;
datalog = struct();
while (it <= num_solve_iterations)

    % Get current window
    Xwin = X(offset + (0:windowSize-1),:);
    
    % Compute covariance matrix 
    Ecx = Xwin.' * conj(Xwin);

    % Scale covariance matrix
    Ecx_scaled = Ecx / windowSize;

    % Diagonal loading
    Ecx_loaded = Ecx_scaled + eye(numArrayElements)*diagLoading;
    
    % Compute weight vector
    wp = Ecx_loaded\sv;
    
    % Normalize response
    norm_mag = real(sv'*wp);
    norm_mag_inv = 1/norm_mag;
    w = wp*norm_mag_inv;
    
    % Form output beam
    Y = X*conj(w);

    % Log signal data
    datalog.Ecx(it,:,:) = Ecx;
    datalog.Ecx_scaled(it,:,:) = Ecx_scaled;
    datalog.Ecx_loaded(it,:,:) = Ecx_loaded;
    datalog.wp(it,:) = reshape(wp,[],1);
    datalog.norm_mag(it) = norm_mag;
    datalog.norm_mag_inv(it) = norm_mag_inv;
    datalog.w(it,:) = reshape(w,[],1);

    if it < num_solve_iterations
        offset = offset + latch_offsets(it);
    end
    it=it+1;

end