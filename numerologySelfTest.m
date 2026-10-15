function summary=numerologySelfTest()
    saved=rng;restore=onCleanup(@()rng(saved));
    rng(9142026,'twister');
    summary=struct('fftSizes',[512 1024 2048],'referenceError',zeros(1,3), ...
        'roundtripError',zeros(1,3),'noiseRatio',zeros(1,3),'zfError',zeros(1,3));
    referenceRB=[25 50 100];
    for j=1:3
        cfg=config();cfg.fftSize=summary.fftSizes(j);cfg=config(cfg);
        p=frameParameters(cfg);p.mod_symbol_len=p.num_active*14;p.pad_symbol_len=0;
        p.mod_symbol_power=1;
        q=(2*randi([0 1],p.mod_symbol_len,1)-1+1i*(2*randi([0 1],p.mod_symbol_len,1)-1))/sqrt(2);
        x=ofdmModulate(q,p);[g,fullGrid]=ofdmDemodulate(x,p);
        recovered=reshape(g.',[],1);
        summary.roundtripError(j)=max(abs(q-recovered));assert(summary.roundtripError(j)<1e-12);
        assert(numel(x)==cfg.sampleRate*1e-3&&iscolumn(x));
        assert(isequal(p.cp_lengths,repmat([160;144*ones(6,1)],2,1)*p.N/2048));
        unused=setdiff(1:p.N,p.active_indices);
        v=fullGrid(unused,:);assert(max(abs(v(:)))<1e-12);
        for k=1:14
            start=p.symbol_start_indices(k);cp=p.cp_lengths(k);
            assert(isequal(x(start:start+cp-1),x(start+p.N:start+p.N+cp-1)));
        end
        refGrid=complex(zeros(referenceRB(j)*12,14));
        offset=(size(refGrid,1)-300)/2;
        refGrid(offset+(1:300),:)=reshape(q,300,14);
        [reference,info]=lteOFDMModulate(cfg.lte.enb,refGrid,0);
        assert(info.Nfft==p.N&&isequal(info.CyclicPrefixLengths(:),p.cp_lengths));
        summary.referenceError(j)=max(abs(x-reference*sqrt(p.N)));
        assert(summary.referenceError(j)<1e-12);
        cfg.channel.type='awgn';cfg.channel.snrDb=10;
        [y,ch]=channel(x,cfg,p);noisy=ofdmDemodulate(y,p)-g;
        summary.noiseRatio(j)=mean(abs(noisy(:)).^2)/ch.noisePower;
        assert(abs(summary.noiseRatio(j)-1)<0.08);
        h=[1;zeros(p.cp_len-1,1);0.2i];y=conv(x,h);y=y(1:numel(x));
        ch=struct('type','tdl','h',h,'noisePower',0);
        decoded=equalize(ofdmDemodulate(y,p),p,ch);
        summary.zfError(j)=max(abs(decoded-q));assert(summary.zfError(j)<1e-10);
    end
    cfg=config();cfg.channel.snrDb=100;cfg.experiment.verbose=false;
    [x,txInfo]=tx(cfg);[~,a]=channel(x,cfg,txInfo.params);[~,b]=channel(x,cfg);
    assert(abs(a.noisePower-b.noisePower)<1e-20); % Correct Es fallback on active tones.
    summary.longDelaySamples=zeros(1,2);ds=[490 500];
    for j=1:2
        cfg.channel.delaySpreadNs=ds(j);packet=main(cfg);
        st=packet.channelInfo.stats;assert(~st.cp_sufficient&&st.excess_delay_samples>0);
        assert(all(isfinite(packet.rxInfo.llr)));summary.longDelaySamples(j)=st.max_delay_samples;
    end
    assert(isequal(summary.longDelaySamples,[145 148]));
    cfg.experiment.delaySpreadsNs=ds;cfg.experiment.snrDb=100;cfg.experiment.packetsPerPoint=1;
    r=delaySpreadRun(cfg);assert(all(r.totalPackets(:)==1));
    assert(~r.channelStats{1}.cp_sufficient&&~r.channelStats{2}.cp_sufficient);
    bad=config();bad.fftSize=256;rejected=false;try,config(bad);catch,rejected=true;end;assert(rejected);
    bad=config();bad.subcarrierSpacing=30e3;rejected=false;try,config(bad);catch,rejected=true;end;assert(rejected);
    fprintf('NUMEROLOGY_SELF_TEST_PASS\n');disp(summary);
end
