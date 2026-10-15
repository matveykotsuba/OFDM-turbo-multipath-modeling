function n=numerologyConfig(fftSize,spacing,numRB)
    if nargin<1,fftSize=2048;end
    if nargin<2,spacing=15e3;end
    if nargin<3,numRB=25;end
    if ~isscalar(fftSize)||~ismember(fftSize,[128 256 512 1024 2048])
        error('project:FFT','Supported FFT sizes: 128, 256, 512, 1024, 2048.');
    end
    if ~isscalar(spacing)||spacing~=15e3
        error('project:Spacing','This normal-CP LTE numerology uses 15 kHz spacing.');
    end
    rbList=[6 15 25 50 75 100];bw=[1.4 3 5 10 15 20]*1e6;
    if ~isscalar(numRB)||~ismember(numRB,rbList)
        error('project:Bandwidth','NDLRB must be 6, 15, 25, 50, 75 or 100.');
    end
    active=12*numRB;
    if active+1>fftSize,error('project:FFT','FFT cannot hold the active subcarriers and DC.');end
    n=struct();n.numResourceBlocks=numRB;n.subcarriersPerResourceBlock=12;
    n.numActiveSubcarriers=active;n.channelBandwidth=bw(rbList==numRB);
    n.sampleRate=fftSize*spacing;n.samplePeriod=1/n.sampleRate;
    n.occupiedBandwidth=active*spacing;n.usefulSymbolDuration=1/spacing;
    n.symbolsPerSlot=7;n.slotsPerSubframe=2;n.subframesPerFrame=10;
    n.slotsPerFrame=20;n.symbolsPerSubframe=14;n.symbolsPerFrame=140;
    n.numOfdmSymbols=n.symbolsPerSubframe;
    n.normalCpFirst=fftSize*160/2048;n.normalCpOther=fftSize*144/2048;
    n.cpLength=n.normalCpOther; % Compatibility alias: MINIMUM CP only.
    n.cpLengths=repmat([n.normalCpFirst;repmat(n.normalCpOther,6,1)],2,1);
    n.cpDurations=n.cpLengths/n.sampleRate;
    n.slotDuration=0.5e-3;n.subframeDuration=1e-3;n.frameDuration=10e-3;
    n.samplesPerSubframe=sum(fftSize+n.cpLengths);
    n.samplesPerSlot=n.samplesPerSubframe/2;n.samplesPerFrame=n.samplesPerSubframe*10;
    n.activeSubcarriers=[-active/2:-1 1:active/2].';
    n.dcIndex=fftSize/2+1;n.activeIndices=n.dcIndex+n.activeSubcarriers;
end
