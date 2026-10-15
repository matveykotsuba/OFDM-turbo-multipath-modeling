function recovered = turbo_rate_recover_manual(llr, tb_len, rv)
    if nargin<3,rv=0;end
    if ~isnumeric(tb_len)||~isreal(tb_len)||~isscalar(tb_len)||~isfinite(tb_len)||tb_len<=0||tb_len~=fix(tb_len)
        error('manualLTE:BlockLength','tb_len must be a positive integer.');
    end
    if ~isnumeric(llr)||~isreal(llr)||~isvector(llr)||any(~isfinite(llr(:)))
        error('manualLTE:LLR','LLR must be a finite real vector.');
    end
    K=tb_len+24;
    indices=turbo_rate_indices_manual(K,numel(llr),rv);
    recovered={accumarray(indices,double(llr(:)),[3*(K+4),1],@sum,0)};
end
