//
//  ViewController.m
//  BigTone
//
//  Created by Joan Barrull Ribalta on 18/03/15.
//  Copyright (c) 2015 com.giria. All rights reserved.
//

#import "ViewController.h"
#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>


@interface ViewController () {
@public
    float _lastTheta;
    AudioUnit _toneGeneratorUnit;
}

@property (strong, nonatomic) IBOutlet UILabel *frequencyLabel;
@property (strong, nonatomic) IBOutlet UISlider *frequencySlider;
@property (strong, nonatomic) IBOutlet UIButton *playButton;

@property (nonatomic)BOOL isPlaying;

@end

const int SAMPLE_RATE=44100;
static float gAmplitude = 0.5f;
OSStatus renderAudio(
                     void *inRefCon,
                     AudioUnitRenderActionFlags *ioActionFlags,
                     const AudioTimeStamp *inTimeStamp,
                     UInt32 inBusNumber,
                     UInt32 inNumberFrames,
                     AudioBufferList *ioData)
{
    ViewController *vc = (__bridge ViewController *)inRefCon;
    float theta = vc->_lastTheta;
    float theta_increment = M_PI *2.0* vc.frequencySlider.value / SAMPLE_RATE;
    
    float *buf = (float* ) ioData ->mBuffers[0].mData;
    for (UInt32 i=0; i<inNumberFrames; i++) {
        buf[i] = gAmplitude * sin(theta);
        theta += theta_increment;
        if (theta > M_PI * 2.0) theta -= 2.0*M_PI;
    }
    vc-> _lastTheta;
    return noErr;
    
    
}



@implementation ViewController
- (IBAction)togglePlaying:(UIButton *)sender {
    if (! self.isPlaying){
        NSLog(@"start");
        [self play];
    } else {
        NSLog(@"Stop");
        [self stop];
    }
    
    
}
- (IBAction)changeFrequency:(UISlider *)sender {
    self.frequencyLabel.text = [NSString stringWithFormat: @"Frequency : %5.0fHz",self.frequencySlider.value];
    
    
}

-(void)play{
    // Start playback
    OSErr err = AudioOutputUnitStart(_toneGeneratorUnit);
    NSAssert(err==noErr, @"Error starting tone generator");
    
    
    [self.playButton setTitle:@"Stop" forState:UIControlStateNormal];
    self.isPlaying = YES;
    
}

- (void) stop {
    OSErr err = AudioOutputUnitStop(_toneGeneratorUnit);
    NSAssert(err==noErr, @"Error stopping tone generator");
    
    
    [self.playButton setTitle:@"Start" forState:UIControlStateNormal];
     self.isPlaying = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setUpAudio];
}

- (void) setUpAudio {
    OSStatus err;
    AudioComponentDescription desc;
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_RemoteIO;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    
    AudioComponent comp = AudioComponentFindNext(NULL,&desc);
    err = AudioComponentInstanceNew(comp, &_toneGeneratorUnit);
    NSAssert(err==noErr, @"Could not create output component");

    
    
    // Set our tone rendering function on the unit
    AURenderCallbackStruct renderCB;
    renderCB.inputProc = renderAudio;
    renderCB.inputProcRefCon = (__bridge void*) self;
    err = AudioUnitSetProperty(_toneGeneratorUnit, kAudioUnitProperty_SetRenderCallback,
                               kAudioUnitScope_Input,
                               0,
                               &renderCB,
                               sizeof(renderCB));
    
    NSAssert1(err== noErr, @"Error setting callback: %ld", err);
    
    
    AudioStreamBasicDescription streamDesc;
    streamDesc.mSampleRate = SAMPLE_RATE; // 44 .1 kHz, same as CD
    streamDesc.mFormatID =kAudioFormatLinearPCM;
    streamDesc.mFormatFlags= kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
    streamDesc.mFramesPerPacket= 1;
    streamDesc.mChannelsPerFrame = 1;
    streamDesc.mBitsPerChannel = 32;
    streamDesc.mBytesPerPacket = 4;
    streamDesc.mBytesPerFrame = 4;
    err = AudioUnitSetProperty(_toneGeneratorUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &streamDesc, sizeof(streamDesc));
    NSAssert(err ==noErr,@"Error setting output stream description");
    err = AudioUnitSetProperty(_toneGeneratorUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &streamDesc, sizeof(streamDesc));
    NSAssert(err==noErr, @"Error settng output stream description");
    err= AudioUnitInitialize(_toneGeneratorUnit);
    NSAssert(err==noErr, @"Error initializing audio unit");
    
    
   
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
