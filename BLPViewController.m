//
//  BLPViewController.m
//  Bloop
//
//  Created by Keith on 7/13/14.
//  Copyright (c) 2014 Keith Kurak. All rights reserved.
//

#import "BLPViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface BLPViewController () <AVCaptureMetadataOutputObjectsDelegate>

@property (weak, nonatomic) IBOutlet UILabel *lastScannedLabel;
@property (weak, nonatomic) IBOutlet UIView *barcodeScanAreaView;
@property (weak, nonatomic) IBOutlet UITextView *historyTextView;

@property (strong, nonatomic) UIView *highlightView;

@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) AVCaptureDevice *device;
@property (strong, nonatomic) AVCaptureDeviceInput *input;
@property (strong, nonatomic) AVCaptureMetadataOutput *output;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *prevLayer;

@end

@implementation BLPViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.historyTextView.text = @"";
    
    //set up the green line that shows up when you scan a barcode (which doesn't actually get used here)
    _highlightView = [[UIView alloc] init];
    _highlightView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;
    _highlightView.layer.borderColor = [UIColor greenColor].CGColor;
    _highlightView.layer.borderWidth = 3;
    [self.barcodeScanAreaView addSubview:_highlightView];
    
    //set up the AVCaptureSession stuff to show the camera and look for barcodes
    _session = [[AVCaptureSession alloc] init];
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    
    _input = [AVCaptureDeviceInput deviceInputWithDevice:_device error:&error];
    if (_input) {
        [_session addInput:_input];
    } else {
        NSLog(@"Error: %@", error);
    }
    
    _output = [[AVCaptureMetadataOutput alloc] init];
    [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [_session addOutput:_output];
    
    _output.metadataObjectTypes = [_output availableMetadataObjectTypes];
    
    _prevLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    _prevLayer.frame = self.barcodeScanAreaView.bounds;
    _prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    //[self.barcodeScanAreaView.layer addSublayer:_prevLayer];
    
    //[_session startRunning];
    
    [self.barcodeScanAreaView bringSubviewToFront:_highlightView];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// handling for capturing the barcode and doing something with it
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    CGRect highlightViewRect = CGRectZero;
    AVMetadataMachineReadableCodeObject *barCodeObject;
    NSString *detectionString = nil;
    NSArray *barCodeTypes = @[AVMetadataObjectTypeUPCECode, AVMetadataObjectTypeCode39Code, AVMetadataObjectTypeCode39Mod43Code,
                              AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeCode128Code,
                              AVMetadataObjectTypePDF417Code, AVMetadataObjectTypeQRCode, AVMetadataObjectTypeAztecCode];
    
    //cycle through cool stuff the camera found, see if it matches one of the barcode types we're looking for
    for (AVMetadataObject *metadata in metadataObjects) {
        for (NSString *type in barCodeTypes) {
            if ([metadata.type isEqualToString:type])
            {
                barCodeObject = (AVMetadataMachineReadableCodeObject *)[_prevLayer transformedMetadataObjectForMetadataObject:(AVMetadataMachineReadableCodeObject *)metadata];
                highlightViewRect = barCodeObject.bounds;
                detectionString = [(AVMetadataMachineReadableCodeObject *)metadata stringValue];
                break;
            }
        }
        
        // if it found a barcode
        if (detectionString != nil)
        {
            //update the label and history
            self.lastScannedLabel.text = detectionString;
            NSString *updatedHistory = [detectionString copy];
            
            updatedHistory= [updatedHistory stringByAppendingString:@"\n"];
            self.historyTextView.text = [updatedHistory stringByAppendingString:self.historyTextView.text];
            
            //remove the barcode view
            [_session stopRunning];
            [self.prevLayer removeFromSuperlayer];
            highlightViewRect = CGRectZero;
            break;
        }
        else
            self.lastScannedLabel.text = @"(none)";
    }
    
    _highlightView.frame = highlightViewRect;
}

//start scanning when the Scan button is pushed down
- (IBAction)startScanning:(id)sender {
    if(![self.session isRunning])
    {
        [self.barcodeScanAreaView.layer addSublayer:_prevLayer];
        [_session startRunning];
        [self.barcodeScanAreaView bringSubviewToFront:_highlightView]; //isn't necessary at this point because the line gets removed before anyone sees it.  Could be useful if there was a delay before shutting down the view and recording the scan
    }
}
//stop scanning when the button is pushed up (inside button)
- (IBAction)stopScanning:(id)sender {
    if([self.session isRunning])
    {
        [_session stopRunning]; //this makes the camera stop streaming to the screen.
        [self.prevLayer removeFromSuperlayer]; //this makes the view containing the camera image go blank
    }
}
//stop scanning when the button is pushed up (outside button)
- (IBAction)stopScanning_Outside:(id)sender {
    if([self.session isRunning])
    {
        [_session stopRunning];
        [self.prevLayer removeFromSuperlayer];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
