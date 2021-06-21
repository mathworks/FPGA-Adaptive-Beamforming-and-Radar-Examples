%% Run this after reading matrix value out
rdMat = MatrixRd.signals(1).values(MatrixRd.signals(2).values);
rdOut = reshape(rdMat(1:N1*N2),[N2,N1]);

fprintf('Matrix written to DDR4: \n');
disp(MatrixInput);
disp('------')

fprintf('Matrix read out of DDR4: \n');
disp(rdOut);
disp('------')

if rdOut ~= transpose(MatrixInput)
    error('Bad transpose!');    
end

if length(rdMat(:)) > N2*N1
    rdMatFormat = reshape(rdMat,[N2 N1 length(rdMat)/(N2*N1)]);
    three_dim_diff = diff(rdMatFormat,3);
    if any(three_dim_diff(:) ~= 0)
        error('Matrix values inconsistent across time!');
    end
end