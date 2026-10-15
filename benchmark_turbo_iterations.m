function result = benchmark_turbo_iterations(packets, seed)
    if nargin<1||isempty(packets),packets=30;end
    if nargin<2||isempty(seed),seed=8304;end
    if ~isscalar(packets)||~isnumeric(packets)||~isfinite(packets)||packets<1||packets~=fix(packets)
        error('manualLTE:Packets','packets must be a positive integer.');
    end
    saved_rng=rng;cleanup=onCleanup(@()rng(saved_rng));
    rng(seed,'twister');
    variances=[0.35 0.45 0.55];iters=[3 4 6];
    errors=zeros(3,3);failed=zeros(3,3);seconds=zeros(3,3);ref_difference=zeros(3,3);
    warm=turbo_encode_manual(zeros(1024,1));
    turbo_decode_manual(2*double(warm)-1,4);
    has_reference=~isempty(which('lteTurboDecode'));
    if has_reference,lteTurboDecode(2*double(warm)-1,4);end
    for i=1:numel(variances)
        v=variances(i);
        for n=1:packets
            u=int8(randi([0 1],1000,1));c=turbo_encode_manual(crc24a_encode_manual(u));
            rm=turbo_rate_match_manual(c,1500,0);y=2*rm-1+sqrt(v)*randn(1500,1);
            rr=turbo_rate_recover_manual(2*y/v,1000,0);
            for j=1:numel(iters)
                tic;d=turbo_decode_manual(rr{1},iters(j));seconds(i,j)=seconds(i,j)+toc;
                [b,e]=crc24a_decode_manual(d);errors(i,j)=errors(i,j)+sum(b~=u);failed(i,j)=failed(i,j)+e;
                if has_reference
                    dr=lteTurboDecode(rr{1},iters(j));ref_difference(i,j)=ref_difference(i,j)+sum(int8(d)~=dr);
                end
            end
        end
        fprintf('NOISE %.2f packets%d errors %s failed %s seconds %s refdiff %s\n',v,packets,mat2str(errors(i,:)),mat2str(failed(i,:)),mat2str(seconds(i,:),5),mat2str(ref_difference(i,:)));
    end
    result=struct('variances',variances,'iterations',iters,'packets_per_variance',packets,'seed',seed, ...
        'errors',errors,'crc_errors',failed,'BER',errors/(1000*packets),'BLER',failed/packets, ...
        'seconds',seconds,'has_toolbox_reference',has_reference,'reference_bit_differences',ref_difference);
end
