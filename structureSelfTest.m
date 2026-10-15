function summary = structureSelfTest(outputDir)
    cfg=config();cfg.experiment.verbose=false;cfg.experiment.packetsPerPoint=2;
    if nargin<1,outputDir=fullfile(cfg.experiment.outputDir,'structure-tests');end
    cfg.experiment.outputDir=outputDir;
    cfg.experiment.snrTdlDb=[0 60];cfg.experiment.snrAwgnDb=[0 60];cfg.experiment.snrDb=[0 60];
    cfg.experiment.modulations={'QPSK','16QAM'};cfg.experiment.delaySpreadsNs=[120 300];
    cfg.channel.snrDb=60;cfg.coding.turboNumIter=3;
    summary=struct('cleanPackets',0,'experiments',0);
    for modulation={'QPSK','16QAM','64QAM'}
      for ch={'awgn','tdl'}
        cfg.modulation=modulation{1};cfg.channel.type=ch{1};
        a=main(cfg);assert(a.metrics.bitErrors==0&&a.metrics.crcErrors==0);
        ref=cfg;ref.coding.backend='toolbox';b=main(ref);
        assert(isequal(a.txSignal,b.txSignal)&&isequal(a.rxInfo.bits,b.rxInfo.bits));
        summary.cleanPackets=summary.cleanPackets+1;
      end
    end
    rng(891);before=rng;a=main(cfg);assert(isequal(before,rng));b=main(cfg);assert(isequal(a.rxSignal,b.rxSignal));
    a=main(cfg,[]);b=main(cfg,[]);assert(~isequal(a.txInfo.bits,b.txInfo.bits));
    before=rng;s=snrRun(cfg);assert(isequal(before,rng));s2=snrRun(cfg);
    assert(isequal(s.bitErrors,s2.bitErrors)&&isequal(s.crcErrors,s2.crcErrors));
    assert(isequal(size(s.BER),[2 2])&&all(s.totalPackets(:)==2));
    m=mcsRun(cfg);d=delaySpreadRun(cfg);
    assert(isequal(size(m.BER),[3 2])&&isequal(size(d.BER),[2 2]));
    assert(all(m.totalBits(:)==2000)&&all(d.totalPackets(:)==2));
    summary.experiments=3;
    [p,folder]=saveResults(s,outputDir,'selftest');[p2,~]=saveResults(s,outputDir,'selftest');
    assert(~strcmp(p,p2)&&exist(p,'file')==2&&exist(p2,'file')==2);
    loaded=load(p);assert(isequal(loaded.results.BER,s.BER)&&isequal(loaded.cfg,s.cfg));
    fig=berPlot(s);savePlot(fig,folder,'ber');close(fig);
    fig=blerPlot(s);savePlot(fig,folder,'bler');close(fig);
    rejected=false;try,config(struct('fftSze',512));catch,rejected=true;end;assert(rejected);
    cfg.fftSize=1024;changed=main(cfg);
    assert(changed.cfg.sampleRate==15360000&&changed.metrics.bitErrors==0);
    summary.resultFile=p;summary.figuresDir=folder;
    fprintf('STRUCTURE_SELF_TEST_PASS: %d clean cases, %d experiment types\n',summary.cleanPackets,summary.experiments);
end
