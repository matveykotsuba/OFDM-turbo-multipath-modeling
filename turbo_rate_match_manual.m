function matched = turbo_rate_match_manual(coded, G, rv)
    if nargin<3,rv=0;end
    if ~(isnumeric(coded)||islogical(coded))||~isreal(coded)||~isvector(coded)||...
            any(coded(:)~=0 & coded(:)~=1)
        error('manualLTE:Bits','Encoded input must be a binary vector.');
    end
    K=numel(coded)/3-4;
    indices=turbo_rate_indices_manual(K,G,rv);
    matched=double(coded(indices)); matched=matched(:);
end
