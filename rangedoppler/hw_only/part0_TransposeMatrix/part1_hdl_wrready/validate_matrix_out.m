%% Run this after reading matrix value out
MatrixRd = out.ScopeData;
Valid = MatrixRd.signals(2).values(:);
rdMat = MatrixRd.signals(1).values(:);

rdMat = rdMat(Valid);

iter = length(rdMat)/(N1*N2);

for ii = 1:iter
    range = (1:N1*N2) + (ii-1)*(N1*N2);
    rdOut = reshape(rdMat(range),[N2,N1]);

    fprintf('Matrix read out of DDR4: \n');
    disp(rdOut);
    disp('------')


    fprintf('Matrix written to DDR4: \n');
    disp(MatrixInput);
    disp('------')

    compare = transpose(MatrixInput);
    if any(rdOut(:) ~= compare(:))
        error('Bad transpose!');    
    end
end