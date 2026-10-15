function summary = switchesSelfTest()
    cfg=config();
    assert(cfg.coding.enabled && cfg.receiver.equalizerEnabled);
    cfg.channel.snrDb=100;
    cfg.coding.turboNumIter=3;
    cfg.experiment.verbose=false;
    summary=struct('packetCases',0,'backendComparisons',0,'uncodedBlocks',0, ...
        'ignoredCodingSettings',0,'rejectedInputs',0,'experimentPackets',0);
    originalRng=rng;
    restoreRng=onCleanup(@()rng(originalRng));
    for modulation={'QPSK','16QAM','64QAM'}
        cfg.modulation=modulation{1};
        awgn=cell(2,2);
        for codingEnabled=[false true]
            cfg.coding.enabled=codingEnabled;
            for eqEnabled=[false true]
                cfg.receiver.equalizerEnabled=eqEnabled;
                for ch={'awgn','tdl'}
                    cfg.channel.type=ch{1};
                    before=rng;packet=main(cfg);assert(isequal(before,rng));
                    assert(packet.txInfo.params.coding_enabled==codingEnabled);
                    assert(packet.txInfo.params.equalizer_enabled==eqEnabled);
                    assert(packet.rxInfo.codingEnabled==codingEnabled);
                    assert(packet.txInfo.coding.enabled==codingEnabled);
                    assert(packet.txInfo.coding.crcEnabled);
                    eq=packet.rxInfo.equalizer;
                    assert(eq.enabled==eqEnabled);
                    expectApplied=eqEnabled && strcmp(ch{1},'tdl');
                    assert(eq.applied==expectApplied);
                    if expectApplied
                        assert(strcmp(eq.mode,'zf'));
                    else
                        assert(strcmp(eq.mode,'bypass'));
                        grid=ofdmDemodulate(packet.rxSignal,packet.txInfo.params);
                        raw=reshape(grid.',[],1);
                        raw=raw(1:packet.txInfo.params.mod_symbol_len);
                        assert(isequal(packet.rxInfo.qamSymbols,raw));
                        expectedVariance=packet.channelInfo.noisePower*ones(size(raw));
                        assert(isequal(packet.rxInfo.noiseVariance,expectedVariance));
                    end
                    if strcmp(ch{1},'awgn') || eqEnabled
                        assert(packet.metrics.bitErrors==0 && packet.metrics.crcErrors==0);
                    end
                    if strcmp(ch{1},'awgn')
                        awgn{double(codingEnabled)+1,double(eqEnabled)+1}=packet;
                    end
                    if ~codingEnabled && eqEnabled
                        reference=cfg;reference.coding.backend='toolbox';
                        reference=main(reference);
                        assert(isequal(packet.txSignal,reference.txSignal));
                        assert(isequal(packet.rxInfo.llr,reference.rxInfo.llr));
                        assert(isequal(packet.rxInfo.bits,reference.rxInfo.bits));
                        assert(packet.rxInfo.crcError==reference.rxInfo.crcError);
                        summary.backendComparisons=summary.backendComparisons+1;
                    end
                    summary.packetCases=summary.packetCases+1;
                end
            end
        end
        for k=1:2
            a=awgn{k,1};b=awgn{k,2};
            assert(isequal(a.txSignal,b.txSignal) && isequal(a.rxSignal,b.rxSignal));
            assert(isequal(a.rxInfo.qamSymbols,b.rxInfo.qamSymbols));
            assert(isequal(a.rxInfo.noiseVariance,b.rxInfo.noiseVariance));
            assert(isequal(a.rxInfo.llr,b.rxInfo.llr));
            assert(isequal(a.rxInfo.bits,b.rxInfo.bits));
        end
        cfg.coding.enabled=false;cfg.channel.type='awgn';
        cfg.coding.codeRate=1/3;cfg.coding.rv=0;cfg.coding.turboNumIter=1;
        a=main(cfg);
        cfg.coding.codeRate=0.9;cfg.coding.rv=3;cfg.coding.turboNumIter=30;
        b=main(cfg);
        assert(isequal(a.txSignal,b.txSignal));
        assert(isequal(a.rxInfo.bits,b.rxInfo.bits));
        assert(a.txInfo.params.rate_matched_len==b.txInfo.params.rate_matched_len);
        summary.ignoredCodingSettings=summary.ignoredCodingSettings+1;
        cfg.coding.codeRate=2/3;cfg.coding.rv=0;cfg.coding.turboNumIter=3;
    end
    cfg.coding.enabled=false;
    for tbLength=[16 1000]
        cfg.coding.tbLength=tbLength;
        for modulation={'QPSK','16QAM','64QAM'}
            cfg.modulation=modulation{1};
            for backend={'manual','toolbox'}
                cfg.coding.backend=backend{1};p=frameParameters(cfg);
                K=tbLength+24;G=p.rate_matched_len;
                assert(p.tb_crc_len==K && p.coded_len_full==K && G>=K);
                assert(p.coding_padding_len==G-K);
                capacities=zeros(cfg.lte.enb.NDLRB,1);
                for n=1:numel(capacities)
                    [~,allocation]=ltePDSCHIndices(p.enb,p.chs,(0:n-1).');
                    capacities(n)=double(allocation.G(1));
                end
                assert(G==min(capacities(capacities>=K)));
                bits=int8(mod((1:tbLength).',3)==0);
                [coded,info]=encoder(bits,p);
                expected=crc24a_encode_manual(bits);
                assert(~info.enabled && info.crcEnabled && isempty(info.turboBits));
                assert(info.paddingLength==G-K);
                assert(isequal(double(info.crcBits),double(expected)));
                assert(isequal(coded(1:K),double(expected)));
                assert(all(coded(K+1:end)==0));
                llr=20*(2*double(coded)-1);
                [decoded,err]=decoder(llr,p);
                assert(isequal(decoded,bits) && ~err);
                [rowDecoded,rowError]=decoder(llr.',p);
                assert(isequal(rowDecoded,bits)&&~rowError);
                llr(K+1:end)=1e6; % Deliberately wrong padding is discarded.
                [decoded,err]=decoder(llr,p);
                assert(isequal(decoded,bits) && ~err);
                llr(1)=-llr(1); % Payload corruption is still detected by CRC.
                [decoded,err]=decoder(llr,p);
                assert(err~=0 && decoded(1)~=bits(1));
                summary.uncodedBlocks=summary.uncodedBlocks+1;
            end
        end
    end
    for invalid=[2 NaN]
        assertRejects(@()codingConfig(struct('enabled',invalid)));
        assertRejects(@()receiverConfig(struct('equalizerEnabled',invalid)));
        summary.rejectedInputs=summary.rejectedInputs+2;
    end
    assertRejects(@()channelConfig(struct('snrDb',Inf)));
    summary.rejectedInputs=summary.rejectedInputs+1;
    tooSmall=config();tooSmall.coding.enabled=false;tooSmall.lte.enb.NDLRB=1;
    assertRejects(@()frameParameters(tooSmall));
    badLlr=llr;badLlr(1)=NaN;assertRejects(@()decoder(badLlr,p));
    summary.rejectedInputs=summary.rejectedInputs+2;
    cfg=config();cfg.coding.enabled=false;cfg.receiver.equalizerEnabled=false;
    cfg.channel.type='awgn';cfg.experiment.verbose=false;
    cfg.experiment.modulations={'QPSK','64QAM'};
    cfg.experiment.snrAwgnDb=100;cfg.experiment.packetsPerPoint=2;
    before=rng;results=snrRun(cfg);assert(isequal(before,rng));
    assert(~results.cfg.coding.enabled && ~results.cfg.receiver.equalizerEnabled);
    assert(all(results.bitErrors(:)==0) && all(results.crcErrors(:)==0));
    assert(all(results.totalPackets(:)==2));
    for k=1:numel(results.cases)
        assert(~results.cases(k).cfg.coding.enabled);
        assert(~results.cases(k).cfg.receiver.equalizerEnabled);
        assert(~results.params{k}.coding_enabled && ~results.params{k}.equalizer_enabled);
    end
    summary.experimentPackets=sum(results.totalPackets(:));
    fprintf(['SWITCHES_SELF_TEST_PASS: %d packet cases, %d backend comparisons, ' ...
        '%d uncoded blocks, %d ignored-settings cases, %d input rejections, %d experiment packets\n'], ...
        summary.packetCases,summary.backendComparisons,summary.uncodedBlocks, ...
        summary.ignoredCodingSettings,summary.rejectedInputs,summary.experimentPackets);
end

function assertRejects(action)
    rejected=false;
    try,action();catch,rejected=true;end
    assert(rejected,'Expected the invalid configuration to be rejected.');
end
