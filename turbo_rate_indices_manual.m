function indices = turbo_rate_indices_manual(K, G, rv)
    qpp_indices_manual(K); % validate the supported block length
    if ~isnumeric(G)||~isreal(G)||~isscalar(G)||~isfinite(G)||G<=0||G~=fix(G)||mod(G,2)~=0
        error('manualLTE:RateLength','G must be a positive even integer.');
    end
    if ~isnumeric(rv)||~isreal(rv)||~isscalar(rv)||~ismember(rv,0:3)
        error('manualLTE:RV','rv must be 0, 1, 2, or 3.');
    end
    D=K+4;
    R=ceil(D/32); Kpi=32*R; Nd=Kpi-D;
    P=[0 16 8 24 4 20 12 28 2 18 10 26 6 22 14 30 ...
       1 17 9 25 5 21 13 29 3 19 11 27 7 23 15 31];
    y=[zeros(Nd,1);(1:D).'];
    matrix=reshape(y,32,R).';
    matrix=matrix(:,P+1);
    v01=matrix(:);
    k=(0:Kpi-1).';
    perm=mod(P(floor(k/R)+1).' + 32*mod(k,R)+1,Kpi);
    v2=y(perm+1);
    v1=v01; valid=v1~=0; v1(valid)=v1(valid)+D;
    valid=v2~=0; v2(valid)=v2(valid)+2*D;
    parity=reshape([v1.';v2.'],[],1);
    circular=[v01;parity];
    Ncb=3*Kpi;
    k0=R*(2*ceil(Ncb/(8*R))*rv+2); % zero-based buffer starting position
    cycle=circular(mod(k0+(0:Ncb-1).',Ncb)+1);
    cycle=cycle(cycle~=0); % skip NULL, keep actual zeros in the data
    indices=cycle(mod((0:G-1).',numel(cycle))+1);
end
