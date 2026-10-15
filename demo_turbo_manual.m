function result = demo_turbo_manual(packets, seed)
    if nargin<1||isempty(packets),packets=20;end
    if nargin<2||isempty(seed),seed=8;end
    if ~isscalar(packets)||~isnumeric(packets)||~isfinite(packets)||packets<1||packets~=fix(packets)
        error('manualLTE:Packets','packets must be a positive integer.');
    end
    saved_rng=rng; cleanup=onCleanup(@()rng(saved_rng));
    rng(seed,'twister');
    iters=[3 4 6];G=1500;variance=0.45;
    errors=zeros(1,3);failed=zeros(1,3);seconds=zeros(1,3);
    for n=1:packets
        u=int8(randi([0 1],1000,1));
        encoded=turbo_encode_manual(crc24a_encode_manual(u));
        sent=turbo_rate_match_manual(encoded,G,0);
        received=(2*sent-1)+sqrt(variance)*randn(G,1);
        recovered=turbo_rate_recover_manual(2*received/variance,1000,0);
        for k=1:numel(iters)
            tic; decoded=turbo_decode_manual(recovered{1},iters(k));
            seconds(k)=seconds(k)+toc;
            [estimated,crc_bad]=crc24a_decode_manual(decoded);
            errors(k)=errors(k)+sum(estimated~=u);
            failed(k)=failed(k)+crc_bad;
        end
    end
    result=struct('iterations',iters,'packets',packets,'seed',seed, ...
        'G',G,'noise_variance',variance,'BER',errors/(1000*packets), ...
        'BLER',failed/packets,'bit_errors',errors,'crc_errors',failed, ...
        'decoder_seconds',seconds);
    fprintf('Manual turbo, K=1024, G=1500, RV=0, %d packets\n',packets);
    fprintf('Iterations       BER          BLER      Decoder seconds\n');
    for k=1:3
        fprintf('%5d         %.6g     %.6g       %.4f\n',iters(k),result.BER(k),result.BLER(k),seconds(k));
    end
end
