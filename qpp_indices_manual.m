function [p, inverse_p, f1, f2] = qpp_indices_manual(K)
    if ~isnumeric(K) || ~isreal(K) || ~isscalar(K) || ~isfinite(K)
        error('manualLTE:BlockLength', 'K must be 40 or 1024.');
    end
    switch K
        case 40
            f1 = 3; f2 = 10;
        case 1024
            f1 = 31; f2 = 64;
        otherwise
            error('manualLTE:BlockLength', ...
                'Supported turbo block lengths are 40 and 1024 (including CRC).');
    end
    i = (0:K-1).';
    p = mod(f1*i + f2*i.^2, K) + 1;
    if nargout > 1
        inverse_p = zeros(K,1);
        inverse_p(p) = (1:K).';
    end
end
