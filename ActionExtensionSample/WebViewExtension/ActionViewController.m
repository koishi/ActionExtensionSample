//
//  ActionViewController.m
//  WebViewExtension
//
//  Created by KAKEGAWA Atsushi on 2014/09/13.
//  Copyright (c) 2014年 KAKEGAWA Atsushi. All rights reserved.
//

#import "ActionViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface ActionViewController () <UIWebViewDelegate>

@property BOOL displayHatena;
@property NSURL *url;

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation ActionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSExtensionItem *item = self.extensionContext.inputItems.firstObject;
    NSItemProvider *itemProvider = item.attachments.firstObject;
    
    if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeURL]) {
        
        __weak typeof(self) weakSelf = self;
        [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeURL options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
            if (error) {
                [weakSelf.extensionContext cancelRequestWithError:error];
                return;
            }
            
            if (![(NSObject *)item isKindOfClass:[NSURL class]]) {
                NSError *unexpectedError = [NSError errorWithDomain:NSItemProviderErrorDomain
                                                               code:NSItemProviderUnexpectedValueClassError
                                                           userInfo:nil];
                [weakSelf.extensionContext cancelRequestWithError:unexpectedError];
                return;
            }

            weakSelf.url = (NSURL *)item;
            weakSelf.displayHatena = true;
            [weakSelf reloadWebView];
        }];
    } else {
        NSError *unavailableError = [NSError errorWithDomain:NSItemProviderErrorDomain
                                                        code:NSItemProviderItemUnavailableError
                                                    userInfo:nil];
        [self.extensionContext cancelRequestWithError:unavailableError];
    }
}

- (void)reloadWebView {
    NSURL *newUrl;
    if (self.displayHatena) {
        newUrl = [[NSURL alloc] initWithString: [NSString stringWithFormat: @"http://b.hatena.ne.jp/entry/s/%@%@", [self.url host], [self.url path]]];
    } else {
        NSString *escapedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                        NULL,
                                                                                                        (CFStringRef)self.url.absoluteString,
                                                                                                        NULL,
                                                                                                        CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                                                        kCFStringEncodingUTF8));

        newUrl = [[NSURL alloc] initWithString: [NSString stringWithFormat: @"https://megalodon.jp/?url=%@", escapedString]];
    }
    [self.webView loadRequest:[NSURLRequest requestWithURL:newUrl]];
}

- (IBAction)done {
    [self.extensionContext completeRequestReturningItems:nil
                                       completionHandler:nil];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (error) {
        NSLog(@"%@", error);
    }
}

- (IBAction)tappedRefreshButton:(UIBarButtonItem *)sender {
    self.displayHatena = !self.displayHatena;
    [self reloadWebView];
}

@end
